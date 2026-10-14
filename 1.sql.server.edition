
/*
===============================================================================
ZABBIX SQL SERVER MONITORING - VERSION 1.0
===============================================================================
Name         : 1.sql.server.edition
Purpose      : Identify and normalize the SQL Server edition
               into a consistent label for Zabbix monitoring.

ODBC Key     : db.odbc.select[1.sql.server.edition,,"Driver={$MSSQL.ODBC.DRIVER};Server={$MSSQL.HOST};Port={$MSSQL.PORT};UID={$MSSQL.USER};PWD={$MSSQL.PASSWORD};Encrypt={$MSSQL.ENCRYPT}"]

Interval     : 24h
History      : 730d
Trends       : Not applicable
Type         : Character
Compatibility: SQL Server 2012+

AG Handling  : Not applicable. Instance-level metric.

Notes        : Uses SERVERPROPERTY('Edition').
               Returns one of the following labels:
                 ENTERPRISE_CORE
                 ENTERPRISE
                 STANDARD
                 DEVELOPER
                 EXPRESS
                 OTHER

               Enterprise Core is detected before Enterprise.
               Unrecognized editions return OTHER.
               Labels describe the SQL Server edition,
               not actual license compliance.
               Returns one character value.
===============================================================================
*/

SET NOCOUNT ON;

DECLARE @Edition nvarchar(256);

------------------------------------------------------------
-- Get SQL Server edition
------------------------------------------------------------

SELECT
    @Edition = CAST(SERVERPROPERTY('Edition') AS nvarchar(256));

------------------------------------------------------------
-- Normalize edition to a consistent label
------------------------------------------------------------

SELECT
    CASE
        WHEN @Edition LIKE N'%Enterprise%'
         AND @Edition LIKE N'%Core%'
            THEN 'ENTERPRISE_CORE'

        WHEN @Edition LIKE N'%Enterprise%'
            THEN 'ENTERPRISE'

        WHEN @Edition LIKE N'%Standard%'
            THEN 'STANDARD'

        WHEN @Edition LIKE N'%Developer%'
            THEN 'DEVELOPER'

        WHEN @Edition LIKE N'%Express%'
            THEN 'EXPRESS'

        ELSE 'OTHER'
    END AS sql_edition_label;
