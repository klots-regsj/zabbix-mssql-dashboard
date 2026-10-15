
/*
===============================================================================
ZABBIX SQL SERVER MONITORING - VERSION 1.0
===============================================================================
Name         : 3.sql.ag.replica_role
Purpose      : Return the local Availability Group replica
               role for the SQL Server instance.

ODBC Key     : db.odbc.select[3.sql.ag.replica_role,,"Driver={$MSSQL.ODBC.DRIVER};Server={$MSSQL.HOST};Port={$MSSQL.PORT};UID={$MSSQL.USER};PWD={$MSSQL.PASSWORD};Encrypt={$MSSQL.ENCRYPT}"]

Interval     : 5m
History      : 90d
Trends       : Not applicable
Type         : Character
Compatibility: SQL Server 2012+

AG Handling  : Evaluates all local AG replicas.
               Detects instances hosting multiple AGs
               with different replica roles.

Values       : PRIMARY
               SECONDARY
               MIXED
               RESOLVING
               NOT_IN_AG

Notes        : Uses sys.dm_hadr_availability_replica_states.
               MIXED means the instance is PRIMARY for at
               least one AG and SECONDARY for another.
               RESOLVING indicates a local replica with
               unresolved role, unless MIXED applies.
               Returns one text value.
               Requires sufficient server permissions.
===============================================================================
*/

SET NOCOUNT ON;

------------------------------------------------------------
-- Determine local AG replica roles
------------------------------------------------------------

;WITH ReplicaRoles AS
(
    SELECT
        COUNT(*) AS ReplicaCount,

        SUM
        (
            CASE WHEN role = 1 THEN 1 ELSE 0 END
        ) AS PrimaryCount,

        SUM
        (
            CASE WHEN role = 2 THEN 1 ELSE 0 END
        ) AS SecondaryCount,

        SUM
        (
            CASE WHEN role = 0 OR role IS NULL
                 THEN 1 ELSE 0 END
        ) AS ResolvingCount

    FROM sys.dm_hadr_availability_replica_states
    WHERE is_local = 1
)
SELECT
    CASE
        WHEN ReplicaCount = 0
            THEN N'NOT_IN_AG'

        WHEN PrimaryCount > 0
         AND SecondaryCount > 0
            THEN N'MIXED'

        WHEN ResolvingCount > 0
            THEN N'RESOLVING'

        WHEN PrimaryCount > 0
            THEN N'PRIMARY'

        WHEN SecondaryCount > 0
            THEN N'SECONDARY'

        ELSE N'RESOLVING'
    END AS replica_role
FROM ReplicaRoles;
