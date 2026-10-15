
/*
===============================================================================
ZABBIX SQL SERVER MONITORING - VERSION 1.0
===============================================================================
Name         : 5.sql.performance.cpu_total_percent
Purpose      : Return the latest total operating system CPU
               utilization percentage observed by SQL Server.

ODBC Key     : db.odbc.select[5.sql.performance.cpu_total_percent,,"Driver={$MSSQL.ODBC.DRIVER};Server={$MSSQL.HOST};Port={$MSSQL.PORT};UID={$MSSQL.USER};PWD={$MSSQL.PASSWORD};Encrypt={$MSSQL.ENCRYPT}"]

Interval     : 1m
History      : 31d
Trends       : 365d
Type         : Numeric (float)
Units        : %
Compatibility: SQL Server 2012+

AG Handling  : Not applicable. Instance-level metric.

Notes        : Uses sys.dm_os_ring_buffers.
               Reads RING_BUFFER_SCHEDULER_MONITOR records.
               Calculates total CPU usage as 100 - SystemIdle.
               Includes CPU usage from SQL Server and
               other operating system processes.
               Returns the latest valid available sample.
               Ring buffer data is undocumented and its
               format may change between SQL versions.
               Returns NULL if no valid sample exists.
               Requires VIEW SERVER STATE on SQL Server
               2012-2019 or VIEW SERVER PERFORMANCE STATE
               on SQL Server 2022+.
               Returns one decimal value.
===============================================================================
*/

SET NOCOUNT ON;

------------------------------------------------------------
-- Return latest total CPU utilization
------------------------------------------------------------

SELECT
    CAST
    (
        100 - rb.SystemIdle
        AS decimal(5,2)
    ) AS cpu_total_percent

FROM
(
    SELECT TOP (1)
        x.SystemIdle

    FROM sys.dm_os_ring_buffers AS r

    CROSS APPLY
    (
        SELECT
            TRY_CAST(r.record AS xml) AS RecordXML
    ) AS rx

    CROSS APPLY
    (
        SELECT
            rx.RecordXML.value
            (
                '(/Record/SchedulerMonitorEvent/SystemHealth/SystemIdle)[1]',
                'int'
            ) AS SystemIdle
    ) AS x

    WHERE r.ring_buffer_type =
          N'RING_BUFFER_SCHEDULER_MONITOR'

      AND rx.RecordXML.exist
          (
              '/Record/SchedulerMonitorEvent/SystemHealth/SystemIdle'
          ) = 1

      AND x.SystemIdle BETWEEN 0 AND 100

    ORDER BY r.[timestamp] DESC

) AS rb;
