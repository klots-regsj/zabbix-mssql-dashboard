
/*
===============================================================================
ZABBIX SQL SERVER MONITORING - VERSION 1.0
===============================================================================
Name         : 4.sql.storage.logfile_used_pct
Purpose      : Return the highest transaction log utilization
               percentage among eligible user databases.

ODBC Key     : db.odbc.select[4.sql.storage.logfile_used_pct,,"Driver={$MSSQL.ODBC.DRIVER};Server={$MSSQL.HOST};Port={$MSSQL.PORT};UID={$MSSQL.USER};PWD={$MSSQL.PASSWORD};Encrypt={$MSSQL.ENCRYPT}"]

Interval     : 1h
History      : 365d
Trends       : 730d
Type         : Numeric (float)
Units        : %
Compatibility: SQL Server 2012+

AG Handling  : Includes standalone and local AG primary databases.
               Excludes local AG secondary databases.

Notes        : Uses sys.dm_db_log_space_usage.
               Measures used transaction log space as a
               percentage of allocated transaction log space.
               Excludes system databases, DBA% databases,
               snapshots and offline databases.
               Does not measure free disk space or log growth
               capacity.
               Returns one numeric value.
===============================================================================
*/

SET NOCOUNT ON;

DECLARE @Database sysname;
DECLARE @SQL nvarchar(max);
DECLARE @MaxUsedPct float = 0;
DECLARE @CurrentUsedPct float;

------------------------------------------------------------
-- Find eligible databases
------------------------------------------------------------

DECLARE database_cursor CURSOR LOCAL FAST_FORWARD FOR

SELECT
    d.name
FROM sys.databases AS d
WHERE d.database_id > 4
  AND d.state_desc = N'ONLINE'
  AND d.source_database_id IS NULL
  AND d.name NOT LIKE N'DBA%'
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
-- Check transaction log usage in each database
------------------------------------------------------------

OPEN database_cursor;

FETCH NEXT FROM database_cursor INTO @Database;

WHILE @@FETCH_STATUS = 0
BEGIN

    SET @CurrentUsedPct = NULL;

    SET @SQL = N'
        USE ' + QUOTENAME(@Database) + N';

        SELECT
            @UsedPct =
                CONVERT(float, used_log_space_in_percent)
        FROM sys.dm_db_log_space_usage;
    ';

    BEGIN TRY

        EXEC sys.sp_executesql
            @SQL,
            N'@UsedPct float OUTPUT',
            @UsedPct = @CurrentUsedPct OUTPUT;

        IF @CurrentUsedPct > @MaxUsedPct
        BEGIN
            SET @MaxUsedPct = @CurrentUsedPct;
        END;

    END TRY
    BEGIN CATCH
        -- Skip databases that cannot be queried.
    END CATCH;

    FETCH NEXT FROM database_cursor INTO @Database;

END;

CLOSE database_cursor;
DEALLOCATE database_cursor;

------------------------------------------------------------
-- Return highest transaction log utilization
------------------------------------------------------------

SELECT
    CONVERT(float, ROUND(@MaxUsedPct, 2))
        AS logfile_used_pct;
