-- ============================================
-- AquaSmart User Setup Script
-- ============================================

-- Connect as SYSDBA
CONNECT sys AS sysdba;
ALTER SESSION SET CONTAINER = D_27897_Uwineza_AquaSmart_DB;

-- 1. ADMIN USER (Already created in PDB creation, but verify)
SELECT username, account_status, default_tablespace
FROM dba_users 
WHERE username = 'AQUA_ADMIN';

-- Grant additional privileges to admin
GRANT CREATE USER, DROP USER, ALTER USER TO aqua_admin;
GRANT GRANT ANY PRIVILEGE TO aqua_admin;
GRANT SELECT ANY DICTIONARY TO aqua_admin;

-- 2. CREATE SEPARATE USERS FOR DIFFERENT ROLES

-- Developer User
CREATE USER aqua_dev IDENTIFIED BY DevPass2025
DEFAULT TABLESPACE aqua_data
TEMPORARY TABLESPACE aqua_temp
QUOTA UNLIMITED ON aqua_data
QUOTA UNLIMITED ON aqua_index;

GRANT aqua_developer TO aqua_dev;
GRANT CREATE JOB, CREATE DATABASE LINK TO aqua_dev;

-- Analyst User (for BI/Reporting)
CREATE USER aqua_analyst_user IDENTIFIED BY Analyst2025
DEFAULT TABLESPACE aqua_data
TEMPORARY TABLESPACE aqua_temp
QUOTA 100M ON aqua_data;

GRANT aqua_analyst TO aqua_analyst_user;
GRANT SELECT ON aqua_app_user.farmers TO aqua_analyst_user;
GRANT SELECT ON aqua_app_user.farm_zones TO aqua_analyst_user;
GRANT SELECT ON aqua_app_user.sensor_data TO aqua_analyst_user;
GRANT SELECT ON aqua_app_user.irrigation_logs TO aqua_analyst_user;

-- 3. PASSWORD POLICIES
-- Set password expiration (90 days)
ALTER PROFILE DEFAULT LIMIT PASSWORD_LIFE_TIME 90;
ALTER PROFILE DEFAULT LIMIT PASSWORD_GRACE_TIME 7;

-- 4. CREATE USER MAPPING FOR SECURITY
BEGIN
    DBMS_NETWORK_ACL_ADMIN.CREATE_ACL (
        acl         => 'aqua_services.xml',
        description => 'ACL for AquaSmart web services',
        principal   => 'AQUA_APP_USER',
        is_grant    => TRUE,
        privilege   => 'connect'
    );
    
    DBMS_NETWORK_ACL_ADMIN.ADD_PRIVILEGE (
        acl         => 'aqua_services.xml',
        principal   => 'AQUA_APP_USER',
        is_grant    => TRUE,
        privilege   => 'resolve'
    );
    
    DBMS_NETWORK_ACL_ADMIN.ASSIGN_ACL (
        acl         => 'aqua_services.xml',
        host        => '*',
        lower_port  => 80,
        upper_port  => 443
    );
END;
/

-- 5. VERIFICATION
-- List all users in the PDB
SELECT username, account_status, default_tablespace, created
FROM dba_users
ORDER BY created DESC;

-- Show user privileges
SELECT * FROM dba_sys_privs WHERE grantee LIKE 'AQUA%';
SELECT * FROM dba_role_privs WHERE grantee LIKE 'AQUA%';