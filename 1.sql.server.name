
/*
===============================================================================
ZABBIX SQL SERVER MONITORING - VERSION 1.0
===============================================================================
Name         : 1.sql.server.name
Purpose      : Return the registered SQL Server instance name.

ODBC Key     : db.odbc.select[1.sql.server.name,,"Driver={$MSSQL.ODBC.DRIVER};Server={$MSSQL.HOST};Port={$MSSQL.PORT};UID={$MSSQL.USER};PWD={$MSSQL.PASSWORD};Encrypt={$MSSQL.ENCRYPT}"]

Interval     : 24h
History      : 730d
Trends       : Not applicable
Type         : Character
Compatibility: SQL Server 2012+

AG Handling  : Not applicable. Instance-level metric.

Notes        : Uses @@SERVERNAME.
               Returns the registered local SQL Server name.
               For named instances, includes the instance name.
               The value may differ from the current hostname
               if the server has been renamed without updating
               SQL Server metadata.
               Returns one character value.
===============================================================================
*/

SET NOCOUNT ON;

SELECT
    @@SERVERNAME AS server_name;
