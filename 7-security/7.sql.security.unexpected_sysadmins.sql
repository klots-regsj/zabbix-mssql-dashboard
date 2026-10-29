/*
===============================================================================
ZABBIX SQL SERVER MONITORING - VERSION 1.0
===============================================================================
Name         : 7.sql.security.unexpected_sysadmins
Purpose      : Count unexpected SQL Server sysadmin role members,
               excluding approved SQL and Windows accounts.

ODBC Key     : db.odbc.select[7.sql.security.unexpected_sysadmins,,"Driver={$MSSQL.ODBC.DRIVER};Server={$MSSQL.HOST};Port={$MSSQL.PORT};UID={$MSSQL.USER};PWD={$MSSQL.PASSWORD};Encrypt={$MSSQL.ENCRYPT}"]

Interval     : 24h
History      : 730d
Trends       : 1825d
Type         : Numeric (unsigned)
Compatibility: SQL Server 2012+

AG Handling  : Not applicable. Instance-level metric.

Notes        : Counts unexpected sysadmin role members.
               Uses separate SQL and Windows exception lists.
               Supports exact matches and Windows prefixes.
               Includes disabled logins.
               Excludes approved administrative, service
               and machine-specific accounts.
               Windows group membership is not expanded.
               Returns 0 when all members are approved.
               Does not modify permissions or logins.

               Customize the exception lists before deployment.
===============================================================================
*/

SET NOCOUNT ON;

------------------------------------------------------------
-- Approved SQL login exceptions (exact match)
------------------------------------------------------------

;WITH SQLExceptions AS
(
    SELECT LoginName
    FROM (VALUES
        (N'sa')
        -- (N'approved_sql_login')
    ) AS E(LoginName)
),

------------------------------------------------------------
-- Approved Windows exceptions (exact match)
------------------------------------------------------------

WindowsExactExceptions AS
(
    SELECT LoginName
    FROM (VALUES
        (N'CONTOSO\SQL-Admins')
        -- (N'CONTOSO\Approved-Service-Account')
    ) AS E(LoginName)
),

------------------------------------------------------------
-- Approved Windows exceptions (prefix match)
------------------------------------------------------------

WindowsPrefixExceptions AS
(
    SELECT LoginPrefix
    FROM (VALUES
        (N'NT AUTHORITY\'),
        (N'NT SERVICE\')
        -- (N'CONTOSO\svc-sql-')
        -- (N'CONTOSO\adm-')
    ) AS E(LoginPrefix)
),

------------------------------------------------------------
-- Approved machine-specific Windows accounts
------------------------------------------------------------

MachineExceptions AS
(
    SELECT LoginName
    FROM (VALUES
        (
            CONCAT(
                N'CONTOSO\',
                CONVERT(NVARCHAR(128),
                    SERVERPROPERTY('MachineName')),
                N'$'
            )
        ),
        (
            CONCAT(
                N'CONTOSO\SQL_',
                CONVERT(NVARCHAR(128),
                    SERVERPROPERTY('MachineName')),
                N'_A$'
            )
        )
    ) AS E(LoginName)
)

------------------------------------------------------------
-- Count unexpected sysadmin role members
------------------------------------------------------------

SELECT
    COUNT(*) AS unexpected_sysadmins

FROM sys.server_principals AS sp

WHERE
    --------------------------------------------------------
    -- Must have sysadmin privileges
    --------------------------------------------------------

    (
        sp.principal_id = 1

        OR EXISTS
        (
            SELECT 1
            FROM sys.server_role_members AS srm
            WHERE srm.member_principal_id = sp.principal_id
              AND srm.role_principal_id = SUSER_ID(N'sysadmin')
        )
    )

    AND
    (
        ----------------------------------------------------
        -- SQL logins: exclude approved exact names
        ----------------------------------------------------

        (
            sp.type = N'S'

            AND NOT EXISTS
            (
                SELECT 1
                FROM SQLExceptions AS e
                WHERE e.LoginName = sp.name
            )
        )

        OR

        ----------------------------------------------------
        -- Windows logins/groups: apply exception lists
        ----------------------------------------------------

        (
            sp.type IN (N'U', N'G')

            AND NOT EXISTS
            (
                SELECT 1
                FROM WindowsExactExceptions AS e
                WHERE e.LoginName = sp.name
            )

            AND NOT EXISTS
            (
                SELECT 1
                FROM WindowsPrefixExceptions AS e
                WHERE LEFT(sp.name, LEN(e.LoginPrefix))
                      = e.LoginPrefix
            )

            AND NOT EXISTS
            (
                SELECT 1
                FROM MachineExceptions AS e
                WHERE e.LoginName = sp.name
            )
        )
    );
