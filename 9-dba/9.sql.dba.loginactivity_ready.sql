
/*
===============================================================================
ZABBIX SQL SERVER MONITORING - VERSION 1.0
===============================================================================
Name         : 9.sql.dba.loginactivity_ready
Purpose      : Verify that the LoginActivity collector job
               and the DBA.dbo.LoginActivity table exist.

ODBC Key     : db.odbc.select[9.sql.dba.loginactivity_ready,,"Driver={$MSSQL.ODBC.DRIVER};Server={$MSSQL.HOST};Port={$MSSQL.PORT};UID={$MSSQL.USER};PWD={$MSSQL.PASSWORD};Encrypt={$MSSQL.ENCRYPT}"]

Interval     : 1h
History      : 365d
Trends       : 730d
Type         : Numeric (unsigned)
Compatibility: SQL Server 2012+

Notes        : Returns 1 when both the SQL Agent job and
               LoginActivity table exist.
               Returns 0 if either object is missing.
               Does not modify any objects.
               Does not verify collector execution.
               Returns one integer.
===============================================================================
*/

SET NOCOUNT ON;

DECLARE @JobExists bit = 0;
DECLARE @TableExists bit = 0;

------------------------------------------------------------
-- Check SQL Agent job
------------------------------------------------------------

IF EXISTS
(
    SELECT 1
    FROM msdb.dbo.sysjobs
    WHERE name = N'DBA - Loginactivity'
)
BEGIN
    SET @JobExists = 1;
END;

------------------------------------------------------------
-- Check DBA database and LoginActivity table
------------------------------------------------------------

IF DB_ID(N'DBA') IS NOT NULL
BEGIN

    IF EXISTS
    (
        SELECT 1
        FROM DBA.sys.tables AS t
        INNER JOIN DBA.sys.schemas AS s
            ON s.schema_id = t.schema_id
        WHERE s.name = N'dbo'
          AND t.name = N'LoginActivity'
    )
    BEGIN
        SET @TableExists = 1;
    END;

END;

------------------------------------------------------------
-- Return readiness status
------------------------------------------------------------

SELECT
    CONVERT
    (
        int,
        CASE
            WHEN @JobExists = 1
             AND @TableExists = 1
            THEN 1
            ELSE 0
        END
    ) AS loginactivity_ready;
