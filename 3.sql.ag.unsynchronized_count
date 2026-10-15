
/*
===============================================================================
ZABBIX SQL SERVER MONITORING - VERSION 1.0
===============================================================================
Name         : 3.sql.ag.unsynchronized_count
Purpose      : Count local Availability Group databases with
               an unhealthy synchronization state.

ODBC Key     : db.odbc.select[3.sql.ag.unsynchronized_count,,"Driver={$MSSQL.ODBC.DRIVER};Server={$MSSQL.HOST};Port={$MSSQL.PORT};UID={$MSSQL.USER};PWD={$MSSQL.PASSWORD};Encrypt={$MSSQL.ENCRYPT}"]

Interval     : 5m
History      : 90d
Trends       : 365d
Type         : Numeric (unsigned)
Units        : None
Compatibility: SQL Server 2012+

AG Handling  : Evaluates local PRIMARY and SECONDARY databases.
               Uses local replica availability mode.
               SYNCHRONIZING is acceptable for asynchronous
               commit replicas.
               SYNCHRONIZED is expected for synchronous
               commit replicas.

Notes        : Uses sys.dm_hadr_database_replica_states,
               sys.dm_hadr_availability_replica_states
               and sys.availability_replicas.

               Counts databases with unexpected synchronization
               states, including NULL or NOT SYNCHRONIZING.

               Suspended databases are monitored separately.
               Returns 0 for standalone instances.
               Requires appropriate HADR DMV permissions.
               Returns one integer value.
===============================================================================
*/

SET NOCOUNT ON;

------------------------------------------------------------
-- Count local databases with unexpected synchronization
-- states, taking availability mode into account
------------------------------------------------------------

SELECT
    COUNT(*) AS unsynchronized_count
FROM sys.dm_hadr_database_replica_states AS drs

INNER JOIN sys.dm_hadr_availability_replica_states AS ars
    ON ars.group_id = drs.group_id
   AND ars.replica_id = drs.replica_id

INNER JOIN sys.availability_replicas AS ar
    ON ar.group_id = ars.group_id
   AND ar.replica_id = ars.replica_id

WHERE drs.is_local = 1
  AND ars.is_local = 1

  AND
  (
      --------------------------------------------------------
      -- Synchronous commit: expect SYNCHRONIZED
      --------------------------------------------------------

      (
          ar.availability_mode_desc = N'SYNCHRONOUS_COMMIT'
          AND
          (
              drs.synchronization_state_desc IS NULL
              OR drs.synchronization_state_desc
                    <> N'SYNCHRONIZED'
          )
      )

      OR

      --------------------------------------------------------
      -- Asynchronous commit: SYNCHRONIZING is normal
      --------------------------------------------------------

      (
          ar.availability_mode_desc = N'ASYNCHRONOUS_COMMIT'
          AND
          (
              drs.synchronization_state_desc IS NULL
              OR drs.synchronization_state_desc NOT IN
                 (
                     N'SYNCHRONIZING',
                     N'SYNCHRONIZED'
                 )
          )
      )

      OR

      --------------------------------------------------------
      -- Unexpected availability mode
      --------------------------------------------------------

      (
          ar.availability_mode_desc IS NULL
          OR ar.availability_mode_desc NOT IN
             (
                 N'SYNCHRONOUS_COMMIT',
                 N'ASYNCHRONOUS_COMMIT'
             )
      )
  );
