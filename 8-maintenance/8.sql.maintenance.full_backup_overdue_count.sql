
/*
===============================================================================
ZABBIX SQL SERVER MONITORING - VERSION 1.0
===============================================================================
Name         : 8.sql.maintenance.full_backup_overdue_count
Purpose      : Count user databases without a successful
               full database backup within the last 8 days.

ODBC Key     : db.odbc.select[8.sql.maintenance.full_backup_overdue_count,,"Driver={$MSSQL.ODBC.DRIVER};Server={$MSSQL.HOST};Port={$MSSQL.PORT};UID={$MSSQL.USER};PWD={$MSSQL.PASSWORD};Encrypt={$MSSQL.ENCRYPT}"]

Interval     : 1h
History      : 365d
Trends       : 730d
Type         : Numeric (unsigned)
Compatibility: SQL Server 2012+

AG Handling  : Includes standalone and local AG primary
               databases. Excludes AG secondaries.

Notes        : Reads msdb.dbo.backupset.
               Excludes system databases, DBA databases,
               snapshots and offline databases.
               Counts full database backups only.
               Returns one integer.
               Read-only.
===============================================================================
*/

SET NOCOUNT ON;

SELECT
    COUNT(*) AS full_backup_overdue_count
FROM sys.databases AS d
WHERE d.database_id > 4
  AND d.name NOT LIKE N'DBA%'
  AND d.state_desc = N'ONLINE'
  AND d.source_database_id IS NULL
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
  )
  AND NOT EXISTS
  (
      SELECT 1
      FROM msdb.dbo.backupset AS bs
      WHERE bs.database_name = d.name
        AND bs.type = 'D'
        AND bs.is_copy_only = 0
        AND bs.backup_finish_date >= DATEADD(DAY, -8, GETDATE())
  );
