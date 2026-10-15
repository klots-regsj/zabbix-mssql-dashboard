
/*
===============================================================================
ZABBIX SQL SERVER MONITORING - VERSION 1.0
===============================================================================
Name         : 4.sql.storage.logfile_maxsize_reached
Purpose      : Count transaction log files that have reached
               their configured maximum file size.

ODBC Key     : db.odbc.select[4.sql.storage.logfile_maxsize_reached,,"Driver={$MSSQL.ODBC.DRIVER};Server={$MSSQL.HOST};Port={$MSSQL.PORT};UID={$MSSQL.USER};PWD={$MSSQL.PASSWORD};Encrypt={$MSSQL.ENCRYPT}"]

Interval     : 1h
History      : 365d
Trends       : 730d
Type         : Numeric (unsigned)
Units        : None
Compatibility: SQL Server 2012+

AG Handling  : Includes standalone and local AG primary databases.
               Excludes AG secondary databases.

Notes        : Uses sys.master_files.
               Counts LOG files where allocated size has
               reached the configured maximum size.
               Only considers files with a positive MAXSIZE.
               Excludes unlimited and non-growing files.
               Excludes system databases, DBA% databases,
               snapshots and offline databases.
               Includes read-only databases.
               Does not measure actual log utilization or
               available disk space.
               Returns one integer value.
===============================================================================
*/

SET NOCOUNT ON;

------------------------------------------------------------
-- Count log files at their configured maximum size
------------------------------------------------------------

SELECT
    COUNT(*) AS logfile_maxsize_reached
FROM sys.master_files AS mf
INNER JOIN sys.databases AS d
    ON d.database_id = mf.database_id
WHERE d.database_id > 4
  AND d.state_desc = N'ONLINE'
  AND d.source_database_id IS NULL
  AND d.name NOT LIKE N'DBA%'

  ----------------------------------------------------------
  -- Transaction log files only
  ----------------------------------------------------------

  AND mf.type = 1

  ----------------------------------------------------------
  -- Only files with an explicit maximum size
  ----------------------------------------------------------

  AND mf.max_size > 0

  ----------------------------------------------------------
  -- Allocated size has reached maximum size
  ----------------------------------------------------------

  AND mf.size >= mf.max_size

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
