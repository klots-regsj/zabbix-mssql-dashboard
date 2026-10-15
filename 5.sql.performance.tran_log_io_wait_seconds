
/*
===============================================================================
ZABBIX SQL SERVER MONITORING - VERSION 1.1
===============================================================================
Name         : 5.sql.performance.tran_log_io_wait_seconds
Purpose      : Return total Query Store transaction log I/O
               wait time in seconds for the latest completed
               60-minute interval across accessible databases.

ODBC Key     : db.odbc.select[5.sql.performance.tran_log_io_wait_seconds,,"Driver={$MSSQL.ODBC.DRIVER};Server={$MSSQL.HOST};Port={$MSSQL.PORT};UID={$MSSQL.USER};PWD={$MSSQL.PASSWORD};Encrypt={$MSSQL.ENCRYPT}"]

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
               Wait category 14 = Tran Log IO.
               Requires Query Store READ_WRITE.
               Requires wait statistics capture ON.
               Requires 60-minute Query Store intervals.
               Uses the latest completed interval per database.
               Converts milliseconds to seconds.
               Excludes system, DBA%, offline and snapshot
               databases.
               Skips databases where HAS_DBACCESS <> 1.
               Skips databases where Query Store is OFF.
               Returns zero if no waits exist in a valid interval.
               Raises errors for other incomplete collection.
               Requires sufficient Query Store permissions.
               Returns one decimal value.
===============================================================================
*/

SET NOCOUNT ON;

------------------------------------------------------------
-- Require SQL Server 2019 or newer
------------------------------------------------------------

IF COALESCE
(
    TRY_CONVERT
    (
        int,
        SERVERPROPERTY('ProductMajorVersion')
    ),
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

CREATE TABLE #LogIOWaits
(
    DatabaseName sysname NOT NULL,
    LogIOWaitSeconds decimal(28,3) NOT NULL
);

DECLARE @DatabaseName sysname;
DECLARE @SQL nvarchar(max);

DECLARE @Now datetimeoffset(7) =
    TODATETIMEOFFSET(SYSUTCDATETIME(), '+00:00');

------------------------------------------------------------
-- Find eligible and accessible databases
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
-- Collect Query Store transaction log I/O waits
------------------------------------------------------------

BEGIN TRY

    OPEN DatabaseCursor;

    FETCH NEXT FROM DatabaseCursor INTO @DatabaseName;

    WHILE @@FETCH_STATUS = 0
    BEGIN

        SET @SQL = N'
USE ' + QUOTENAME(@DatabaseName) + N';

DECLARE @ErrorMessage nvarchar(2048);
DECLARE @IntervalId bigint;

------------------------------------------------------------
-- Skip databases where Query Store is OFF
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
    SET @ErrorMessage =
        N''Incompatible Query Store configuration: ''
        + DB_NAME();

    THROW 50001, @ErrorMessage, 1;
END;

------------------------------------------------------------
-- Find latest completed 60-minute interval
------------------------------------------------------------

SELECT TOP (1)
    @IntervalId = runtime_stats_interval_id
FROM sys.query_store_runtime_stats_interval
WHERE end_time <= @Now
  AND end_time >= DATEADD(MINUTE, -120, @Now)
  AND DATEDIFF(SECOND, start_time, end_time) = 3600
ORDER BY end_time DESC;

IF @IntervalId IS NULL
BEGIN
    SET @ErrorMessage =
        N''No recent completed Query Store interval: ''
        + DB_NAME();

    THROW 50002, @ErrorMessage, 1;
END;

------------------------------------------------------------
-- Collect transaction log I/O wait time
------------------------------------------------------------

INSERT INTO #LogIOWaits
(
    DatabaseName,
    LogIOWaitSeconds
)
SELECT
    DB_NAME(),
    CAST
    (
        COALESCE
        (
            SUM
            (
                CAST
                (
                    total_query_wait_time_ms
                    AS decimal(28,3)
                )
            ),
            0
        ) / 1000.0
        AS decimal(28,3)
    )
FROM sys.query_store_wait_stats
WHERE runtime_stats_interval_id = @IntervalId
  AND wait_category = 14;
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
        FROM #LogIOWaits
    )
    BEGIN
        THROW 50003,
            'No eligible accessible databases with Query Store data.',
            1;
    END;

    --------------------------------------------------------
    -- Return total transaction log I/O wait time
    --------------------------------------------------------

    SELECT
        CAST
        (
            SUM(LogIOWaitSeconds)
            AS decimal(28,3)
        ) AS tran_log_io_wait_seconds
    FROM #LogIOWaits;

    DROP TABLE #LogIOWaits;

END TRY
BEGIN CATCH

    IF CURSOR_STATUS('local', 'DatabaseCursor') >= 0
        CLOSE DatabaseCursor;

    IF CURSOR_STATUS('local', 'DatabaseCursor') >= -1
        DEALLOCATE DatabaseCursor;

    IF OBJECT_ID('tempdb..#LogIOWaits') IS NOT NULL
        DROP TABLE #LogIOWaits;

    THROW;

END CATCH;
