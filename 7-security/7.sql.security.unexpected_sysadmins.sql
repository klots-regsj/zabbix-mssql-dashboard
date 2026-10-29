/*
===============================================================================
ZABBIX SQL SERVER MONITORING - VERSION 1.0
===============================================================================
Name         : 7.sql.security.unexpected_sysadmins
Purpose      : Count SQL Server sysadmin role members
               not included in the approved whitelist.

ODBC Key     : db.odbc.select[7.sql.security.unexpected_sysadmins,,"Driver={$MSSQL.ODBC.DRIVER};Server={$MSSQL.HOST};Port={$MSSQL.PORT};UID={$MSSQL.USER};PWD={$MSSQL.PASSWORD};Encrypt={$MSSQL.ENCRYPT}"]

Interval     : 24h
History      : 730d
Trends       : 1825d
Type         : Numeric (unsigned)
Compatibility: SQL Server 2012+

AG Handling  : Not applicable. Instance-level metric.

Notes        : Identifies sysadmin role members not included
               in the approved whitelist.
               Returns 0 when all direct role members
               are approved.
               Returns >0 when unexpected members exist.
               Windows group membership is not expanded.
               Fixed server role membership is checked.
               Does not modify any permissions or logins.
===============================================================================
*/

SET NOCOUNT ON;

------------------------------------------------------------
-- Approved sysadmin whitelist
------------------------------------------------------------

WITH Whitelist AS
(
    SELECT LoginName
    FROM (VALUES
        (N'REGSJ\*),
        (N'sa')
        -- Add additional approved logins or groups here
    ) AS W(LoginName)
)

------------------------------------------------------------
-- Count unexpected sysadmin role members
------------------------------------------------------------

SELECT
    COUNT(*) AS unexpected_sysadmins

FROM sys.server_role_members AS srm

INNER JOIN sys.server_principals AS sp
    ON sp.principal_id = srm.member_principal_id

WHERE srm.role_principal_id = SUSER_ID(N'sysadmin')

  ----------------------------------------------------------
  -- Exclude approved sysadmin members
  ----------------------------------------------------------

  AND NOT EXISTS
  (
      SELECT 1
      FROM Whitelist AS w
      WHERE w.LoginName = sp.name
  );
