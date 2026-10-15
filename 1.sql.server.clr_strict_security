
/*
Name          : 
Purpose       : Returns whether CLR Strict Security is enabled.
ODBC Key      : db.odbc.select[1.sql.server.clr_strict_security,,"Driver={$MSSQL.ODBC.DRIVER};Server={$MSSQL.HOST};Port={$MSSQL.PORT};UID={$MSSQL.USER};PWD={$MSSQL.PASSWORD};Encrypt={$MSSQL.ENCRYPT}"]
Interval      : 24h
History       : 730d
Trends        : 1825d
Type          : Numeric (unsigned)
Compatibility : SQL Server 2012+
AG Handling   : Instance-level setting; AG role is irrelevant.
Notes         : 0 = Disabled
                1 = Enabled
                2 = Not supported (SQL Server 2012-2016)
                Uses the active configuration (value_in_use).
                Intended for security configuration inventory
                and housekeeping across SQL Server instances.
*/

SET NOCOUNT ON;

DECLARE @MajorVersion int;

SET @MajorVersion =
    CAST(SERVERPROPERTY('ProductMajorVersion') AS int);

SELECT
    CAST(
        CASE
            WHEN @MajorVersion < 14 THEN 2
            WHEN c.value_in_use IS NULL THEN 2
            ELSE c.value_in_use
        END
        AS int
    ) AS clr_strict_security
FROM (SELECT 1 AS dummy) AS x
LEFT JOIN sys.configurations AS c
    ON c.name = N'clr strict security';
