
/*
===============================================================================
ZABBIX SQL SERVER MONITORING - VERSION 1.0
===============================================================================
Name         : 5.sql.performance.adhoc_cache_percent
Purpose      : Return the percentage of cached execution
               plans classified as Adhoc.

ODBC Key     : db.odbc.select[5.sql.performance.adhoc_cache_percent,,"Driver={$MSSQL.ODBC.DRIVER};Server={$MSSQL.HOST};Port={$MSSQL.PORT};UID={$MSSQL.USER};PWD={$MSSQL.PASSWORD};Encrypt={$MSSQL.ENCRYPT}"]

Interval     : 15m
History      : 180d
Trends       : 365d
Type         : Numeric (float)
Units        : %
Compatibility: SQL Server 2012+

AG Handling  : Not applicable. Instance-level metric.

Notes        : Uses sys.dm_exec_cached_plans.
               Calculates Adhoc plans as a percentage
               of all cached execution plans.
               Measures plan count, not memory consumption.
               A high percentage may indicate excessive
               single-use ad hoc execution plans.
               Does not distinguish single-use plans.
               Returns 0 when the plan cache is empty.
               Requires VIEW SERVER STATE on SQL Server
               2012-2019 or VIEW SERVER PERFORMANCE STATE
               on SQL Server 2022+.
               Returns one decimal value.
===============================================================================
*/

SET NOCOUNT ON;

------------------------------------------------------------
-- Calculate Adhoc execution plan percentage
------------------------------------------------------------

SELECT
    CAST
    (
        COALESCE
        (
            100.0 *
            COUNT_BIG
            (
                CASE
                    WHEN objtype = N'Adhoc'
                    THEN 1
                END
            )
            / NULLIF(COUNT_BIG(*), 0),
            0
        )
        AS decimal(10,2)
    ) AS adhoc_cache_percent

FROM sys.dm_exec_cached_plans;
