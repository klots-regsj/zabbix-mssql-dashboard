
/*
Name          : 1.sql.server.xp_cmdshell_enabled
Purpose       : Returns whether xp_cmdshell is enabled
                on the SQL Server instance.
ODBC Key      : db.odbc.select[1.sql.server.xp_cmdshell_enabled,,"Driver={$MSSQL.ODBC.DRIVER};Server={$MSSQL.HOST};Port={$MSSQL.PORT};UID={$MSSQL.USER};PWD={$MSSQL.PASSWORD};Encrypt={$MSSQL.ENCRYPT}"]
Interval      : 24h
History       : 730d
Trends        : 1825d
Type          : Numeric (unsigned)
Compatibility : SQL Server 2012+
AG Handling   : Instance-level setting; AG role is irrelevant.
Notes         : Returns the active configuration (value_in_use).
                0 = Disabled
                1 = Enabled
                Intended for security configuration inventory
                and housekeeping across SQL Server instances.
                Does not execute xp_cmdshell.
*/

SET NOCOUNT ON;

SELECT
    CAST(value_in_use AS int) AS xp_cmdshell_enabled
FROM sys.configurations
WHERE name = N'xp_cmdshell';
