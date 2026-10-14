
/*
===============================================================================
ZABBIX SQL SERVER MONITORING
===============================================================================
Name         : 2.sql.database.count
Original     : 1 Count DB
Purpose      : Count online, writable user databases on the SQL Server
               instance, excluding DBA databases and AG secondaries.

Interval     : 1h
History      : 365d
Trends       : 730d
Type         : Numeric (unsigned)
Compatibility: SQL Server 2012+

AG Handling  : Include standalone and local AG primary databases.
               Exclude local AG secondary databases.

Notes        : Excludes databases beginning with DBA.
               Excludes read-only databases and snapshots.
               Returns a single integer.
===============================================================================
*/

SET NOCOUNT ON;

------------------------------------------------------------
-- Count user databases
------------------------------------------------------------

SELECT
    COUNT(*) AS DatabaseCount
FROM sys.databases AS db
WHERE db.database_id > 4
  AND db.name NOT LIKE 'DBA%'
  AND db.state = 0
  AND db.is_read_only = 0
  AND db.source_database_id IS NULL

  AND
  (
      -- Standalone databases
      NOT EXISTS
      (
          SELECT 1
          FROM sys.availability_databases_cluster AS adc
          WHERE adc.database_name = db.name
      )

      OR

      -- AG databases where this instance is PRIMARY
      EXISTS
      (
          SELECT 1
          FROM sys.dm_hadr_database_replica_states AS drs
          WHERE drs.database_id = db.database_id
            AND drs.is_local = 1
            AND drs.is_primary_replica = 1
      )
  );
