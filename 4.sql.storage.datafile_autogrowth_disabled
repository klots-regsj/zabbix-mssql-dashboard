
/*
===============================================================================
ZABBIX SQL SERVER MONITORING - VERSION 1.0
===============================================================================
Name         : 4.sql.storage.datafile_autogrowth_disabled
Purpose      : Count user database data files where
               automatic file growth is disabled.

ODBC Key     : db.odbc.select[4.sql.storage.datafile_autogrowth_disabled,,"Driver={$MSSQL.ODBC.DRIVER};Server={$MSSQL.HOST};Port={$MSSQL.PORT};UID={$MSSQL.USER};PWD={$MSSQL.PASSWORD};Encrypt={$MSSQL.ENCRYPT}"]

Interval     : 1h
History      : 365d
Trends       : 730d
Type         : Numeric (unsigned)
Units        : None
Compatibility: SQL Server 2012+

AG Handling  : Includes standalone and local AG primary databases.
               Excludes AG secondary databases.

Notes        : Uses sys.master_files.
               Counts ROWS data files with growth = 0.
               Excludes system databases, DBA% databases,
               snapshots and offline databases.
               Includes read-only databases.
               Does not count log files.
               Returns one integer value.
===============================================================================
*/

SET NOCOUNT ON;

------------------------------------------------------------
-- Count data files with autogrowth disabled
------------------------------------------------------------

SELECT
    COUNT(*) AS datafile_autogrowth_disabled

FROM sys.master_files AS mf

INNER JOIN sys.databases AS d
    ON d.database_id = mf.database_id

WHERE d.database_id > 4
  AND d.state_desc = N'ONLINE'
  AND d.source_database_id IS NULL
  AND d.name NOT LIKE N'DBA%'

  ----------------------------------------------------------
  -- Data files only
  ----------------------------------------------------------

  AND mf.type = 0

  ----------------------------------------------------------
  -- Autogrowth disabled
  ----------------------------------------------------------

  AND mf.growth = 0

  ----------------------------------------------------------
  -- Standalone or local AG primary
  ----------------------------------------------------------

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
