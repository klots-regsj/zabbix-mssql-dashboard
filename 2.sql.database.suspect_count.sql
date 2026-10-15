
/*
Name          : 2.sql.database.suspect_count
Purpose       : Counts user databases in the SUSPECT state.
ODBC Key      : db.odbc.select[2.sql.database.suspect_count,,"Driver={$MSSQL.ODBC.DRIVER};Server={$MSSQL.HOST};Port={$MSSQL.PORT};UID={$MSSQL.USER};PWD={$MSSQL.PASSWORD};Encrypt={$MSSQL.ENCRYPT}"]
Interval      : 5m
History       : 90d
Trends        : 365d
Type          : Numeric (unsigned)
Compatibility : SQL Server 2012+
AG Handling   : Includes standalone and AG databases.
                AG secondary databases are also included
                when their state is SUSPECT.
Notes         : Excludes system databases, DBA databases
                and database snapshots.
                Uses state = 4 (SUSPECT).
                Returns 0 when no databases are SUSPECT.
                Requires appropriate metadata visibility.
*/

SET NOCOUNT ON;

SELECT
    COUNT(*) AS suspect_count
FROM sys.databases AS d
WHERE d.database_id > 4
  AND d.name NOT LIKE N'DBA%'
  AND d.source_database_id IS NULL
  AND d.state = 4;
