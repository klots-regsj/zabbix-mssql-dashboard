
/*
===============================================================================
ZABBIX SQL SERVER MONITORING - VERSION 1.0
===============================================================================
Name         : 5.sql.performance.cpu_wait_seconds
Purpose      : Return total Query Store CPU-related wait
               time in seconds for the latest completed
               60-minute interval across eligible databases.

ODBC Key     : db.odbc.select[5.sql.performance.cpu_wait_seconds,,"Driver={$MSSQL.ODBC.DRIVER};Server={$MSSQL.HOST};Port={$MSSQL.PORT};UID={$MSSQL.USER};PWD={$MSSQL.PASSWORD};Encrypt={$MSSQL.ENCRYPT}"]

Interval     : 1h
History      : 365d
Trends       : 730d
Type         : Numeric (float)
Units        : s
Compatibility: SQL Server 2019+

AG Handling  : Includes standalone databases and local
               AG primary replicas only.
               Excludes AG secondary databases.

Notes        : Uses sys.query_store_wait_stats.
               Wait category 1 = CPU.
               Requires Query Store READ_WRITE.
               Requires wait statistics capture ON.
               Requires 60-minute Query Store intervals.
               Uses the latest completed interval.
               Converts milliseconds to seconds.
               Measures accumulated CPU-related waits,
               not actual CPU execution time.
               Throws an error if an eligible Query Store
               database cannot be collected.
               Returns one decimal value.
===============================================================================
*/

SET NOCOUNT ON;

------------------------------------------------------------
-- Require SQL Server 2019 or newer
------------------------------------------------------------

IF COALESCE
(
    CONVERT(int, SERVERPROPERTY('ProductMajorVersion')),
    0
) < 15
BEGIN
    THROW 50000,
        'SQL Server 2019 or newer is required.',
        1;
END;

------------------------------------------------------------
-- Temporary result table
------------------------------------------------------------

CREATE TABLE #CPUWaits
(
    DatabaseName sysname NOT NULL,
    CPUWaitSeconds decimal(28,3) NOT NULL
);

DECLARE @DatabaseName sysname;
DECLARE @SQL nvarchar(max);

DECLARE @Now datetimeoffset(7) =
    TODATETIMEOFFSET(GETUTCDATE(), '+00:00');

------------------------------------------------------------
-- Find eligible databases
------------------------------------------------------------

DECLARE DatabaseCursor CURSOR LOCAL FAST_FORWARD FOR

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
-- Collect Query Store CPU waits
------------------------------------------------------------

BEGIN TRY

    OPEN DatabaseCursor;

    FETCH NEXT FROM DatabaseCursor INTO @DatabaseName;

    WHILE @@FETCH_STATUS = 0
    BEGIN

        SET @SQL = N'
USE ' + QUOTENAME(@DatabaseName) + N';

------------------------------------------------------------
-- Skip databases where Query Store is disabled
------------------------------------------------------------

IF NOT EXISTS
(
    SELECT 1
    FROM sys.database_query_store_options
    WHERE actual_state_desc <> N''OFF''
)
BEGIN
    RETURN;
END;

------------------------------------------------------------
-- Validate Query Store configuration
------------------------------------------------------------

IF NOT EXISTS
(
    SELECT 1
    FROM sys.database_query_store_options
    WHERE actual_state_desc = N''READ_WRITE''
      AND interval_length_minutes = 60
      AND wait_stats_capture_mode_desc = N''ON''
)
BEGIN
    THROW 50001,
        ''Query Store configuration is not compatible.'',
        1;
END;

------------------------------------------------------------
-- Find latest completed 60-minute interval
------------------------------------------------------------

DECLARE @IntervalId bigint;

SELECT TOP (1)
    @IntervalId = runtime_stats_interval_id
FROM sys.query_store_runtime_stats_interval
WHERE end_time <= @Now
  AND end_time >= DATEADD(MINUTE, -120, @Now)
  AND DATEDIFF(SECOND, start_time, end_time) = 3600
ORDER BY end_time DESC;

IF @IntervalId IS NULL
BEGIN
    THROW 50002,
        ''No completed Query Store interval found.'',
        1;
END;

------------------------------------------------------------
-- Collect CPU-related wait time
------------------------------------------------------------

INSERT INTO #CPUWaits
(
    DatabaseName,
    CPUWaitSeconds
)
SELECT
    DB_NAME(),
    CAST
    (
        COALESCE
        (
            SUM(CAST(total_query_wait_time_ms AS decimal(28,3))),
            0
        ) / 1000.0
        AS decimal(28,3)
    )
FROM sys.query_store_wait_stats
WHERE runtime_stats_interval_id = @IntervalId
  AND wait_category = 1;
';

        EXEC sys.sp_executesql
            @SQL,
            N'@Now datetimeoffset(7)',
            @Now = @Now;

        FETCH NEXT FROM DatabaseCursor INTO @DatabaseName;

    END;

    CLOSE DatabaseCursor;
    DEALLOCATE DatabaseCursor;

    --------------------------------------------------------
    -- Require at least one collected database
    --------------------------------------------------------

    IF NOT EXISTS
    (
        SELECT 1
        FROM #CPUWaits
    )
    BEGIN
        THROW 50003,
            'No eligible databases with Query Store data.',
            1;
    END;

    --------------------------------------------------------
    -- Return total CPU-related wait time
    --------------------------------------------------------

    SELECT
        CAST
        (
            SUM(CPUWaitSeconds)
            AS decimal(28,3)
        ) AS cpu_wait_seconds
    FROM #CPUWaits;

    DROP TABLE #CPUWaits;

END TRY
BEGIN CATCH

    IF CURSOR_STATUS('local', 'DatabaseCursor') >= 0
        CLOSE DatabaseCursor;

    IF CURSOR_STATUS('local', 'DatabaseCursor') >= -1
        DEALLOCATE DatabaseCursor;

    IF OBJECT_ID('tempdb..#CPUWaits') IS NOT NULL
        DROP TABLE #CPUWaits;

    THROW;

END CATCH;
