
/*
===============================================================================
ZABBIX SQL SERVER MONITORING - VERSION 1.0
===============================================================================
Name         : 1.sql.server.cpu_socket_count
Purpose      : Return the number of CPU sockets reported
               by the SQL Server instance.

ODBC Key     : db.odbc.select[1.sql.server.cpu_socket_count,,"Driver={$MSSQL.ODBC.DRIVER};Server={$MSSQL.HOST};Port={$MSSQL.PORT};UID={$MSSQL.USER};PWD={$MSSQL.PASSWORD};Encrypt={$MSSQL.ENCRYPT}"]

Interval     : 24h
History      : 730d
Trends       : 1825d
Type         : Numeric (unsigned)
Compatibility: SQL Server 2012+

AG Handling  : Not applicable. Instance-level metric.

Notes        : Uses sys.dm_os_sys_info.socket_count.
               Returns the CPU socket count reported
               to SQL Server by the operating system.
               Virtual machines may report virtual sockets.
               Does not represent physical core count.
               Requires VIEW SERVER STATE on SQL Server
               2012-2019 or VIEW SERVER PERFORMANCE STATE
               on SQL Server 2022+.
               Returns one integer.
===============================================================================
*/

SET NOCOUNT ON;

------------------------------------------------------------
-- Return CPU socket count
------------------------------------------------------------

SELECT
    socket_count AS cpu_socket_count
FROM sys.dm_os_sys_info;
