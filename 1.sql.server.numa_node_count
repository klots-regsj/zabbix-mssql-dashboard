
/*
===============================================================================
ZABBIX SQL SERVER MONITORING - VERSION 1.0
===============================================================================
Name         : 1.sql.server.numa_node_count
Purpose      : Return the number of NUMA nodes reported
               by the SQL Server instance.

ODBC Key     : db.odbc.select[1.sql.server.numa_node_count,,"Driver={$MSSQL.ODBC.DRIVER};Server={$MSSQL.HOST};Port={$MSSQL.PORT};UID={$MSSQL.USER};PWD={$MSSQL.PASSWORD};Encrypt={$MSSQL.ENCRYPT}"]

Interval     : 24h
History      : 730d
Trends       : 1825d
Type         : Numeric (unsigned)
Compatibility: SQL Server 2012+

AG Handling  : Not applicable. Instance-level metric.

Notes        : Uses sys.dm_os_sys_info.
               Returns the number of NUMA nodes visible
               to SQL Server.
               May include hardware or soft-NUMA nodes.
               Virtualization can affect NUMA topology.
               Requires VIEW SERVER STATE on SQL Server
               2012-2019 or VIEW SERVER PERFORMANCE STATE
               on SQL Server 2022+.
               Returns one integer.
===============================================================================
*/

SET NOCOUNT ON;

------------------------------------------------------------
-- Return NUMA node count
------------------------------------------------------------

SELECT
    numa_node_count AS numa_node_count
FROM sys.dm_os_sys_info;
