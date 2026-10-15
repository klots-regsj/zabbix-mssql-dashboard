
/*
Name          : 1.sql.server.cost_threshold_parallelism
Purpose       : Returns the configured Cost Threshold for Parallelism.
ODBC Key      : db.odbc.select[1.sql.server.cost_threshold_parallelism,,"Driver={$MSSQL.ODBC.DRIVER};Server={$MSSQL.HOST};Port={$MSSQL.PORT};UID={$MSSQL.USER};PWD={$MSSQL.PASSWORD};Encrypt={$MSSQL.ENCRYPT}"]
Interval      : 24h
History       : 730d
Trends        : 1825d
Type          : Numeric (unsigned)
Compatibility : SQL Server 2012+
AG Handling   : Instance-level setting; AG role is irrelevant.
Notes         : Returns the active configuration (value_in_use).
                The SQL Server default is 5.
                This metric is intended for configuration
                inventory and housekeeping, not performance
                monitoring.
*/

SET NOCOUNT ON;

SELECT
    CAST(value_in_use AS int) AS cost_threshold_parallelism
FROM sys.configurations
WHERE name = N'cost threshold for parallelism';
