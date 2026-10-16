
/*
===============================================================================
ZABBIX SQL SERVER MONITORING - VERSION 1.0
===============================================================================
Name         : 8.sql.maintenance.index_maintenance_overdue_count
Purpose      : Count enabled IndexOptimize jobs without a
               successful execution within the last 8 days.

ODBC Key     : db.odbc.select[8.sql.maintenance.index_maintenance_overdue_count,,"Driver={$MSSQL.ODBC.DRIVER};Server={$MSSQL.HOST};Port={$MSSQL.PORT};UID={$MSSQL.USER};PWD={$MSSQL.PASSWORD};Encrypt={$MSSQL.ENCRYPT}"]

Interval     : 24h
History      : 730d
Trends       : 1815d
Type         : Numeric (unsigned)
Compatibility: SQL Server 2012+

AG Handling  : Instance-level SQL Agent job monitoring.

Notes        : Uses msdb SQL Agent job history.
               Checks enabled jobs named IndexOptimize%.
               Counts jobs without a successful execution
               during the last 8 days.
               Returns one integer.
               Read-only.
===============================================================================
*/

SET NOCOUNT ON;

SELECT
    COUNT(*) AS index_maintenance_overdue_count
FROM msdb.dbo.sysjobs AS j
WHERE j.enabled = 1
  AND j.name LIKE N'IndexOptimize%'
  AND NOT EXISTS
  (
      SELECT 1
      FROM msdb.dbo.sysjobhistory AS h
      WHERE h.job_id = j.job_id
        AND h.step_id = 0
        AND h.run_status = 1
        AND msdb.dbo.agent_datetime
            (
                h.run_date,
                h.run_time
            ) >= DATEADD(DAY, -8, GETDATE())
  );
