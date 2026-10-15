
/*
Name          : 1.sql.server.version_year
Purpose       : Returns the SQL Server release year as an integer.
ODBC Key      : db.odbc.select[1.sql.server.version_year,,"Driver={$MSSQL.ODBC.DRIVER};Server={$MSSQL.HOST};Port={$MSSQL.PORT};UID={$MSSQL.USER};PWD={$MSSQL.PASSWORD};Encrypt={$MSSQL.ENCRYPT}"]
Interval      : 24h
History       : 730d
Trends        : 1825d
Type          : Numeric (unsigned)
Compatibility : SQL Server 2012+
AG Handling   : Instance-level property; AG role is irrelevant.
Notes         : Returns the SQL Server release year.
                Returns 0 for unknown or unsupported versions.
                Intended for version inventory, lifecycle
                management and housekeeping.
*/

SET NOCOUNT ON;

SELECT
    CASE CAST(SERVERPROPERTY('ProductMajorVersion') AS int)
        WHEN 10 THEN 2008
        WHEN 11 THEN 2012
        WHEN 12 THEN 2014
        WHEN 13 THEN 2016
        WHEN 14 THEN 2017
        WHEN 15 THEN 2019
        WHEN 16 THEN 2022
        WHEN 17 THEN 2025
        ELSE 0
    END AS version_year;
