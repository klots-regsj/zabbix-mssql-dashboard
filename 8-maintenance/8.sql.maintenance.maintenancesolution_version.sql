
/*
===============================================================================
ZABBIX SQL SERVER MONITORING - VERSION 1.0
===============================================================================
Name         : 8.sql.maintenance.maintenancesolution_version
Purpose      : Return the MaintenanceSolution version date
               from the IndexOptimize procedure header.

ODBC Key     : db.odbc.select[8.sql.maintenance.maintenancesolution_version,,"Driver={$MSSQL.ODBC.DRIVER};Server={$MSSQL.HOST};Port={$MSSQL.PORT};UID={$MSSQL.USER};PWD={$MSSQL.PASSWORD};Encrypt={$MSSQL.ENCRYPT}"]

Interval     : 24h
History      : 730d
Trends       : 1815d
Type         : Numeric (unsigned)
Compatibility: SQL Server 2012+

AG Handling  : Instance-level check.
               Independent of AG replica role.

Notes        : Reads the Version field from the
               dbo.IndexOptimize procedure definition.

               Returns YYYYMMDD as an integer.
               Returns 0 if no valid version is found.

               Requires VIEW DEFINITION permission.
               Does not execute maintenance procedures.
               Read-only.
===============================================================================
*/

SET NOCOUNT ON;

DECLARE @Version int = 0;
DECLARE @Database sysname;
DECLARE @SQL nvarchar(max);

------------------------------------------------------------
-- Search online databases
------------------------------------------------------------

DECLARE DatabaseCursor CURSOR LOCAL FAST_FORWARD FOR

SELECT d.name
FROM sys.databases AS d
WHERE d.state_desc = N'ONLINE'
  AND d.source_database_id IS NULL
ORDER BY
    CASE
        WHEN d.name = N'master' THEN 0
        WHEN d.name = N'DBA' THEN 1
        ELSE 2
    END,
    d.name;

OPEN DatabaseCursor;

FETCH NEXT FROM DatabaseCursor INTO @Database;

WHILE @@FETCH_STATUS = 0
BEGIN

    SET @SQL = N'
DECLARE @Definition nvarchar(max);
DECLARE @Position int;
DECLARE @Candidate nvarchar(30);
DECLARE @Date date;

SELECT @Definition = m.definition
FROM ' + QUOTENAME(@Database) + N'.sys.procedures AS p
INNER JOIN ' + QUOTENAME(@Database) + N'.sys.schemas AS s
    ON s.schema_id = p.schema_id
INNER JOIN ' + QUOTENAME(@Database) + N'.sys.sql_modules AS m
    ON m.object_id = p.object_id
WHERE s.name = N''dbo''
  AND p.name = N''IndexOptimize'';

IF @Definition IS NOT NULL
BEGIN
    SET @Position = CHARINDEX(N''Version:'', @Definition);

    IF @Position > 0
    BEGIN
        SET @Candidate =
            LTRIM(RTRIM(SUBSTRING(
                @Definition,
                @Position + LEN(N''Version:''),
                30
            )));

        SET @Date = TRY_CONVERT(date, LEFT(@Candidate, 10), 23);

        IF @Date IS NOT NULL
        BEGIN
            SET @Result =
                CONVERT(int, CONVERT(char(8), @Date, 112));
        END;
    END;
END;
';

    BEGIN TRY

        EXEC sys.sp_executesql
            @SQL,
            N'@Result int OUTPUT',
            @Result = @Version OUTPUT;

    END TRY
    BEGIN CATCH
        -- Skip inaccessible databases.
    END CATCH;

    IF @Version > 0
        BREAK;

    FETCH NEXT FROM DatabaseCursor INTO @Database;

END;

CLOSE DatabaseCursor;
DEALLOCATE DatabaseCursor;

------------------------------------------------------------
-- Return one integer for Zabbix
------------------------------------------------------------

SELECT @Version AS maintenancesolution_version;
