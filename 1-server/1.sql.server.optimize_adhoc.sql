
/*
Name          : 1.sql.server.optimize_adhoc
Purpose       : Returns whether Optimize for Ad Hoc Workloads is enabled.
ODBC Key      : db.odbc.select[1.sql.server.optimize_adhoc,,"Driver={$MSSQL.ODBC.DRIVER};Server={$MSSQL.HOST};Port={$MSSQL.PORT};UID={$MSSQL.USER};PWD={$MSSQL.PASSWORD};Encrypt={$MSSQL.ENCRYPT}"]
Interval      : 24h
History       : 730d
Trends        : 1825d
Type          : Numeric (unsigned)
Compatibility : SQL Server 2012+
AG Handling   : Instance-level setting; AG role is irrelevant.
Notes         : Returns the active configuration (value_in_use).
                0 = Disabled
                1 = Enabled
                Intended for configuration inventory and
                housekeeping across SQL Server instances.
*/

SET NOCOUNT ON;

SELECT
    CAST(value_in_use AS int) AS optimize_adhoc
FROM sys.configurations
WHERE name = N'optimize for ad hoc workloads';
