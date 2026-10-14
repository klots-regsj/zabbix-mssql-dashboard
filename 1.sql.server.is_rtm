
/*
===============================================================================
ZABBIX SQL SERVER MONITORING - VERSION 1.0
===============================================================================
Name         : 1.sql.server.is_rtm
Purpose      : Identify SQL Server instances running their
               original RTM build without subsequent updates.

ODBC Key     : db.odbc.select[1.sql.server.is_rtm,,"Driver={$MSSQL.ODBC.DRIVER};Server={$MSSQL.HOST};Port={$MSSQL.PORT};UID={$MSSQL.USER};PWD={$MSSQL.PASSWORD};Encrypt={$MSSQL.ENCRYPT}"]

Interval     : 24h
History      : 730d
Trends       : 1825d
Type         : Numeric (unsigned)
Compatibility: SQL Server 2012+

AG Handling  : Not applicable. Instance-level metric.

Notes        : Returns:
                 1 = Exact original RTM build
                 0 = Different build (updated or unsupported)

               Compares the complete four-part product version.
               Does not determine whether SQL Server has the
               latest available security updates or CU.
               Unknown versions return 0.
               Returns one integer.
===============================================================================
*/

SET NOCOUNT ON;

DECLARE @ProductVersion varchar(50);
DECLARE @Major int;
DECLARE @IsRTM int = 0;

------------------------------------------------------------
-- Get SQL Server product version
------------------------------------------------------------

SELECT
    @ProductVersion =
        CAST(SERVERPROPERTY('ProductVersion') AS varchar(50));

SET @Major = CAST(PARSENAME(@ProductVersion, 4) AS int);

------------------------------------------------------------
-- Compare against original RTM builds
------------------------------------------------------------

SELECT
    @IsRTM =
        CASE
            -- SQL Server 2012
            WHEN @Major = 11
             AND @ProductVersion = '11.0.2100.60'
                THEN 1

            -- SQL Server 2014
            WHEN @Major = 12
             AND @ProductVersion = '12.0.2000.8'
                THEN 1

            -- SQL Server 2016
            WHEN @Major = 13
             AND @ProductVersion = '13.0.1601.5'
                THEN 1

            -- SQL Server 2017
            WHEN @Major = 14
             AND @ProductVersion = '14.0.1000.169'
                THEN 1

            -- SQL Server 2019
            WHEN @Major = 15
             AND @ProductVersion = '15.0.2000.5'
                THEN 1

            -- SQL Server 2022
            WHEN @Major = 16
             AND @ProductVersion = '16.0.1000.6'
                THEN 1

            -- SQL Server 2025
            WHEN @Major = 17
             AND @ProductVersion = '17.0.1000.7'
                THEN 1

            ELSE 0
        END;

------------------------------------------------------------
-- Return result to Zabbix
------------------------------------------------------------

SELECT
    @IsRTM AS is_rtm;
