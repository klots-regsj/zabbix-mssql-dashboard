
/*
===============================================================================
ZABBIX SQL SERVER MONITORING - VERSION 1.0
===============================================================================
Name         : 2.sql.database.low_compat_count
Purpose      : Count online user databases running at a compatibility
               level below the native SQL Server compatibility level.

Key          : db.odbc.select[2.sql.database.low_compat_count,,"Driver={$MSSQL.ODBC.DRIVER};Server={$MSSQL.HOST};Port={$MSSQL.PORT};UID={$MSSQL.USER};PWD={$MSSQL.PASSWORD};Encrypt={$MSSQL.ENCRYPT}"]

Interval     : 1h
History      : 365d
Trends       : 730d
Type         : Numeric (unsigned)
Compatibility: SQL Server 2012+

AG Handling  : Include standalone and local AG primary databases.
               Exclude AG secondary databases.

Notes        : Excludes system databases, snapshots and DBA% databases.
               Returns one integer.
               Unsupported SQL Server versions raise an error.
===============================================================================
*/

SET NOCOUNT ON;

DECLARE @ServerMajor int;
DECLARE @ServerCompat int;

------------------------------------------------------------
-- Determine native SQL Server compatibility level
------------------------------------------------------------

SET @ServerMajor =
    CONVERT(int, SERVERPROPERTY('ProductMajorVersion'));

SET @ServerCompat =
    CASE @ServerMajor
        WHEN 17 THEN 170  -- SQL Server 2025
        WHEN 16 THEN 160  -- SQL Server 2022
        WHEN 15 THEN 150  -- SQL Server 2019
        WHEN 14 THEN 140  -- SQL Server 2017
        WHEN 13 THEN 130  -- SQL Server 2016
        WHEN 12 THEN 120  -- SQL Server 2014
        WHEN 11 THEN 110  -- SQL Server 2012
        ELSE NULL
    END;

IF @ServerCompat IS NULL
BEGIN
    RAISERROR(
        'Unsupported SQL Server version.',
        16, 1
    );
    RETURN;
END;

------------------------------------------------------------
-- Count databases below native compatibility level
--
-- Include:
--   * Standalone databases
--   * Local AG primary databases
--
-- Exclude:
--   * System databases
--   * DBA% databases
--   * Database snapshots
--   * Offline databases
--   * AG secondary databases
------------------------------------------------------------

SELECT
    COUNT(*) AS user_database_count_low_compat
FROM sys.databases AS d
WHERE d.database_id > 4
  AND d.name NOT LIKE 'DBA%'
  AND d.state_desc = 'ONLINE'
  AND d.source_database_id IS NULL
  AND d.compatibility_level < @ServerCompat

  AND
  (
      -- Standalone databases
      NOT EXISTS
      (
          SELECT 1
          FROM sys.availability_databases_cluster AS adc
          WHERE adc.database_name = d.name
      )

      OR

      -- Local AG primary databases
      EXISTS
      (
          SELECT 1
          FROM sys.dm_hadr_database_replica_states AS drs
          WHERE drs.database_id = d.database_id
            AND drs.is_local = 1
            AND drs.is_primary_replica = 1
      )
  );
