
/*
Name          : 1.sql.server.clr_enabled
Purpose       : Returns whether SQL Server CLR Integration
                is enabled on the instance.
ODBC Key      : db.odbc.select[1.sql.server.clr_enabled,,"Driver={$MSSQL.ODBC.DRIVER};Server={$MSSQL.HOST};Port={$MSSQL.PORT};UID={$MSSQL.USER};PWD={$MSSQL.PASSWORD};Encrypt={$MSSQL.ENCRYPT}"]
Interval      : 24h
History       : 730d
Trends        : 1825d
Type          : Numeric (unsigned)
Compatibility : SQL Server 2012+
AG Handling   : Instance-level setting; AG role is irrelevant.
Notes         : Returns the active configuration (value_in_use).
                0 = Disabled
                1 = Enabled
                Does not indicate whether CLR assemblies exist
                or are actively used.
                Intended for configuration inventory and
                housekeeping across SQL Server instances.
*/

SET NOCOUNT ON;

SELECT
    CAST(value_in_use AS int) AS clr_enabled
FROM sys.configurations
WHERE name = N'clr enabled';
