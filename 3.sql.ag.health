
/*
===============================================================================
ZABBIX SQL SERVER MONITORING - VERSION 1.0
===============================================================================
Name         : 3.sql.ag.health
Purpose      : Return the worst synchronization health
               status across local Availability Groups.

ODBC Key     : db.odbc.select[3.sql.ag.health,,"Driver={$MSSQL.ODBC.DRIVER};Server={$MSSQL.HOST};Port={$MSSQL.PORT};UID={$MSSQL.USER};PWD={$MSSQL.PASSWORD};Encrypt={$MSSQL.ENCRYPT}"]

Interval     : 5m
History      : 90d
Trends       : 365d
Type         : Numeric (unsigned)
Compatibility: SQL Server 2012+

AG Handling  : Evaluates all Availability Groups associated
               with the local SQL Server instance.

Values       : 0 = No local Availability Groups
               1 = Healthy
               2 = Partially healthy
               3 = Unhealthy or unknown

Notes        : Uses sys.dm_hadr_availability_group_states.
               Evaluates synchronization health.
               Reports the worst status across local AGs.
               Does not modify Availability Groups.
               Requires appropriate server permissions.
               Returns one integer.
===============================================================================
*/

SET NOCOUNT ON;

------------------------------------------------------------
-- Evaluate local Availability Group health
------------------------------------------------------------

SELECT
    CAST
    (
        CASE
            WHEN COUNT(*) = 0 THEN 0

            WHEN SUM
            (
                CASE
                    WHEN ags.synchronization_health = 0
                      OR ags.synchronization_health IS NULL
                    THEN 1
                    ELSE 0
                END
            ) > 0 THEN 3

            WHEN SUM
            (
                CASE
                    WHEN ags.synchronization_health = 1
                    THEN 1
                    ELSE 0
                END
            ) > 0 THEN 2

            ELSE 1
        END
        AS int
    ) AS ag_health
FROM sys.dm_hadr_availability_group_states AS ags
INNER JOIN sys.availability_groups AS ag
    ON ag.group_id = ags.group_id;
