
/*
===============================================================================
ZABBIX SQL SERVER MONITORING - VERSION 1.0
===============================================================================
Name         : 6.sql.jobs.failed_24h
Purpose      : Count distinct SQL Server Agent jobs with at least
               one failed execution during the last 24 hours.

ODBC Key     : db.odbc.select[6.sql.jobs.failed_24h,,"Driver={$MSSQL.ODBC.DRIVER};Server={$MSSQL.HOST};Port={$MSSQL.PORT};UID={$MSSQL.USER};PWD={$MSSQL.PASSWORD};Encrypt={$MSSQL.ENCRYPT}"]

Interval     : 5m
History      : 90d
Trends       : 365d
Type         : Numeric (unsigned)
Compatibility: SQL Server 2012+

AG Handling  : Not applicable. Instance-level metric.

Notes        : Uses msdb.dbo.sysjobhistory.
               Counts distinct jobs, not failed executions.
               Includes only job outcome records (step_id = 0).
               Includes jobs that subsequently succeeded.
               Calculates execution completion time using
               run_date, run_time and run_duration.
               Excludes individual job step failures when
               the overall job execution succeeded.
               Requires permission to read job history.
               Returns one integer.
===============================================================================
*/

SET NOCOUNT ON;

DECLARE @Now datetime = GETDATE();

------------------------------------------------------------
-- Find failed SQL Server Agent job executions
------------------------------------------------------------

;WITH FailedRuns AS
(
    SELECT
        h.job_id,

        ----------------------------------------------------
        -- Calculate execution completion time
        ----------------------------------------------------

        DATEADD
        (
            SECOND,

            (h.run_duration / 10000) * 3600
            + ((h.run_duration % 10000) / 100) * 60
            + (h.run_duration % 100),

            DATEADD
            (
                SECOND,

                (h.run_time / 10000) * 3600
                + ((h.run_time % 10000) / 100) * 60
                + (h.run_time % 100),

                CONVERT
                (
                    datetime,
                    CONVERT(varchar(8), h.run_date),
                    112
                )
            )
        ) AS FinishedAt

    FROM msdb.dbo.sysjobhistory AS h

    WHERE h.step_id = 0
      AND h.run_status = 0
      AND h.run_date > 0
)

------------------------------------------------------------
-- Count distinct jobs with failures in the last 24 hours
------------------------------------------------------------

SELECT
    COUNT(DISTINCT job_id) AS failed_jobs_24h

FROM FailedRuns

WHERE FinishedAt >= DATEADD(HOUR, -24, @Now)
  AND FinishedAt <= @Now;
