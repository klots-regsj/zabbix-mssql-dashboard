
/*
===============================================================================
ZABBIX SQL SERVER MONITORING - VERSION 1.0
===============================================================================
Name         : 2.sql.database.max_inactive_days
Purpose      : Return the maximum number of days since the last
               recorded index activity across eligible user databases.

ODBC Key     : db.odbc.select[2.sql.database.max_inactive_days,,"Driver={$MSSQL.ODBC.DRIVER};Server={$MSSQL.HOST};Port={$MSSQL.PORT};UID={$MSSQL.USER};PWD={$MSSQL.PASSWORD};Encrypt={$MSSQL.ENCRYPT}"]

Interval     : 24h
History      : 730d
Trends       : 1825d
Type         : Numeric (unsigned)
Units        : d
Compatibility: SQL Server 2012+

AG Handling  : Include standalone and local AG primary databases.
               Exclude AG secondary databases.

Notes        : Excludes system databases, DBA% databases,
               snapshots and offline databases.
               Includes read-only databases.
               Uses sys.dm_db_index_usage_stats.
               Databases without recorded activity use the SQL
               Server startup time as their reference.
               Returns 0 when no eligible databases exist.
               Does not represent a persistent access history.
===============================================================================
*/

SET NOCOUNT ON;

DECLARE @sqlserver_start_time datetime;
DECLARE @now datetime = GETDATE();

------------------------------------------------------------
-- Get SQL Server startup time
------------------------------------------------------------

SELECT
    @sqlserver_start_time = sqlserver_start_time
FROM sys.dm_os_sys_info;

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
-- Select eligible databases and calculate inactivity
------------------------------------------------------------

inactive_days AS
(
    SELECT
        d.database_id,

        DATEDIFF
        (
            DAY,
            COALESCE(a.last_access, @sqlserver_start_time),
            @now
        ) AS days_since_last_access

    FROM sys.databases AS d

    LEFT JOIN activity AS a
        ON a.database_id = d.database_id

    WHERE d.database_id > 4
      AND d.state_desc = N'ONLINE'
      AND d.source_database_id IS NULL
      AND d.name NOT LIKE N'DBA%'

      ------------------------------------------------------
      -- Standalone or local AG primary
      ------------------------------------------------------

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
      )
)

------------------------------------------------------------
-- Return maximum inactivity in days
------------------------------------------------------------

SELECT
    ISNULL(MAX(days_since_last_access), 0)
        AS max_inactive_days
FROM inactive_days;
