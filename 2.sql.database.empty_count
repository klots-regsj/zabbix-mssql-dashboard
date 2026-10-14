
/*
===============================================================================
ZABBIX SQL SERVER MONITORING - VERSION 1.0
===============================================================================
Name         : 2.sql.database.empty_count
Purpose      : Count user databases older than 30 days that contain
               no user-defined objects. Identifies databases that
               may have been created but never put into production.

ODBC Key     : db.odbc.select[2.sql.database.empty_count,,"Driver={$MSSQL.ODBC.DRIVER};Server={$MSSQL.HOST};Port={$MSSQL.PORT};UID={$MSSQL.USER};PWD={$MSSQL.PASSWORD};Encrypt={$MSSQL.ENCRYPT}"]

Interval     : 24h
History      : 730d
Trends       : 1825d
Type         : Numeric (unsigned)
Compatibility: SQL Server 2012+

AG Handling  : Include standalone and local AG primary databases.
               Exclude AG secondary databases.

Notes        : Excludes system databases, DBA% databases,
               snapshots and offline databases.
               Includes read-only databases.
               Requires metadata visibility in each database.
               Returns one integer or raises an error.
===============================================================================
*/

SET NOCOUNT ON;

DECLARE @EmptyDatabases int = 0;
DECLARE @Database sysname;
DECLARE @SQL nvarchar(max);

------------------------------------------------------------
-- Select eligible databases
--
-- Include:
--   * Standalone databases
--   * Local AG primary databases
--   * Databases at least 30 days old
--
-- Exclude:
--   * System databases
--   * DBA% databases
--   * Database snapshots
--   * Offline databases
--   * AG secondary databases
------------------------------------------------------------

DECLARE databases CURSOR LOCAL FAST_FORWARD FOR

SELECT
    d.name
FROM sys.databases AS d
WHERE d.database_id > 4
  AND d.state_desc = N'ONLINE'
  AND d.source_database_id IS NULL
  AND d.create_date <= DATEADD(DAY, -30, GETDATE())
  AND d.name NOT LIKE N'DBA%'

  AND
  (
      -- Standalone databases
      d.replica_id IS NULL

      OR

      -- Local AG primary databases
      EXISTS
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
-- Inspect each database
------------------------------------------------------------

BEGIN TRY

    OPEN databases;

    FETCH NEXT FROM databases INTO @Database;

    WHILE @@FETCH_STATUS = 0
    BEGIN

        SET @SQL = N'
            USE ' + QUOTENAME(@Database) + N';

            IF NOT EXISTS
            (
                SELECT 1
                FROM sys.objects
                WHERE is_ms_shipped = 0
                  AND type NOT IN (N''S'', N''IT'')
            )
            BEGIN
                SET @Count = @Count + 1;
            END;
        ';

        EXEC sys.sp_executesql
            @SQL,
            N'@Count int OUTPUT',
            @Count = @EmptyDatabases OUTPUT;

        FETCH NEXT FROM databases INTO @Database;

    END;

    CLOSE databases;
    DEALLOCATE databases;

END TRY
BEGIN CATCH

    IF CURSOR_STATUS('local', 'databases') >= 0
        CLOSE databases;

    IF CURSOR_STATUS('local', 'databases') >= -1
        DEALLOCATE databases;

    THROW;

END CATCH;

------------------------------------------------------------
-- Return result to Zabbix
------------------------------------------------------------

SELECT
    @EmptyDatabases AS databases_without_user_objects;
