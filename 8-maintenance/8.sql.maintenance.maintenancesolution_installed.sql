
/*
===============================================================================
ZABBIX SQL SERVER MONITORING - VERSION 1.0
===============================================================================
Name         : 8.sql.maintenance.maintenancesolution_installed
Purpose      : Check whether MaintenanceSolution is installed
               on the SQL Server instance.

ODBC Key     : db.odbc.select[8.sql.maintenance.maintenancesolution_installed,,"Driver={$MSSQL.ODBC.DRIVER};Server={$MSSQL.HOST};Port={$MSSQL.PORT};UID={$MSSQL.USER};PWD={$MSSQL.PASSWORD};Encrypt={$MSSQL.ENCRYPT}"]

Interval     : 24h
History      : 730d
Trends       : 1825d
Type         : Numeric (unsigned)
Compatibility: SQL Server 2012+

AG Handling  : Instance-level check.
               Independent of AG replica role.

Notes        : Checks for the following stored procedures:
                 - dbo.DatabaseBackup
                 - dbo.IndexOptimize
                 - dbo.DatabaseIntegrityCheck

               All three procedures must exist together
               in at least one accessible online database.

               Returns 1 = MaintenanceSolution installed.
               Returns 0 = Not found or incomplete.

               Does not check SQL Agent jobs.
               Does not execute maintenance procedures.
               Read-only.
===============================================================================
*/

SET NOCOUNT ON;

DECLARE @Installed int = 0;
DECLARE @Database sysname;
DECLARE @SQL nvarchar(max);

------------------------------------------------------------
-- Search all online databases
------------------------------------------------------------

DECLARE DatabaseCursor CURSOR LOCAL FAST_FORWARD FOR

SELECT
    d.name
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

------------------------------------------------------------
-- Check MaintenanceSolution procedures
------------------------------------------------------------

OPEN DatabaseCursor;

FETCH NEXT FROM DatabaseCursor INTO @Database;

WHILE @@FETCH_STATUS = 0
BEGIN

    SET @SQL = N'
IF EXISTS
(
    SELECT 1
    FROM ' + QUOTENAME(@Database) + N'.sys.procedures AS p
    INNER JOIN ' + QUOTENAME(@Database) + N'.sys.schemas AS s
        ON s.schema_id = p.schema_id
    WHERE s.name = N''dbo''
      AND p.name IN
      (
          N''DatabaseBackup'',
          N''IndexOptimize'',
          N''DatabaseIntegrityCheck''
      )
    GROUP BY s.name
    HAVING COUNT(DISTINCT p.name) = 3
)
BEGIN
    SET @Result = 1;
END;
';

    BEGIN TRY

        EXEC sys.sp_executesql
            @SQL,
            N'@Result int OUTPUT',
            @Result = @Installed OUTPUT;

    END TRY
    BEGIN CATCH

        ----------------------------------------------------
        -- Skip inaccessible databases
        ----------------------------------------------------

    END CATCH;

    --------------------------------------------------------
    -- Stop searching when MaintenanceSolution is found
    --------------------------------------------------------

    IF @Installed = 1
        BREAK;

    FETCH NEXT FROM DatabaseCursor INTO @Database;

END;

CLOSE DatabaseCursor;
DEALLOCATE DatabaseCursor;

------------------------------------------------------------
-- Return one integer for Zabbix
------------------------------------------------------------

SELECT
    @Installed AS maintenancesolution_installed;
