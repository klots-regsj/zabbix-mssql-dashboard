
/*
===============================================================================
ZABBIX SQL SERVER MONITORING - VERSION 1.0
===============================================================================
Name         : 3.sql.ag.quorum_state
Purpose      : Return the current Windows Server Failover
               Cluster quorum state for the SQL Server instance.

ODBC Key     : db.odbc.select[3.sql.ag.quorum_state,,"Driver={$MSSQL.ODBC.DRIVER};Server={$MSSQL.HOST};Port={$MSSQL.PORT};UID={$MSSQL.USER};PWD={$MSSQL.PASSWORD};Encrypt={$MSSQL.ENCRYPT}"]

Interval     : 5m
History      : 90d
Trends       : Not applicable
Type         : Character
Compatibility: SQL Server 2012+

AG Handling  : Reads local WSFC cluster information.
               Does not require a local primary replica.

Values       : OK
               FORCED
               UNKNOWN
               NO_CLUSTER

Notes        : Uses sys.dm_hadr_cluster.
               OK indicates normal quorum operation.
               FORCED indicates forced quorum.
               UNKNOWN indicates an unrecognized or NULL
               quorum state returned by the cluster.
               NO_CLUSTER indicates no cluster row returned.
               Requires sufficient server permissions.
               Returns one text value.
===============================================================================
*/

SET NOCOUNT ON;

------------------------------------------------------------
-- Return current WSFC quorum state
------------------------------------------------------------

SELECT
    COALESCE
    (
        (
            SELECT TOP (1)
                CASE
                    WHEN quorum_state_desc IN
                    (
                        N'NORMAL',
                        N'NORMAL_QUORUM'
                    )
                        THEN N'OK'

                    WHEN quorum_state_desc = N'FORCED_QUORUM'
                        THEN N'FORCED'

                    ELSE N'UNKNOWN'
                END
            FROM sys.dm_hadr_cluster
        ),
        N'NO_CLUSTER'
    ) AS quorum_state;
