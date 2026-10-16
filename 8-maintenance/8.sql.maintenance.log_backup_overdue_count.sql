
/*
===============================================================================
ZABBIX SQL SERVER MONITORING - VERSION 1.0
===============================================================================
Name         : 8.sql.maintenance.log_backup_overdue_count
Purpose      : Count standalone databases without a successful
               transaction log backup within 60 minutes.

ODBC Key     : db.odbc.select[8.sql.maintenance.log_backup_overdue_count,,"Driver={$MSSQL.ODBC.DRIVER};Server={$MSSQL.HOST};Port={$MSSQL.PORT};UID={$MSSQL.USER};PWD={$MSSQL.PASSWORD};Encrypt={$MSSQL.ENCRYPT}"]

Interval     : 15m
History      : 730d
Trends       : 1815d
Type         : Numeric (unsigned)
Compatibility: SQL Server 2012+

AG Handling  : Excludes ALL AG databases, including primary
               and secondary replicas.

Notes        : Includes FULL and BULK_LOGGED recovery models.
               Excludes SIMPLE, system databases, DBA databases,
               snapshots and offline databases.
               Reads local msdb backup history.
               Returns one integer.
               Read-only.
===============================================================================
*/

SET NOCOUNT ON;

SELECT
    COUNT(*) AS log_backup_overdue_count
FROM sys.databases AS d
WHERE d.database_id > 4
  AND d.name NOT LIKE N'DBA%'
  AND d.state_desc = N'ONLINE'
  AND d.source_database_id IS NULL
  AND d.recovery_model_desc IN (N'FULL', N'BULK_LOGGED')

  ----------------------------------------------------------
  -- Standalone databases only
  ----------------------------------------------------------

  AND d.replica_id IS NULL

  ----------------------------------------------------------
  -- No successful log backup within 60 minutes
  ----------------------------------------------------------

  AND NOT EXISTS
  (
      SELECT 1
      FROM msdb.dbo.backupset AS b
      WHERE b.database_name = d.name
        AND b.type = 'L'
        AND b.backup_finish_date >= DATEADD(MINUTE, -60, GETDATE())
  );
