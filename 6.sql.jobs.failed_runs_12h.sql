
/*
===============================================================================
ZABBIX SQL SERVER MONITORING - VERSION 1.0
===============================================================================
Name         : 6.sql.jobs.failed_runs_12h
Purpose      : Count failed SQL Server Agent job executions
               during the last 12 hours for currently enabled jobs.

ODBC Key     : db.odbc.select[6.sql.jobs.failed_runs_12h,,"Driver={$MSSQL.ODBC.DRIVER};Server={$MSSQL.HOST};Port={$MSSQL.PORT};UID={$MSSQL.USER};PWD={$MSSQL.PASSWORD};Encrypt={$MSSQL.ENCRYPT}"]

Interval     : 5m
History      : 90d
Trends       : 365d
Type         : Numeric (unsigned)
Compatibility: SQL Server 2012+

AG Handling  : Not applicable. Instance-level metric.

Notes        : Uses msdb.dbo.sysjobhistory and sysjobs.
               Counts failed executions, not distinct jobs.
               Includes only job outcome records (step_id = 0).
               Includes currently enabled jobs only.
               Uses job start time for the 12-hour window.
               A job may subsequently have succeeded.
               Requires permission to read SQL Agent history.
               Returns one integer.
===============================================================================
*/

SET NOCOUNT ON;

DECLARE @Now datetime = GETDATE();

------------------------------------------------------------
-- Count failed executions of enabled SQL Agent jobs
------------------------------------------------------------

SELECT
    COUNT(*) AS failed_runs_12h

FROM msdb.dbo.sysjobhistory AS h

INNER JOIN msdb.dbo.sysjobs AS j
    ON j.job_id = h.job_id

WHERE h.step_id = 0
  AND h.run_status = 0
  AND h.run_date > 0
  AND j.enabled = 1

  AND msdb.dbo.agent_datetime
      (
          h.run_date,
          h.run_time
      ) >= DATEADD(HOUR, -12, @Now)

  AND msdb.dbo.agent_datetime
      (
          h.run_date,
          h.run_time
      ) <= @Now;
