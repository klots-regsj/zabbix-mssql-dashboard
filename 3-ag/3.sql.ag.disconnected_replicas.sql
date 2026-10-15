
/*
===============================================================================
ZABBIX SQL SERVER MONITORING - VERSION 1.0
===============================================================================
Name         : 3.sql.ag.disconnected_replicas
Purpose      : Count disconnected secondary replicas in
               Availability Groups hosted by the local primary.

ODBC Key     : db.odbc.select[3.sql.ag.disconnected_replicas,,"Driver={$MSSQL.ODBC.DRIVER};Server={$MSSQL.HOST};Port={$MSSQL.PORT};UID={$MSSQL.USER};PWD={$MSSQL.PASSWORD};Encrypt={$MSSQL.ENCRYPT}"]

Interval     : 5m
History      : 90d
Trends       : 365d
Type         : Numeric (unsigned)
Units        : None
Compatibility: SQL Server 2012+

AG Handling  : Evaluates AGs where the local replica is PRIMARY.
               Counts disconnected remote secondary replicas.
               Includes synchronous and asynchronous AGs.
               Returns 0 on standalone and secondary-only nodes.

Notes        : Uses sys.availability_replicas and
               sys.dm_hadr_availability_replica_states.
               Missing remote state is treated as disconnected.
               Requires appropriate HADR DMV permissions.
               Returns one integer value.
===============================================================================
*/

SET NOCOUNT ON;

------------------------------------------------------------
-- Count disconnected secondary replicas
-- for locally primary Availability Groups
------------------------------------------------------------

SELECT
    COUNT(*) AS disconnected_replicas
FROM sys.dm_hadr_availability_replica_states AS local_ars

INNER JOIN sys.availability_replicas AS remote_ar
    ON remote_ar.group_id = local_ars.group_id
   AND remote_ar.replica_id <> local_ars.replica_id

LEFT JOIN sys.dm_hadr_availability_replica_states AS remote_ars
    ON remote_ars.group_id = remote_ar.group_id
   AND remote_ars.replica_id = remote_ar.replica_id

WHERE local_ars.is_local = 1
  AND local_ars.role = 1

  AND
  (
      remote_ars.connected_state_desc = N'DISCONNECTED'
      OR remote_ars.connected_state_desc IS NULL
  );
