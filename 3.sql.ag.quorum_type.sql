
/*
===============================================================================
ZABBIX SQL SERVER MONITORING - VERSION 1.0
===============================================================================
Name         : 3.sql.ag.quorum_type
Purpose      : Return the Windows Server Failover Cluster
               quorum configuration used by the local
               SQL Server instance.

ODBC Key     : db.odbc.select[3.sql.ag.quorum_type,,"Driver={$MSSQL.ODBC.DRIVER};Server={$MSSQL.HOST};Port={$MSSQL.PORT};UID={$MSSQL.USER};PWD={$MSSQL.PASSWORD};Encrypt={$MSSQL.ENCRYPT}"]

Interval     : 5m
History      : 90d
Trends       : Not applicable
Type         : Character
Compatibility: SQL Server 2012+

AG Handling  : Reads local WSFC cluster information.
               Does not require a local primary replica.

Values       : NODE
               NODE+DISK
               NODE+FS
               NODE+CLOUD
               DISK
               UNKNOWN
               NO_CLUSTER

Notes        : Uses sys.dm_hadr_cluster.
               Returns NO_CLUSTER when no WSFC cluster
               information is available.
               Returns UNKNOWN for unrecognized quorum types.
               Requires appropriate server permissions.
               Returns one text value.
===============================================================================
*/

SET NOCOUNT ON;

------------------------------------------------------------
-- Return local WSFC quorum configuration
------------------------------------------------------------

SELECT
    COALESCE
    (
        (
            SELECT TOP (1)
                CASE quorum_type_desc
                    WHEN N'NODE_MAJORITY'
                        THEN N'NODE'

                    WHEN N'NODE_AND_DISK_MAJORITY'
                        THEN N'NODE+DISK'

                    WHEN N'NODE_AND_FILE_SHARE_MAJORITY'
                        THEN N'NODE+FS'

                    WHEN N'NODE_AND_CLOUD_MAJORITY'
                        THEN N'NODE+CLOUD'

                    WHEN N'DISK_ONLY'
                        THEN N'DISK'

                    ELSE N'UNKNOWN'
                END
            FROM sys.dm_hadr_cluster
        ),
        N'NO_CLUSTER'
    ) AS quorum_type;
