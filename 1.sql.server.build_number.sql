
/*
===============================================================================
ZABBIX SQL SERVER MONITORING - VERSION 1.0
===============================================================================
Name         : 1.sql.server.build_number
Purpose      : Return the full SQL Server product build version.

ODBC Key     : db.odbc.select[1.sql.server.build_number,,"Driver={$MSSQL.ODBC.DRIVER};Server={$MSSQL.HOST};Port={$MSSQL.PORT};UID={$MSSQL.USER};PWD={$MSSQL.PASSWORD};Encrypt={$MSSQL.ENCRYPT}"]

Interval     : 24h
History      : 730d
Trends       : Not applicable
Type         : Character
Compatibility: SQL Server 2012+

AG Handling  : Not applicable. Instance-level metric.

Notes        : Uses SERVERPROPERTY('ProductVersion').
               Returns the complete four-part SQL Server
               build version, for example 16.0.1000.6.
               Does not indicate whether the installed
               build is the latest available update.
               Returns one character value.
===============================================================================
*/

SET NOCOUNT ON;

SELECT
    CAST(SERVERPROPERTY('ProductVersion') AS varchar(50))
        AS build_number;
