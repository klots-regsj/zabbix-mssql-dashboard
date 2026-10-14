
/*
===============================================================================
ZABBIX SQL SERVER MONITORING - VERSION 1.0
===============================================================================
Name         : 2.sql.database.inactive_size_gb
Purpose      : Calculate the total allocated data file size in GB
               for user databases without recorded index activity.

ODBC Key     : db.odbc.select[2.sql.database.inactive_size_gb,,"Driver={$MSSQL.ODBC.DRIVER};Server={$MSSQL.HOST};Port={$MSSQL.PORT};UID={$MSSQL.USER};PWD={$MSSQL.PASSWORD};Encrypt={$MSSQL.ENCRYPT}"]

Interval     : 24h
History      : 730d
Trends       : 1825d
Type         : Numeric (float)
Units        : GB
Compatibility: SQL Server 2012+

AG Handling  : Include standalone and local AG primary databases.
               Exclude AG secondary databases.

Notes        : Uses the same inactivity criteria as
               2.sql.database.inactive_count.
               Excludes system databases, DBA% databases,
               snapshots and offline databases.
               Includes allocated data files only, not log files.
               Index usage statistics may reset after restart
               or database operations.
               Returns one decimal value.
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
),

------------------------------------------------------------
-- Calculate allocated data file size per database
------------------------------------------------------------

data_files AS
(
    SELECT
        database_id,
        SUM(CAST(size AS bigint)) AS total_pages
    FROM sys.master_files
    WHERE type = 0
    GROUP BY database_id
)

------------------------------------------------------------
-- Sum data file size for inactive databases
------------------------------------------------------------

SELECT
    CAST(
        COALESCE(SUM(f.total_pages), 0) * 8.0 / 1024 / 1024
        AS decimal(18, 2)
    ) AS inactive_databases_size_gb

FROM sys.databases AS d

LEFT JOIN activity AS a
    ON a.database_id = d.database_id

LEFT JOIN data_files AS f
    ON f.database_id = d.database_id

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
