
/*
Name          : 1.sql.server.remote_admin_connections
Purpose       : Returns whether remote Dedicated Administrator
                Connections (DAC) are enabled.
ODBC Key      : db.odbc.select[1.sql.server.remote_admin_connections,,"Driver={$MSSQL.ODBC.DRIVER};Server={$MSSQL.HOST};Port={$MSSQL.PORT};UID={$MSSQL.USER};PWD={$MSSQL.PASSWORD};Encrypt={$MSSQL.ENCRYPT}"]
Interval      : 24h
History       : 730d
Trends        : 1825d
Type          : Numeric (unsigned)
Compatibility : SQL Server 2012+
AG Handling   : Instance-level setting; AG role is irrelevant.
Notes         : Returns the active configuration (value_in_use).
                0 = Remote DAC disabled
                1 = Remote DAC enabled
                Does not test DAC connectivity.
                Intended for configuration inventory
                and housekeeping across SQL Server instances.
*/

SET NOCOUNT ON;

SELECT
    CAST(value_in_use AS int) AS remote_admin_connections
FROM sys.configurations
WHERE name = N'remote admin connections';
