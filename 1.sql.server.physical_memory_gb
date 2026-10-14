
/*
===============================================================================
ZABBIX SQL SERVER MONITORING - VERSION 1.0
===============================================================================
Name         : 1.sql.server.physical_memory_gb
Purpose      : Return the total physical memory visible
               to SQL Server in GB.

ODBC Key     : db.odbc.select[1.sql.server.physical_memory_gb,,"Driver={$MSSQL.ODBC.DRIVER};Server={$MSSQL.HOST};Port={$MSSQL.PORT};UID={$MSSQL.USER};PWD={$MSSQL.PASSWORD};Encrypt={$MSSQL.ENCRYPT}"]

Interval     : 24h
History      : 730d
Trends       : 1825d
Type         : Numeric (float)
Units        : GB
Compatibility: SQL Server 2012+

AG Handling  : Not applicable. Instance-level metric.

Notes        : Uses sys.dm_os_sys_info.physical_memory_kb.
               Converts KB to GB using decimal division.
               Returns total physical memory reported
               by the operating system.
               On virtual machines, this normally reflects
               the memory assigned to the VM.
               Does not measure available or used memory.
               Requires VIEW SERVER STATE on SQL Server
               2012-2019 or VIEW SERVER PERFORMANCE STATE
               on SQL Server 2022+.
               Returns one decimal value.
===============================================================================
*/

SET NOCOUNT ON;

------------------------------------------------------------
-- Return total physical memory in GB
------------------------------------------------------------

SELECT
    CAST
    (
        physical_memory_kb / 1048576.0
        AS decimal(18,2)
    ) AS physical_memory_gb
FROM sys.dm_os_sys_info;
