
/*
===============================================================================
ZABBIX SQL SERVER - INITIAL SETUP
VERSION 1.1
===============================================================================
Name         : 00-Setup-Zabbix-User.sql

Purpose      : Create or update the SQL Server login and
               monitoring permissions required by Zabbix.

Compatibility: SQL Server 2012+
Execution    : SSMS / Central Management Server (CMS)
Database     : master

Permissions  : VIEW SERVER STATE
               VIEW ANY DEFINITION
               VIEW SERVER PERFORMANCE STATE (SQL 2022+)
               VIEW ANY SECURITY DEFINITION (SQL 2022+)
               CONNECT and VIEW DEFINITION in user databases
               VIEW DATABASE STATE (SQL 2012-2019)
               VIEW DATABASE PERFORMANCE STATE (SQL 2022+)
               SQLAgentReaderRole in msdb
               SELECT on msdb.dbo.sysjobhistory
               db_datareader in DBA database

AG Handling  : Configures standalone databases and local
               AG primary replicas.
               Skips AG secondary databases.
               Existing AG database users are replicated.
               Matching login SIDs are required on replicas.

Notes        : Idempotent.
               Does not grant sysadmin or db_owner.
               Does not grant read access to application
               tables outside the DBA database.
               Skips offline databases and snapshots.
               Reports database-level errors.
               Does not change SQL Agent jobs.
               Does not change Query Store configuration.
===============================================================================
*/

USE [master];

SET NOCOUNT ON;

------------------------------------------------------------
-- CONFIGURATION
------------------------------------------------------------

DECLARE @LoginName sysname = N'zabbix_prod';

DECLARE @Password nvarchar(128) =
    N'CHANGE_ME_TO_A_STRONG_PASSWORD';

-- 0 = Keep password on existing logins
-- 1 = Reset password on existing SQL logins
DECLARE @ResetExistingPassword bit = 0;

------------------------------------------------------------
-- INTERNAL VARIABLES
------------------------------------------------------------

DECLARE @SQL nvarchar(max);
DECLARE @Database sysname;

DECLARE @MajorVersion int =
    TRY_CONVERT
    (
        int,
        SERVERPROPERTY('ProductMajorVersion')
    );

DECLARE @LoginCreated bit = 0;
DECLARE @UpdatedDatabases int = 0;
DECLARE @ErrorDatabases int = 0;

DECLARE @DBAReadAccess varchar(20) = 'NOT FOUND';

DECLARE @DatabaseResults TABLE
(
    DatabaseName sysname NOT NULL,
    Status nvarchar(20) NOT NULL,
    Details nvarchar(2048) NULL
);

------------------------------------------------------------
-- Validate configuration
------------------------------------------------------------

IF ISNULL(@MajorVersion, 0) < 11
BEGIN
    THROW 50000,
        'SQL Server 2012 or newer is required.',
        1;
END;

IF NULLIF(@LoginName, N'') IS NULL
BEGIN
    THROW 50001,
        'Login name cannot be empty.',
        1;
END;

IF @Password IS NULL
   OR @Password = N'CHANGE_ME_TO_A_STRONG_PASSWORD'
   OR LEN(@Password) = 0
BEGIN
    THROW 50002,
        'Configure a password before execution.',
        1;
END;

------------------------------------------------------------
-- Create SQL login if missing
------------------------------------------------------------

