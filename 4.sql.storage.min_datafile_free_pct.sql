
/*
===============================================================================
ZABBIX SQL SERVER MONITORING - VERSION 1.0
===============================================================================
Name         : 4.sql.storage.min_datafile_free_pct
Purpose      : Return the lowest percentage of unused allocated
               data file space among eligible user databases.

ODBC Key     : db.odbc.select[4.sql.storage.min_datafile_free_pct,,"Driver={$MSSQL.ODBC.DRIVER};Server={$MSSQL.HOST};Port={$MSSQL.PORT};UID={$MSSQL.USER};PWD={$MSSQL.PASSWORD};Encrypt={$MSSQL.ENCRYPT}"]

Interval     : 1h
History      : 365d
Trends       : 730d
Type         : Numeric (float)
Units        : %
Compatibility: SQL Server 2012+

AG Handling  : Include standalone and local AG primary databases.
               Exclude AG secondary databases.

Notes        : Automatically includes all ROWS data files,
               regardless of drive or storage location.
               Evaluates databases with more than 1 GB of
               allocated data file space.
               Excludes system databases, DBA% databases,
               snapshots and offline databases.
               Includes read-only databases.
               Measures free space inside allocated data files,
               not free space on the underlying disk.
               Requires access to database file metadata.
               Returns one decimal value.
===============================================================================
*/

SET NOCOUNT ON;

------------------------------------------------------------
-- Temporary result table
------------------------------------------------------------

CREATE TABLE #Result
(
    DatabaseName sysname NOT NULL,
    FreePercent decimal(9,2) NULL
);

DECLARE @Database sysname;
DECLARE @SQL nvarchar(max);

------------------------------------------------------------
-- Select eligible databases
------------------------------------------------------------

DECLARE databases CURSOR LOCAL FAST_FORWARD FOR

SELECT
    d.name
FROM sys.databases AS d
WHERE d.database_id > 4
  AND d.state_desc = N'ONLINE'
  AND d.source_database_id IS NULL
  AND d.name NOT LIKE N'DBA%'
  AND HAS_DBACCESS(d.name) = 1

  AND
  (
      -- Standalone database
      d.replica_id IS NULL

      OR

      -- Local AG primary database
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
-- Calculate free space percentage per database
------------------------------------------------------------

BEGIN TRY

    OPEN databases;

    FETCH NEXT FROM databases INTO @Database;

    WHILE @@FETCH_STATUS = 0
    BEGIN

        SET @SQL = N'
USE ' + QUOTENAME(@Database) + N';

INSERT INTO #Result
(
    DatabaseName,
    FreePercent
)
SELECT
    DB_NAME(),

    CAST
    (
        CASE
            WHEN COUNT(*) = COUNT(FILEPROPERTY(name, ''SpaceUsed''))
            THEN
                100.0 *
                (
                    SUM(CAST(size AS bigint))
                    - SUM(CAST(FILEPROPERTY(name, ''SpaceUsed'') AS bigint))
                )
                / NULLIF(SUM(CAST(size AS bigint)), 0)
        END
        AS decimal(9,2)
    )

FROM sys.database_files
WHERE type = 0

HAVING SUM(CAST(size AS bigint)) > 131072;
';

        EXEC sys.sp_executesql @SQL;

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

    DROP TABLE #Result;

    THROW;

END CATCH;

------------------------------------------------------------
-- Return lowest free percentage to Zabbix
------------------------------------------------------------

SELECT
    MIN(FreePercent) AS min_datafile_free_pct
FROM #Result;

DROP TABLE #Result;
