
/*
===============================================================================
ZABBIX SQL SERVER MONITORING - VERSION 1.0
===============================================================================
Name         : 1.sql.server.maxdop
Purpose      : Return the active instance-level MAXDOP
               (Max Degree of Parallelism) configuration.

ODBC Key     : db.odbc.select[1.sql.server.maxdop,,"Driver={$MSSQL.ODBC.DRIVER};Server=tcp:{$MSSQL.HOST},{$MSSQL.PORT};UID={$MSSQL.USER};PWD={$MSSQL.PASSWORD};Encrypt={$MSSQL.ENCRYPT}"]

Interval     : 24h
History      : 730d
Trends       : 1825d
Type         : Numeric (unsigned)
Compatibility: SQL Server 2012+

AG Handling  : Not applicable. Instance-level metric.

Notes        : Uses sys.configurations.value_in_use.
               Returns the active instance-level MAXDOP value.
               0 = SQL Server determines the parallelism limit
                   based on available logical processors.
               1 = Parallel execution is disabled for queries
                   governed by this setting.
               2+ = Maximum degree of parallelism.
               Database-scoped configurations, query hints and
               workload-specific overrides may take precedence.
               Returns one integer.
===============================================================================
*/

SET NOCOUNT ON;

SELECT
    CAST(value_in_use AS int) AS maxdop
FROM sys.configurations
WHERE name = N'max degree of parallelism';
