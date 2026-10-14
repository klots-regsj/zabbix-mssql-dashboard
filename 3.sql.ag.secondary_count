/*
===============================================================================
ZABBIX SQL SERVER MONITORING - VERSION 1.0
===============================================================================
Name         : 3.sql.ag.secondary_count
Purpose      : Count online, writable user databases belonging to
               local Always On secondary replicas.

ODBC Key     : db.odbc.select[3.sql.ag.secondary_count,,"Driver={$MSSQL.ODBC.DRIVER};Server={$MSSQL.HOST};Port={$MSSQL.PORT};UID={$MSSQL.USER};PWD={$MSSQL.PASSWORD};Encrypt={$MSSQL.ENCRYPT}"]

Interval     : 1h
History      : 365d
Trends       : 730d
Type         : Numeric (unsigned)
Compatibility: SQL Server 2012+

AG Handling  : Count databases on local AG secondary replicas only.

Notes        : Excludes system databases, DBA% databases,
               database snapshots and read-only databases.
               Returns one integer.
===============================================================================
*/

SET NOCOUNT ON;

------------------------------------------------------------
-- Count databases on local AG secondary replicas
--
-- Include:
--   * Online user databases
--   * Local AG secondary databases
--
-- Exclude:
--   * System databases
--   * DBA% databases
--   * Database snapshots
--   * Read-only databases
--   * AG primary databases
--   * Standalone databases
------------------------------------------------------------

SELECT
    COUNT(*) AS DatabaseCount
FROM sys.databases AS db
WHERE db.database_id > 4
  AND db.name NOT LIKE 'DBA%'
  AND db.state = 0
  AND db.source_database_id IS NULL

  AND EXISTS
  (
      SELECT 1
      FROM sys.dm_hadr_database_replica_states AS drs

      INNER JOIN sys.dm_hadr_availability_replica_states AS ars
          ON ars.group_id = drs.group_id
         AND ars.replica_id = drs.replica_id

      WHERE drs.database_id = db.database_id
        AND drs.is_local = 1
        AND ars.is_local = 1
        AND ars.role = 2
  );
