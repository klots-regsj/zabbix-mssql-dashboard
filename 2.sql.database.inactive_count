
/*
===============================================================================
ZABBIX SQL SERVER MONITORING - VERSION 1.0
===============================================================================
Name         : 2.sql.database.inactive_count
Purpose      : Count online user databases without recorded index
               usage activity since SQL Server statistics were reset.

ODBC Key     : db.odbc.select[2.sql.database.inactive_count,,"Driver={$MSSQL.ODBC.DRIVER};Server={$MSSQL.HOST};Port={$MSSQL.PORT};UID={$MSSQL.USER};PWD={$MSSQL.PASSWORD};Encrypt={$MSSQL.ENCRYPT}"]

Interval     : 24h
History      : 730d
Trends       : 1825d
Type         : Numeric (unsigned)
Compatibility: SQL Server 2012+

AG Handling  : Include standalone and local AG primary databases.
               Exclude AG secondary databases.

Notes        : Excludes system databases, DBA% databases,
               snapshots and offline databases.
               Uses sys.dm_db_index_usage_stats.
               Statistics may reset after SQL Server restart,
               database detach or certain database operations.
               No index activity does not prove no database usage.
               Returns one integer.
===============================================================================
*/

SET NOCOUNT ON;

------------------------------------------------------------
-- Find last recorded index activity per database
------------------------------------------------------------

;WITH activity AS
(
    SELECT
        s.database_id,
        MAX(v.dt) AS last_access
    FROM sys.dm_db_index_usage_stats AS s

    CROSS APPLY
    (
        VALUES
            (s.last_user_lookup),
            (s.last_user_scan),
            (s.last_user_seek),
            (s.last_user_update)
    ) AS v(dt)

    GROUP BY
        s.database_id
)

------------------------------------------------------------
-- Count databases without recorded activity
------------------------------------------------------------

SELECT
    COUNT(*) AS inactive_databases

FROM sys.databases AS d

LEFT JOIN activity AS a
    ON a.database_id = d.database_id

WHERE d.database_id > 4
  AND d.state_desc = N'ONLINE'
  AND d.source_database_id IS NULL
  AND d.name NOT LIKE N'DBA%'

  -- No recorded index activity
  AND a.last_access IS NULL

  ----------------------------------------------------------
  -- Standalone or local AG primary
  ----------------------------------------------------------

  AND
  (
      -- Standalone database
      d.replica_id IS NULL

      OR

      -- Local AG primary database
      EXISTS
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
