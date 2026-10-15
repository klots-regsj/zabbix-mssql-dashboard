
/*
Name          : 2.sql.database.auto_close_count
Purpose       : Counts user databases with AUTO_CLOSE enabled.
ODBC Key      : db.odbc.select[2.sql.database.auto_close_count,,"Driver={$MSSQL.ODBC.DRIVER};Server={$MSSQL.HOST};Port={$MSSQL.PORT};UID={$MSSQL.USER};PWD={$MSSQL.PASSWORD};Encrypt={$MSSQL.ENCRYPT}"]
Interval      : 24h
History       : 730d
Trends        : 1825d
Type          : Numeric (unsigned)
Compatibility : SQL Server 2012+
AG Handling   : Includes standalone databases and local
                AG primary databases.
                Excludes local AG secondary databases.
Notes         : Excludes system databases, DBA databases,
                database snapshots and offline databases.
                Returns 0 when no eligible databases have
                AUTO_CLOSE enabled.
                Intended for database configuration
                housekeeping.
*/

SET NOCOUNT ON;

SELECT
    COUNT(*) AS auto_close_count
FROM sys.databases AS d
WHERE d.database_id > 4
  AND d.name NOT LIKE N'DBA%'
  AND d.source_database_id IS NULL
  AND d.state = 0
  AND d.is_auto_close_on = 1
  AND
  (
      d.replica_id IS NULL
      OR EXISTS
      (
          SELECT 1
          FROM sys.dm_hadr_database_replica_states AS drs
          INNER JOIN sys.dm_hadr_availability_replica_states AS ars
              ON ars.group_id = drs.group_id
             AND ars.replica_id = drs.replica_id
          WHERE drs.database_id = d.database_id
            AND drs.is_local = 1
            AND ars.is_local = 1
            AND ars.role = 1
      )
  );
