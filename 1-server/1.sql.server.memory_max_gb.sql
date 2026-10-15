
/*
===============================================================================
ZABBIX SQL SERVER MONITORING - VERSION 1.1
===============================================================================
Name         : 1.sql.server.memory_max_gb
Purpose      : Return the active SQL Server maximum memory
               configuration in GB.

ODBC Key     : db.odbc.select[1.sql.server.memory_max_gb,,"Driver={$MSSQL.ODBC.DRIVER};Server={$MSSQL.HOST};Port={$MSSQL.PORT};UID={$MSSQL.USER};PWD={$MSSQL.PASSWORD};Encrypt={$MSSQL.ENCRYPT}"]

Interval     : 24h
History      : 730d
Trends       : 1825d
Type         : Numeric (float)
Units        : GB
Compatibility: SQL Server 2012+

AG Handling  : Not applicable. Instance-level metric.

Notes        : Uses sys.configurations.value_in_use.
               Explicitly converts sql_variant to bigint.
               Converts MB to GB with two decimal places.
               Returns the configured maximum memory,
               not actual SQL Server memory consumption.
               The default value of 2147483647 MB
               indicates no practical configured limit.
               Returns one decimal value.
===============================================================================
*/

SET NOCOUNT ON;

------------------------------------------------------------
-- Return active maximum server memory in GB
------------------------------------------------------------

SELECT
    CAST
    (
        CONVERT(bigint, value_in_use) / 1024.0
        AS decimal(18,2)
    ) AS memory_max_gb
FROM sys.configurations
WHERE name = N'max server memory (MB)';
