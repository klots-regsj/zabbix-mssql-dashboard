
/*
===============================================================================
ZABBIX SQL SERVER MONITORING - VERSION 1.2
===============================================================================
Name         : 3.sql.ag.failover_readiness
Purpose      : Report automatic failover readiness and distinguish
               asynchronous or manual failover configurations.

ODBC Key     : db.odbc.select[3.sql.ag.failover_readiness,,"Driver={$MSSQL.ODBC.DRIVER};Server={$MSSQL.HOST};Port={$MSSQL.PORT};UID={$MSSQL.USER};PWD={$MSSQL.PASSWORD};Encrypt={$MSSQL.ENCRYPT}"]

Interval     : 5m
History      : 90d
Trends       : Not applicable
Type         : Text
Compatibility: SQL Server 2012+

AG Handling  : Evaluates all local AG primary replicas.
               Reports SECONDARY if no local primary exists.

Values       : READY
               NOT_READY
               ASYNC
               MANUAL
               SECONDARY
               NOT_IN_AG
               UNKNOWN

Notes        : READY requires an eligible, connected,
               synchronized automatic failover partner.
               NOT_READY indicates an automatic failover
               configuration without a ready partner.
               ASYNC and MANUAL are configuration states,
               not necessarily failures.

               Multiple primary AGs are aggregated.
               NOT_READY takes precedence over ASYNC/MANUAL.
               Mixed configurations without a failure
               return UNKNOWN.

               READY is not a guarantee of successful failover.
===============================================================================
*/

SET NOCOUNT ON;

DECLARE @Result varchar(16) = 'NOT_IN_AG';

DECLARE @AGStatus TABLE
(
    group_id uniqueidentifier PRIMARY KEY,
    status varchar(16) NOT NULL
);

------------------------------------------------------------
-- Evaluate each locally primary AG
------------------------------------------------------------

INSERT INTO @AGStatus (group_id, status)
SELECT
    local_ars.group_id,

    CASE

        ----------------------------------------------------
        -- Automatic failover configured and ready
        ----------------------------------------------------

        WHEN EXISTS
        (
            SELECT 1
            FROM sys.availability_replicas AS local_ar
            INNER JOIN sys.availability_replicas AS remote_ar
                ON remote_ar.group_id = local_ar.group_id
               AND remote_ar.replica_id <> local_ar.replica_id
            INNER JOIN sys.dm_hadr_availability_replica_states AS remote_ars
                ON remote_ars.group_id = remote_ar.group_id
               AND remote_ars.replica_id = remote_ar.replica_id
            WHERE local_ar.replica_id = local_ars.replica_id
              AND local_ar.availability_mode_desc = N'SYNCHRONOUS_COMMIT'
              AND local_ar.failover_mode_desc = N'AUTOMATIC'
              AND remote_ar.availability_mode_desc = N'SYNCHRONOUS_COMMIT'
              AND remote_ar.failover_mode_desc = N'AUTOMATIC'
              AND remote_ars.connected_state_desc = N'CONNECTED'
              AND remote_ars.synchronization_health_desc = N'HEALTHY'

              AND EXISTS
              (
                  SELECT 1
                  FROM sys.dm_hadr_database_replica_states AS drs
                  WHERE drs.group_id = remote_ar.group_id
                    AND drs.replica_id = remote_ar.replica_id
              )

              AND NOT EXISTS
              (
                  SELECT 1
                  FROM sys.dm_hadr_database_replica_states AS drs
                  LEFT JOIN sys.dm_hadr_database_replica_cluster_states AS rcs
                      ON rcs.group_database_id = drs.group_database_id
                     AND rcs.replica_id = drs.replica_id
                  WHERE drs.group_id = remote_ar.group_id
                    AND drs.replica_id = remote_ar.replica_id
                    AND
                    (
                        drs.synchronization_state_desc <> N'SYNCHRONIZED'
                        OR drs.synchronization_state_desc IS NULL
                        OR ISNULL(rcs.is_failover_ready, 0) <> 1
                    )
              )
        )
        THEN 'READY'

        ----------------------------------------------------
        -- Automatic failover configured, but not ready
        ----------------------------------------------------

        WHEN EXISTS
        (
            SELECT 1
            FROM sys.availability_replicas AS local_ar
            INNER JOIN sys.availability_replicas AS remote_ar
                ON remote_ar.group_id = local_ar.group_id
               AND remote_ar.replica_id <> local_ar.replica_id
            WHERE local_ar.replica_id = local_ars.replica_id
              AND local_ar.availability_mode_desc = N'SYNCHRONOUS_COMMIT'
              AND local_ar.failover_mode_desc = N'AUTOMATIC'
              AND remote_ar.availability_mode_desc = N'SYNCHRONOUS_COMMIT'
              AND remote_ar.failover_mode_desc = N'AUTOMATIC'
        )
        THEN 'NOT_READY'

        ----------------------------------------------------
        -- Asynchronous primary
        ----------------------------------------------------

        WHEN EXISTS
        (
            SELECT 1
            FROM sys.availability_replicas AS ar
            WHERE ar.replica_id = local_ars.replica_id
              AND ar.availability_mode_desc = N'ASYNCHRONOUS_COMMIT'
        )
        THEN 'ASYNC'

        ----------------------------------------------------
        -- Synchronous primary without automatic failover
        ----------------------------------------------------

        WHEN EXISTS
        (
            SELECT 1
            FROM sys.availability_replicas AS ar
            WHERE ar.replica_id = local_ars.replica_id
              AND ar.availability_mode_desc = N'SYNCHRONOUS_COMMIT'
              AND ar.failover_mode_desc = N'MANUAL'
        )
        THEN 'MANUAL'

        ELSE 'UNKNOWN'

    END

FROM sys.dm_hadr_availability_replica_states AS local_ars
WHERE local_ars.is_local = 1
  AND local_ars.role_desc = N'PRIMARY';

------------------------------------------------------------
-- Aggregate local primary AG statuses
------------------------------------------------------------

IF EXISTS (SELECT 1 FROM @AGStatus)
BEGIN

    SET @Result =
        CASE
            WHEN EXISTS
            (
                SELECT 1
                FROM @AGStatus
                WHERE status = 'NOT_READY'
            )
            THEN 'NOT_READY'

            WHEN NOT EXISTS
            (
                SELECT 1
                FROM @AGStatus
                WHERE status <> 'READY'
            )
            THEN 'READY'

            WHEN NOT EXISTS
            (
                SELECT 1
                FROM @AGStatus
                WHERE status <> 'ASYNC'
            )
            THEN 'ASYNC'

            WHEN NOT EXISTS
            (
                SELECT 1
                FROM @AGStatus
                WHERE status <> 'MANUAL'
            )
            THEN 'MANUAL'

            ELSE 'UNKNOWN'
        END;

END

------------------------------------------------------------
-- Secondary or unknown local role
------------------------------------------------------------

ELSE IF EXISTS
(
    SELECT 1
    FROM sys.dm_hadr_availability_replica_states
    WHERE is_local = 1
      AND role_desc = N'SECONDARY'
)
BEGIN
    SET @Result = 'SECONDARY';
END

ELSE IF EXISTS
(
    SELECT 1
    FROM sys.availability_replicas
    WHERE replica_server_name =
          CONVERT(sysname, SERVERPROPERTY('ServerName'))
)
BEGIN
    SET @Result = 'UNKNOWN';
END;

------------------------------------------------------------
-- Return one text value
------------------------------------------------------------

SELECT
    @Result AS failover_readiness;
