
/*
Name          : 1.sql.server.tcp_port
Purpose       : Returns the TCP port used by the current
                SQL Server monitoring connection.
ODBC Key      : db.odbc.select[1.sql.server.tcp_port,,"Driver={$MSSQL.ODBC.DRIVER};Server={$MSSQL.HOST};Port={$MSSQL.PORT};UID={$MSSQL.USER};PWD={$MSSQL.PASSWORD};Encrypt={$MSSQL.ENCRYPT}"]
Interval      : 24h
History       : 730d
Trends        : 1825d
Type          : Numeric (unsigned)
Compatibility : SQL Server 2012+
AG Handling   : Instance-level connection; AG role is irrelevant.
Notes         : Returns the local TCP port for the current session.
                Returns 0 if the connection is not using TCP.
                Requires appropriate access to connection metadata.
                Does not enumerate all configured listening ports.
                Intended for instance inventory and housekeeping.
*/

SET NOCOUNT ON;

SELECT
    ISNULL(
        CAST(local_tcp_port AS int),
        0
    ) AS tcp_port
FROM sys.dm_exec_connections
WHERE session_id = @@SPID;
