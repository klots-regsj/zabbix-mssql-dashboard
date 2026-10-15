
/*
===============================================================================
ZABBIX SQL SERVER MONITORING - VERSION 1.0
===============================================================================
Name         : 4.sql.storage.datafile_free_gb
Purpose      : Calculate total unused allocated data file space
               in GB across eligible user databases.

ODBC Key     : db.odbc.select[4.sql.storage.datafile_free_gb,,"Driver={$MSSQL.ODBC.DRIVER};Server={$MSSQL.HOST};Port={$MSSQL.PORT};UID={$MSSQL.USER};PWD={$MSSQL.PASSWORD};Encrypt={$MSSQL.ENCRYPT}"]

Interval     : 1h
History      : 365d
Trends       : 730d
Type         : Numeric (float)
Units        : GB
Compatibility: SQL Server 2012+

AG Handling  : Include standalone and local AG primary databases.
               Exclude AG secondary databases.

Notes        : Includes all ROWS data files regardless of drive.
               Excludes system databases, DBA% databases,
               snapshots and offline databases.
               Includes read-only databases.
               Measures unused space inside allocated data files,
               not free capacity on the underlying disk.
               Returns one decimal value or NULL if file usage
               information is unavailable.
===============================================================================
*/

SET NOCOUNT ON;

------------------------------------------------------------
-- Temporary result table
------------------------------------------------------------

CREATE TABLE #FreeSpace
(
    FreePages bigint NULL
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
-- Collect unused pages
------------------------------------------------------------

BEGIN TRY

    OPEN databases;

    FETCH NEXT FROM databases INTO @Database;

    WHILE @@FETCH_STATUS = 0
    BEGIN

        SET @SQL = N'
USE ' + QUOTENAME(@Database) + N';

INSERT INTO #FreeSpace
(
    FreePages
)
SELECT
    CAST(size AS bigint)
      - CAST(FILEPROPERTY(name, ''SpaceUsed'') AS bigint)
FROM sys.database_files
WHERE type = 0;
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

    DROP TABLE #FreeSpace;

    THROW;

END CATCH;

------------------------------------------------------------
-- Return total free space in GB
------------------------------------------------------------

SELECT
    CASE
        WHEN COUNT(*) = COUNT(FreePages)
        THEN
            CAST
            (
                COALESCE(SUM(FreePages), 0) / 131072.0
                AS decimal(18,2)
            )
    END AS datafile_free_gb
FROM #FreeSpace;

DROP TABLE #FreeSpace;
