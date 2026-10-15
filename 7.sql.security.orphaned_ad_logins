
/*
===============================================================================
ZABBIX SQL SERVER MONITORING - VERSION 1.0
===============================================================================
Name         : 7.sql.security.orphaned_ad_logins
Purpose      : Count Windows logins and groups whose SIDs
               cannot be resolved by SQL Server.

ODBC Key     : db.odbc.select[7.sql.security.orphaned_ad_logins,,"Driver={$MSSQL.ODBC.DRIVER};Server={$MSSQL.HOST};Port={$MSSQL.PORT};UID={$MSSQL.USER};PWD={$MSSQL.PASSWORD};Encrypt={$MSSQL.ENCRYPT}"]

Interval     : 24h
History      : 730d
Trends       : 1825d
Type         : Numeric (unsigned)
Compatibility: SQL Server 2012+

AG Handling  : Not applicable. Instance-level metric.

Notes        : Checks Windows logins and groups.
               Excludes local and built-in accounts.
               Uses SID resolution as a screening check.
               Unresolved SIDs are not proof of AD deletion.
               Domain connectivity and trust relationships
               can affect results.
               Requires sufficient metadata visibility.
               Returns one integer.
===============================================================================
*/

SET NOCOUNT ON;

------------------------------------------------------------
-- Count Windows principals with unresolved SIDs
------------------------------------------------------------

SELECT
    COUNT(*) AS orphaned_ad_logins
FROM sys.server_principals AS sp
WHERE sp.type IN (N'U', N'G')

  -- Exclude built-in and service accounts
  AND sp.name NOT LIKE N'NT AUTHORITY\%'
  AND sp.name NOT LIKE N'NT SERVICE\%'
  AND sp.name NOT LIKE N'BUILTIN\%'

  -- Only domain-style names
  AND CHARINDEX(N'\', sp.name) > 1

  -- SID cannot be resolved
  AND SUSER_SNAME(sp.sid) IS NULL;
