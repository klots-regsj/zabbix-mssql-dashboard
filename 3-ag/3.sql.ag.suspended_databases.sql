
/*
===============================================================================
ZABBIX SQL SERVER MONITORING - VERSION 1.0
===============================================================================
Name         : 3.sql.ag.suspended_databases
Purpose      : Count local Availability Group databases where
               data movement is suspended.

ODBC Key     : db.odbc.select[3.sql.ag.suspended_databases,,"Driver={$MSSQL.ODBC.DRIVER};Server={$MSSQL.HOST};Port={$MSSQL.PORT};UID={$MSSQL.USER};PWD={$MSSQL.PASSWORD};Encrypt={$MSSQL.ENCRYPT}"]

Interval     : 5m
History      : 90d
Trends       : 365d
Type         : Numeric (unsigned)
Units        : None
Compatibility: SQL Server 2012+

AG Handling  : Includes local PRIMARY and SECONDARY AG databases.
               Excludes remote replica database states.
               Returns 0 on standalone instances.

Notes        : Uses sys.dm_hadr_database_replica_states.
               Checks is_suspended = 1.
               Counts each local suspended database once.
               Includes synchronous and asynchronous AGs.
               Requires appropriate HADR DMV permissions.
               Returns one integer value.
===============================================================================
*/

SET NOCOUNT ON;

------------------------------------------------------------
-- Count local AG databases with suspended data movement
------------------------------------------------------------

SELECT
    COUNT(*) AS suspended_databases
FROM sys.dm_hadr_database_replica_states AS drs
INNER JOIN sys.dm_hadr_availability_replica_states AS ars
    ON ars.group_id = drs.group_id
   AND ars.replica_id = drs.replica_id
WHERE drs.is_local = 1
  AND ars.is_local = 1
  AND drs.is_suspended = 1;
