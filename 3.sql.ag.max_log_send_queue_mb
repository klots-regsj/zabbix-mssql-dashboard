
/*
===============================================================================
ZABBIX SQL SERVER MONITORING - VERSION 1.0
===============================================================================
Name         : 3.sql.ag.max_log_send_queue_mb
Purpose      : Return the largest AG log send queue in MB
               across secondary database replicas.

ODBC Key     : db.odbc.select[3.sql.ag.max_log_send_queue_mb,,"Driver={$MSSQL.ODBC.DRIVER};Server={$MSSQL.HOST};Port={$MSSQL.PORT};UID={$MSSQL.USER};PWD={$MSSQL.PASSWORD};Encrypt={$MSSQL.ENCRYPT}"]

Interval     : 5m
History      : 90d
Trends       : 365d
Type         : Numeric (float)
Units        : MB
Compatibility: SQL Server 2012+

AG Handling  : Evaluates locally PRIMARY Availability Groups.
               Includes remote SECONDARY database replicas.
               Supports synchronous and asynchronous AGs.
               Returns 0 when no qualifying queue exists.

Notes        : Uses log_send_queue_size from
               sys.dm_hadr_database_replica_states.
               SQL Server reports queue size in KB.
               Converts KB to MB using 1024.
               Returns the largest individual database queue,
               not the sum of all queues.
               Missing replica state is not treated as zero
               health; monitor disconnected_replicas separately.
===============================================================================
*/

SET NOCOUNT ON;

------------------------------------------------------------
-- Find the largest log send queue for local primary AGs
------------------------------------------------------------

SELECT
    CONVERT
    (
        float,
        ISNULL(MAX(CONVERT(bigint, drs.log_send_queue_size)), 0)
    ) / 1024.0 AS max_log_send_queue_mb

FROM sys.dm_hadr_availability_replica_states AS local_ars

INNER JOIN sys.dm_hadr_database_replica_states AS drs
    ON drs.group_id = local_ars.group_id
   AND drs.replica_id <> local_ars.replica_id

WHERE local_ars.is_local = 1
  AND local_ars.role = 1
  AND drs.is_local = 0;
