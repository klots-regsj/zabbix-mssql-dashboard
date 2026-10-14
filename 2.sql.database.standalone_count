
/*
===============================================================================
ZABBIX SQL SERVER MONITORING - VERSION 1.0
===============================================================================
Name         : 2.sql.database.standalone_count
Purpose      : Count online standalone user databases not belonging
               to an Always On Availability Group.

ODBC Key     : db.odbc.select[2.sql.database.standalone_count,,"Driver={$MSSQL.ODBC.DRIVER};Server={$MSSQL.HOST};Port={$MSSQL.PORT};UID={$MSSQL.USER};PWD={$MSSQL.PASSWORD};Encrypt={$MSSQL.ENCRYPT}"]

Interval     : 1h
History      : 365d
Trends       : 730d
Type         : Numeric (unsigned)
Compatibility: SQL Server 2012+

AG Handling  : Exclude databases belonging to Availability Groups.

Notes        : Excludes system databases, DBA% databases,
               snapshots and offline databases.
               Includes read-only and writable databases.
               Returns one integer.
===============================================================================
*/

SET NOCOUNT ON;

------------------------------------------------------------
-- Count standalone user databases
--
-- Include:
--   * Online user databases
--   * Standalone databases
--   * Read-only and writable databases
--
-- Exclude:
--   * System databases
--   * DBA% databases
--   * Database snapshots
--   * Offline databases
--   * AG databases
------------------------------------------------------------

SELECT
    COUNT(*) AS DatabaseCount
FROM sys.databases AS db
WHERE db.database_id > 4
  AND db.name NOT LIKE 'DBA%'
  AND db.state = 0
  AND db.source_database_id IS NULL
  AND db.replica_id IS NULL;
