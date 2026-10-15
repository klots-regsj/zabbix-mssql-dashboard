
/*
===============================================================================
ZABBIX SQL SERVER MONITORING - VERSION 1.0
===============================================================================
Name         : 1.sql.server.recommended_maxdop
Purpose      : Calculate a recommended instance-level MAXDOP
               based on SQL Server CPU and NUMA topology.

ODBC Key     : db.odbc.select[1.sql.server.recommended_maxdop,,"Driver={$MSSQL.ODBC.DRIVER};Server={$MSSQL.HOST};Port={$MSSQL.PORT};UID={$MSSQL.USER};PWD={$MSSQL.PASSWORD};Encrypt={$MSSQL.ENCRYPT}"]

Interval     : 24h
History      : 730d
Trends       : 1825d
Type         : Numeric (unsigned)
Compatibility: SQL Server 2012+

AG Handling  : Not applicable. Instance-level metric.

Notes        : Calculates a conservative MAXDOP recommendation.
               Uses visible logical CPUs and hardware NUMA nodes.
               Excludes DAC and offline NUMA nodes.
               For SQL Server 2016+, uses the hardware NUMA
               topology rather than soft-NUMA node count.
               Returns a recommendation, not a configuration.
               Does not modify SQL Server settings.
               Actual optimal MAXDOP depends on workload.
               Requires VIEW SERVER STATE on SQL Server
               2012-2019 or VIEW SERVER PERFORMANCE STATE
               on SQL Server 2022+.
               Returns one integer.
===============================================================================
*/

SET NOCOUNT ON;

DECLARE @LogicalCores int;
DECLARE @HardwareNumaNodes int;
DECLARE @CoresPerNode int;
DECLARE @MajorVersion int;
DECLARE @RecommendedMaxdop int;

------------------------------------------------------------
-- Get SQL Server version and visible CPU count
------------------------------------------------------------

SELECT
    @LogicalCores = cpu_count
FROM sys.dm_os_sys_info;

SET @MajorVersion =
    CAST(SERVERPROPERTY('ProductMajorVersion') AS int);

------------------------------------------------------------
-- Count hardware NUMA nodes
-- Exclude DAC and offline nodes
------------------------------------------------------------

SELECT
    @HardwareNumaNodes = COUNT(*)
FROM sys.dm_os_nodes
WHERE node_state_desc = N'ONLINE'
  AND memory_node_id = node_id;

------------------------------------------------------------
-- Calculate logical processors per hardware NUMA node
------------------------------------------------------------

SET @CoresPerNode =
    CASE
        WHEN @HardwareNumaNodes > 0
        THEN @LogicalCores / @HardwareNumaNodes
        ELSE @LogicalCores
    END;

------------------------------------------------------------
-- Apply conservative MAXDOP recommendation
------------------------------------------------------------

SET @RecommendedMaxdop =
    CASE
        WHEN @CoresPerNode <= 0 THEN 1

        -- SQL Server 2016 and newer
        WHEN @MajorVersion >= 13 THEN
            CASE
                WHEN @CoresPerNode <= 8
                    THEN @CoresPerNode
                ELSE 8
            END

        -- SQL Server 2012 / 2014
        ELSE
            CASE
                WHEN @CoresPerNode <= 8
                    THEN @CoresPerNode
                ELSE 8
            END
    END;

------------------------------------------------------------
-- Return recommended MAXDOP
------------------------------------------------------------

SELECT
    @RecommendedMaxdop AS recommended_maxdop;
