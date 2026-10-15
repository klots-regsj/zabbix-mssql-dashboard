
/*
===============================================================================
ZABBIX SQL SERVER MONITORING - VERSION 1.1
===============================================================================
Name         : 5.sql.performance.max_query_duration_ms
Purpose      : Return the highest recorded individual query
               execution duration from Query Store runtime
               groups active during the last 5 minutes.

ODBC Key     : db.odbc.select[5.sql.performance.max_query_duration_ms,,"Driver={$MSSQL.ODBC.DRIVER};Server={$MSSQL.HOST};Port={$MSSQL.PORT};UID={$MSSQL.USER};PWD={$MSSQL.PASSWORD};Encrypt={$MSSQL.ENCRYPT}"]

Interval     : 5m
History      : 90d
Trends       : 365d
Type         : Numeric (float)
Units        : ms
Compatibility: SQL Server 2016+

AG Handling  : Includes standalone databases and local
               AG primary replicas only.
               Excludes AG secondary databases.

Notes        : Uses Query Store max_duration.
               Converts microseconds to milliseconds.
               Filters by last_execution_time.
               Skips databases without access.
               Skips databases where Query Store is OFF.
               Query Store aggregates runtime statistics,
               so max_duration may include executions
               outside the exact 5-minute window.
               Returns 0 if no eligible samples exist.
               Does not modify database configuration.
               Requires sufficient Query Store permissions.
               Returns one decimal value.
===============================================================================
*/

SET NOCOUNT ON;

DECLARE @DatabaseName sysname;
DECLARE @SQL nvarchar(max);

DECLARE @WindowEnd datetimeoffset(7) =
    TODATETIMEOFFSET(SYSUTCDATETIME(), '+00:00');

DECLARE @WindowStart datetimeoffset(7) =
    DATEADD(MINUTE, -5, @WindowEnd);

DECLARE @MaxDurationMs decimal(19,2) = 0;
DECLARE @DatabaseMaxMs decimal(19,2);

------------------------------------------------------------
-- Find eligible and accessible databases
------------------------------------------------------------

DECLARE database_cursor CURSOR LOCAL FAST_FORWARD FOR

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
-- Scan Query Store runtime statistics
------------------------------------------------------------

OPEN database_cursor;

FETCH NEXT FROM database_cursor INTO @DatabaseName;

WHILE @@FETCH_STATUS = 0
BEGIN

    SET @DatabaseMaxMs = NULL;

    SET @SQL = N'
USE ' + QUOTENAME(@DatabaseName) + N';

------------------------------------------------------------
-- Check whether Query Store is enabled
------------------------------------------------------------

IF EXISTS
(
    SELECT 1
    FROM sys.database_query_store_options
    WHERE actual_state_desc IN
    (
        N''READ_WRITE'',
        N''READ_ONLY''
    )
)
BEGIN

    --------------------------------------------------------
    -- Find maximum recorded execution duration
    --------------------------------------------------------

    SELECT
        @Result =
            CAST
            (
                MAX(rs.max_duration) / 1000.0
                AS decimal(19,2)
            )
    FROM sys.query_store_runtime_stats AS rs
    WHERE rs.last_execution_time >= @StartTime
      AND rs.last_execution_time <= @EndTime
      AND rs.count_executions > 0;

END;
';

    BEGIN TRY

        EXEC sys.sp_executesql
            @SQL,
            N'@StartTime datetimeoffset(7),
              @EndTime datetimeoffset(7),
              @Result decimal(19,2) OUTPUT',
            @StartTime = @WindowStart,
            @EndTime = @WindowEnd,
            @Result = @DatabaseMaxMs OUTPUT;

        IF @DatabaseMaxMs > @MaxDurationMs
        BEGIN
            SET @MaxDurationMs = @DatabaseMaxMs;
        END;

    END TRY
    BEGIN CATCH

        ----------------------------------------------------
        -- Skip databases that cannot be queried
        ----------------------------------------------------

    END CATCH;

    FETCH NEXT FROM database_cursor INTO @DatabaseName;

END;

CLOSE database_cursor;
DEALLOCATE database_cursor;

------------------------------------------------------------
-- Return maximum query execution duration
------------------------------------------------------------

SELECT
    @MaxDurationMs AS max_query_duration_ms;