IF SUSER_ID(@LoginName) IS NULL
BEGIN

    SET @SQL =
        N'CREATE LOGIN ' + QUOTENAME(@LoginName) +
        N' WITH PASSWORD = N''' +
        REPLACE(@Password, N'''', N'''''') +
        N''', CHECK_POLICY = ON,
              CHECK_EXPIRATION = OFF;';

    EXEC sys.sp_executesql @SQL;

    SET @LoginCreated = 1;

END
ELSE
BEGIN

    --------------------------------------------------------
    -- Require an existing SQL-authenticated login
    --------------------------------------------------------

    IF NOT EXISTS
    (
        SELECT 1
        FROM sys.sql_logins
        WHERE name = @LoginName
    )
    BEGIN
        THROW 50004,
            'Existing login is not a SQL login.',
            1;
    END;

    --------------------------------------------------------
    -- Optional password reset
    --------------------------------------------------------

    IF @ResetExistingPassword = 1
    BEGIN

        SET @SQL =
            N'ALTER LOGIN ' + QUOTENAME(@LoginName) +
            N' WITH PASSWORD = N''' +
            REPLACE(@Password, N'''', N'''''') +
            N''';';

        EXEC sys.sp_executesql @SQL;

    END;

END;

------------------------------------------------------------
-- Server-level monitoring permissions
------------------------------------------------------------

SET @SQL =
    N'GRANT VIEW SERVER STATE TO ' +
    QUOTENAME(@LoginName) + N';';

EXEC sys.sp_executesql @SQL;

SET @SQL =
    N'GRANT VIEW ANY DEFINITION TO ' +
    QUOTENAME(@LoginName) + N';';

EXEC sys.sp_executesql @SQL;

------------------------------------------------------------
-- SQL Server 2022+ permissions
------------------------------------------------------------

IF @MajorVersion >= 16
BEGIN

    SET @SQL =
        N'GRANT VIEW SERVER PERFORMANCE STATE TO ' +
        QUOTENAME(@LoginName) + N';';

    EXEC sys.sp_executesql @SQL;

    SET @SQL =
        N'GRANT VIEW ANY SECURITY DEFINITION TO ' +
        QUOTENAME(@LoginName) + N';';

    EXEC sys.sp_executesql @SQL;

END;

------------------------------------------------------------
-- Configure msdb user
------------------------------------------------------------

SET @SQL = N'
USE [msdb];

IF NOT EXISTS
(
    SELECT 1
    FROM sys.database_principals
    WHERE name = @UserName
)
BEGIN

    DECLARE @CreateSQL nvarchar(max);

    SET @CreateSQL =
        N''CREATE USER '' + QUOTENAME(@UserName) +
        N'' FOR LOGIN '' + QUOTENAME(@UserName);

    EXEC sys.sp_executesql @CreateSQL;

END
ELSE
BEGIN

    DECLARE @UserSID varbinary(85);
    DECLARE @LoginSID varbinary(85);

    SELECT @UserSID = sid
    FROM sys.database_principals
    WHERE name = @UserName;

    SELECT @LoginSID = sid
    FROM sys.server_principals
    WHERE name = @UserName;

    IF @UserSID <> @LoginSID
    BEGIN

        DECLARE @AlterSQL nvarchar(max);

        SET @AlterSQL =
            N''ALTER USER '' + QUOTENAME(@UserName) +
            N'' WITH LOGIN = '' + QUOTENAME(@UserName);

        EXEC sys.sp_executesql @AlterSQL;

    END;

END;
';

EXEC sys.sp_executesql
    @SQL,
    N'@UserName sysname',
    @UserName = @LoginName;

------------------------------------------------------------
-- SQL Agent role membership
------------------------------------------------------------

SET @SQL = N'
USE [msdb];

IF NOT EXISTS
(
    SELECT 1
    FROM sys.database_role_members AS drm
    INNER JOIN sys.database_principals AS r
        ON r.principal_id = drm.role_principal_id
    INNER JOIN sys.database_principals AS u
        ON u.principal_id = drm.member_principal_id
    WHERE r.name = N''SQLAgentReaderRole''
      AND u.name = @UserName
)
BEGIN

    EXEC sys.sp_addrolemember
        @rolename = N''SQLAgentReaderRole'',
        @membername = @UserName;

END;
';

EXEC sys.sp_executesql
    @SQL,
    N'@UserName sysname',
    @UserName = @LoginName;

------------------------------------------------------------
-- Direct SQL Agent history permission
------------------------------------------------------------

SET @SQL =
    N'USE [msdb];
      GRANT SELECT ON OBJECT::dbo.sysjobhistory
      TO ' + QUOTENAME(@LoginName) + N';';

EXEC sys.sp_executesql @SQL;

------------------------------------------------------------
-- Find databases for monitoring permissions
--
-- Includes:
--   Standalone databases
--   Local AG primary databases
--   DBA database
--
-- Excludes:
--   System databases
--   AG secondaries
--   Offline databases
--   Database snapshots
------------------------------------------------------------

DECLARE DatabaseCursor CURSOR LOCAL FAST_FORWARD FOR

SELECT
    d.name
FROM sys.databases AS d
WHERE d.database_id > 4
  AND d.state_desc = N'ONLINE'
  AND d.source_database_id IS NULL
  AND
  (
      d.replica_id IS NULL

      OR EXISTS
      (
          SELECT 1
          FROM sys.dm_hadr_database_replica_states AS drs
          INNER JOIN sys.dm_hadr_availability_replica_states AS ars
            ON ars.group_id = drs.group_id
           AND ars.replica_id = drs.replica_id
          WHERE drs.database_id = d.database_id
            AND drs.is_local = 1
            AND ars.is_local = 1
            AND ars.role = 1
      )
  );

------------------------------------------------------------
-- Configure database-level permissions
------------------------------------------------------------

OPEN DatabaseCursor;

FETCH NEXT FROM DatabaseCursor INTO @Database;

WHILE @@FETCH_STATUS = 0
BEGIN

    BEGIN TRY

        ----------------------------------------------------
        -- Create or validate database user
        ----------------------------------------------------

        SET @SQL = N'
USE ' + QUOTENAME(@Database) + N';

IF NOT EXISTS
(
    SELECT 1
    FROM sys.database_principals
    WHERE name = @UserName
)
BEGIN

    DECLARE @CreateSQL nvarchar(max);

    SET @CreateSQL =
        N''CREATE USER '' + QUOTENAME(@UserName) +
        N'' FOR LOGIN '' + QUOTENAME(@UserName);

    EXEC sys.sp_executesql @CreateSQL;

END
ELSE
BEGIN

    DECLARE @UserSID varbinary(85);
    DECLARE @LoginSID varbinary(85);

    SELECT @UserSID = sid
    FROM sys.database_principals
    WHERE name = @UserName;

    SELECT @LoginSID = sid
    FROM sys.server_principals
    WHERE name = @UserName;

    IF @UserSID <> @LoginSID
    BEGIN

        DECLARE @AlterSQL nvarchar(max);

        SET @AlterSQL =
            N''ALTER USER '' + QUOTENAME(@UserName) +
            N'' WITH LOGIN = '' + QUOTENAME(@UserName);

        EXEC sys.sp_executesql @AlterSQL;

    END;

END;
';

        EXEC sys.sp_executesql
            @SQL,
            N'@UserName sysname',
            @UserName = @LoginName;

        ----------------------------------------------------
        -- Grant database access and metadata visibility
        ----------------------------------------------------

        SET @SQL =
            N'USE ' + QUOTENAME(@Database) + N';
              GRANT CONNECT TO ' +
              QUOTENAME(@LoginName) + N';
              GRANT VIEW DEFINITION TO ' +
              QUOTENAME(@LoginName) + N';';

        EXEC sys.sp_executesql @SQL;

        ----------------------------------------------------
        -- Grant Query Store / DMV permissions
        ----------------------------------------------------

        IF @MajorVersion >= 16
        BEGIN

            SET @SQL =
                N'USE ' + QUOTENAME(@Database) + N';
                  GRANT VIEW DATABASE PERFORMANCE STATE TO ' +
                  QUOTENAME(@LoginName) + N';';

        END
        ELSE
        BEGIN

            SET @SQL =
                N'USE ' + QUOTENAME(@Database) + N';
                  GRANT VIEW DATABASE STATE TO ' +
                  QUOTENAME(@LoginName) + N';';

        END;

        EXEC sys.sp_executesql @SQL;

        ----------------------------------------------------
        -- DBA database: grant db_datareader
        --
        -- Read access to all user tables and views
        -- in DBA, including dbo.LoginActivity.
        ----------------------------------------------------

        IF @Database = N'DBA'
        BEGIN

            SET @SQL = N'
USE [DBA];

IF NOT EXISTS
(
    SELECT 1
    FROM sys.database_role_members AS drm
    INNER JOIN sys.database_principals AS r
        ON r.principal_id = drm.role_principal_id
    INNER JOIN sys.database_principals AS u
        ON u.principal_id = drm.member_principal_id
    WHERE r.name = N''db_datareader''
      AND u.name = @UserName
)
BEGIN

    EXEC sys.sp_addrolemember
        @rolename = N''db_datareader'',
        @membername = @UserName;

END;
';

            EXEC sys.sp_executesql
                @SQL,
                N'@UserName sysname',
                @UserName = @LoginName;

            SET @DBAReadAccess = 'GRANTED';

        END;

        ----------------------------------------------------
        -- Record successful database configuration
        ----------------------------------------------------

        SET @UpdatedDatabases =
            @UpdatedDatabases + 1;

        INSERT INTO @DatabaseResults
        (
            DatabaseName,
            Status,
            Details
        )
        VALUES
        (
            @Database,
            N'OK',
            CASE
                WHEN @Database = N'DBA'
                THEN N'Permissions configured; db_datareader granted'
                ELSE N'Permissions configured'
            END
        );

    END TRY
    BEGIN CATCH

        SET @ErrorDatabases =
            @ErrorDatabases + 1;

        IF @Database = N'DBA'
        BEGIN
            SET @DBAReadAccess = 'ERROR';
        END;

        INSERT INTO @DatabaseResults
        (
            DatabaseName,
            Status,
            Details
        )
        VALUES
        (
            @Database,
            N'ERROR',
            ERROR_MESSAGE()
        );

    END CATCH;

    FETCH NEXT FROM DatabaseCursor INTO @Database;

END;

CLOSE DatabaseCursor;
DEALLOCATE DatabaseCursor;

------------------------------------------------------------
-- CMS summary: one row per SQL Server instance
------------------------------------------------------------

SELECT
    @@SERVERNAME AS ServerName,
    @MajorVersion AS SQLMajorVersion,
    @LoginName AS LoginName,

    CASE
        WHEN @LoginCreated = 1 THEN N'CREATED'
        ELSE N'EXISTING'
    END AS LoginStatus,

    @UpdatedDatabases AS UpdatedDatabases,
    @ErrorDatabases AS ErrorDatabases,
    @DBAReadAccess AS DBAReadAccess,

    CASE
        WHEN @ErrorDatabases = 0 THEN N'OK'
        ELSE N'PARTIAL'
    END AS Status;

------------------------------------------------------------
-- Database-level errors only
------------------------------------------------------------

SELECT
    @@SERVERNAME AS ServerName,
    DatabaseName,
    Status,
    Details
FROM @DatabaseResults
WHERE Status = N'ERROR'
ORDER BY DatabaseName;
