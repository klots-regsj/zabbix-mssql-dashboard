
/*
===============================================================================
ZABBIX SQL SERVER MONITORING - VERSION 1.0
===============================================================================
Name         : 8.sql.maintenance.checkdb_overdue_count
Purpose      : Count user databases without a successful
               DBCC CHECKDB within the last 7 days.

ODBC Key     : db.odbc.select[8.sql.maintenance.checkdb_overdue_count,,"Driver={$MSSQL.ODBC.DRIVER};Server={$MSSQL.HOST};Port={$MSSQL.PORT};UID={$MSSQL.USER};PWD={$MSSQL.PASSWORD};Encrypt={$MSSQL.ENCRYPT}"]

Interval     : 24h
History      : 730d
Trends       : 1815d
Type         : Numeric (unsigned)
Compatibility: SQL Server 2012+

AG Handling  : Includes standalone and local AG primary
               databases. Excludes AG secondaries.

Notes        : Reads master.dbo.CommandLog.
               Excludes system databases, DBA databases,
               snapshots and offline databases.
               Returns one integer.
               Read-only.
===============================================================================
*/

SET NOCOUNT ON;

SELECT
    COUNT(*) AS checkdb_overdue_count
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
      FROM master.dbo.CommandLog AS cl
      WHERE cl.DatabaseName = d.name
        AND cl.CommandType = N'DBCC_CHECKDB'
        AND cl.ErrorNumber = 0
        AND cl.EndTime IS NOT NULL
        AND cl.EndTime >= DATEADD(DAY, -7, GETDATE())
  );
