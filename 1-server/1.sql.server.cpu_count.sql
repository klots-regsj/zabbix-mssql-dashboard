
/*
===============================================================================
ZABBIX SQL SERVER MONITORING - VERSION 1.0
===============================================================================
Name         : 1.sql.server.cpu_count
Purpose      : Return the number of logical CPUs visible
               to the SQL Server instance.

ODBC Key     : db.odbc.select[1.sql.server.cpu_count,,"Driver={$MSSQL.ODBC.DRIVER};Server={$MSSQL.HOST};Port={$MSSQL.PORT};UID={$MSSQL.USER};PWD={$MSSQL.PASSWORD};Encrypt={$MSSQL.ENCRYPT}"]

Interval     : 24h
History      : 730d
Trends       : 1825d
Type         : Numeric (unsigned)
Compatibility: SQL Server 2012+

AG Handling  : Not applicable. Instance-level metric.

Notes        : Uses sys.dm_os_sys_info.
               Returns the number of logical CPUs visible
               to SQL Server.
               Includes logical processors from Hyper-Threading.
               May reflect VM or operating system CPU limits.
               Does not represent physical core count.
               Returns one integer.
===============================================================================
*/

SET NOCOUNT ON;

SELECT
    cpu_count AS cpu_count
FROM sys.dm_os_sys_info;
