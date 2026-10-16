
/*
===============================================================================
ZABBIX SQL SERVER MONITORING - VERSION 1.0
===============================================================================
Name         : 8.sql.maintenance.failed_maintenance_jobs_24h
Purpose      : Count failed Ola Hallengren maintenance job
               executions within the last 24 hours.

ODBC Key     : db.odbc.select[8.sql.maintenance.failed_maintenance_jobs_24h,,"Driver={$MSSQL.ODBC.DRIVER};Server={$MSSQL.HOST};Port={$MSSQL.PORT};UID={$MSSQL.USER};PWD={$MSSQL.PASSWORD};Encrypt={$MSSQL.ENCRYPT}"]

Interval     : 1h
History      : 730d
Trends       : 1815d
Type         : Numeric (unsigned)
Compatibility: SQL Server 2012+

AG Handling  : Instance-level SQL Agent monitoring.
               Works on standalone and AG replicas.

Notes        : Reads msdb.dbo.sysjobs and sysjobhistory.
               Checks completed job executions only.
               Includes DatabaseBackup, IndexOptimize
               and DatabaseIntegrityCheck jobs.
               Counts failures, not distinct jobs.
               Returns one integer.
               Read-only.
===============================================================================
*/

SET NOCOUNT ON;

SELECT
    COUNT(*) AS failed_maintenance_jobs_24h
FROM msdb.dbo.sysjobs AS j
INNER JOIN msdb.dbo.sysjobhistory AS h
    ON h.job_id = j.job_id
WHERE h.step_id = 0
  AND h.run_status = 0
  AND
  (
      j.name LIKE N'IndexOptimize%'
      OR j.name LIKE N'DatabaseIntegrityCheck%'
  )
  AND h.run_date > 0
  AND msdb.dbo.agent_datetime
      (
          h.run_date,
          h.run_time
      ) >= DATEADD(HOUR, -24, GETDATE());
