
/*
===============================================================================
ZABBIX SQL SERVER MONITORING - VERSION 1.0
===============================================================================
Name         : 7.sql.security.disabled_logins
Purpose      : Count disabled SQL Server and Windows logins,
               excluding system and internal service accounts.

ODBC Key     : db.odbc.select[7.sql.security.disabled_logins,,"Driver={$MSSQL.ODBC.DRIVER};Server={$MSSQL.HOST};Port={$MSSQL.PORT};UID={$MSSQL.USER};PWD={$MSSQL.PASSWORD};Encrypt={$MSSQL.ENCRYPT}"]

Interval     : 24h
History      : 730d
Trends       : 1825d
Type         : Numeric (unsigned)
Compatibility: SQL Server 2012+

AG Handling  : Not applicable. Instance-level metric.

Notes        : Identifies disabled logins retained on the
               SQL Server instance.
               Disabled logins may be re-enabled by an
               administrator with sufficient permissions.
               Intended to identify accounts for review
               and potential permanent removal.
               Excludes sa and internal service accounts.
               Does not automatically delete any logins.
===============================================================================
*/

SET NOCOUNT ON;

------------------------------------------------------------
-- Count disabled server principals
------------------------------------------------------------

SELECT
    COUNT(*) AS disabled_logins

FROM sys.server_principals AS sp

WHERE sp.type IN (N'S', N'U', N'G')

  AND sp.is_disabled = 1

  ----------------------------------------------------------
  -- Exclude system and internal service accounts
  ----------------------------------------------------------

  AND sp.name NOT LIKE N'##MS_%'
  AND sp.name <> N'sa'
  AND sp.name <> N'NT AUTHORITY\SYSTEM'
  AND sp.name NOT LIKE N'NT SERVICE\%';
