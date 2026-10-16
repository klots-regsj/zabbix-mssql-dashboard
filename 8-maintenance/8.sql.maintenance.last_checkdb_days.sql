
/*
===============================================================================
ZABBIX SQL SERVER MONITORING - VERSION 1.0
===============================================================================
Name         : 8.sql.maintenance.last_checkdb_days
Purpose      : Days since the latest successful DBCC CHECKDB.

ODBC Key     : db.odbc.select[8.sql.maintenance.last_checkdb_days,,"Driver={$MSSQL.ODBC.DRIVER};Server={$MSSQL.HOST};Port={$MSSQL.PORT};UID={$MSSQL.USER};PWD={$MSSQL.PASSWORD};Encrypt={$MSSQL.ENCRYPT}"]

Interval     : 24h
History      : 730d
Trends       : 1815d
Type         : Numeric (float)
Compatibility: SQL Server 2012+

AG Handling  : Instance-level maintenance history.

Notes        : Reads master.dbo.CommandLog.
               Returns days since latest successful CHECKDB.
               Returns -1 if no successful run is recorded.
               Read-only.
===============================================================================
*/

SET NOCOUNT ON;

SELECT
    COALESCE
    (
        CONVERT
        (
            decimal(12,2),
            DATEDIFF
            (
                MINUTE,
                MAX(EndTime),
                GETDATE()
            ) / 1440.0
        ),
        CONVERT(decimal(12,2), -1)
    ) AS last_checkdb_days
FROM master.dbo.CommandLog
WHERE CommandType = N'DBCC_CHECKDB'
  AND ErrorNumber = 0
  AND EndTime IS NOT NULL;
