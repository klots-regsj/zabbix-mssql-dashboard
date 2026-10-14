
/*
===============================================================================
ZABBIX SQL SERVER MONITORING - VERSION 1.0
===============================================================================
Name         : 1.sql.server.uptime_days
Purpose      : Return the number of days since the SQL Server
               instance was last started.

ODBC Key     : db.odbc.select[1.sql.server.uptime_days,,"Driver={$MSSQL.ODBC.DRIVER};Server={$MSSQL.HOST};Port={$MSSQL.PORT};UID={$MSSQL.USER};PWD={$MSSQL.PASSWORD};Encrypt={$MSSQL.ENCRYPT}"]

Interval     : 24h
History      : 730d
Trends       : 1825d
Type         : Numeric (unsigned)
Units        : d
Compatibility: SQL Server 2012+

AG Handling  : Not applicable. Instance-level metric.

Notes        : Uses sys.dm_os_sys_info.
               Returns one integer.
               Counts complete 24-hour periods since startup.
===============================================================================
*/

SET NOCOUNT ON;

SELECT
    DATEDIFF
    (
        SECOND,
        sqlserver_start_time,
        GETDATE()
    ) / 86400 AS uptime_days
FROM sys.dm_os_sys_info;
