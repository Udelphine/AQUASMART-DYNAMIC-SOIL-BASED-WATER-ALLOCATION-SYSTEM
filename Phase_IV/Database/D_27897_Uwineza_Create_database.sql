-- ============================================
-- AquaSmart Database Creation Script
-- ============================================

-- Connect as SYSDBA
CONNECT sys AS sysdba;

-- 1. CREATE PLUGGABLE DATABASE
CREATE PLUGGABLE DATABASE D_27897_Uwineza_AquaSmart_DB
ADMIN USER aqua_admin IDENTIFIED BY Delphine
ROLES = (DBA)
FILE_NAME_CONVERT = ('/opt/oracle/oradata/XE/pdbseed/', 
                     '/opt/oracle/oradata/XE/D_27897_Uwineza_AquaSmart_DB/');

-- Open the new PDB
ALTER PLUGGABLE DATABASE D_27897_Uwineza_AquaSmart_DB OPEN;

-- Switch to new PDB
ALTER SESSION SET CONTAINER = D_27897_Uwineza_AquaSmart_DB;

-- 2. CREATE TABLESPACES
-- Data tablespace
CREATE TABLESPACE aqua_data
DATAFILE '/opt/oracle/oradata/XE/D_27897_Uwineza_AquaSmart_DB/aqua_data01.dbf'
SIZE 100M
AUTOEXTEND ON NEXT 50M MAXSIZE UNLIMITED
EXTENT MANAGEMENT LOCAL
SEGMENT SPACE MANAGEMENT AUTO;

-- Index tablespace
CREATE TABLESPACE aqua_index
DATAFILE '/opt/oracle/oradata/XE/D_27897_Uwineza_AquaSmart_DB/aqua_index01.dbf'
SIZE 50M
AUTOEXTEND ON NEXT 25M MAXSIZE UNLIMITED
EXTENT MANAGEMENT LOCAL
SEGMENT SPACE MANAGEMENT AUTO;

-- Temporary tablespace
CREATE TEMPORARY TABLESPACE aqua_temp
TEMPFILE '/opt/oracle/oradata/XE/D_27897_Uwineza_AquaSmart_DB/aqua_temp01.dbf'
SIZE 50M
AUTOEXTEND ON NEXT 25M MAXSIZE 200M;

-- Undo tablespace (for transactions)
CREATE UNDO TABLESPACE aqua_undo
DATAFILE '/opt/oracle/oradata/XE/D_27897_Uwineza_AquaSmart_DB/aqua_undo01.dbf'
SIZE 100M
AUTOEXTEND ON NEXT 50M MAXSIZE UNLIMITED;

-- 3. CREATE APPLICATION USER WITH PRIVILEGES
CREATE USER aqua_app_user IDENTIFIED BY AquaSmart2025
DEFAULT TABLESPACE aqua_data
TEMPORARY TABLESPACE aqua_temp
QUOTA UNLIMITED ON aqua_data
QUOTA UNLIMITED ON aqua_index;

-- Grant privileges
GRANT CONNECT, RESOURCE TO aqua_app_user;
GRANT CREATE SESSION, CREATE TABLE, CREATE VIEW, 
      CREATE PROCEDURE, CREATE SEQUENCE, CREATE TRIGGER,
      CREATE TYPE, CREATE SYNONYM TO aqua_app_user;
GRANT EXECUTE ON DBMS_CRYPTO TO aqua_app_user;  -- For password encryption

-- 4. CONFIGURE DATABASE PARAMETERS
-- Set memory parameters
ALTER SYSTEM SET SGA_TARGET=512M SCOPE=BOTH;
ALTER SYSTEM SET PGA_AGGREGATE_TARGET=256M SCOPE=BOTH;

-- Enable archive logging (for recovery)
ALTER DATABASE ARCHIVELOG;
ALTER SYSTEM SET LOG_ARCHIVE_DEST_1='LOCATION=/opt/oracle/archive/D_27897_Uwineza_AquaSmart_DB' SCOPE=BOTH;

-- Set optimization parameters
ALTER SYSTEM SET OPTIMIZER_MODE=ALL_ROWS SCOPE=BOTH;
ALTER SYSTEM SET DB_CACHE_SIZE=256M SCOPE=BOTH;

-- 5. CREATE NECESSARY ROLES
CREATE ROLE aqua_developer;
GRANT CREATE SESSION, CREATE TABLE, CREATE VIEW, 
      CREATE PROCEDURE, CREATE SEQUENCE TO aqua_developer;

CREATE ROLE aqua_analyst;
GRANT SELECT ANY TABLE, CREATE SESSION TO aqua_analyst;

-- 6. VERIFICATION QUERIES
-- Check database creation
SELECT name, open_mode, created 
FROM v$database 
WHERE name = 'D_27897_Uwineza_AquaSmart_DB';

-- Check tablespaces
SELECT tablespace_name, status, contents 
FROM dba_tablespaces 
WHERE tablespace_name LIKE 'AQUA%';

-- Check users
SELECT username, account_status, created 
FROM dba_users 
WHERE username LIKE 'AQUA%';

-- 7. CREATE DIRECTORY FOR EXTERNAL FILES (Optional)
CREATE OR REPLACE DIRECTORY aqua_data_dir AS '/opt/oracle/data/aquasmart/';
GRANT READ, WRITE ON DIRECTORY aqua_data_dir TO aqua_app_user;

-- ============================================
-- Database Creation Complete
-- ============================================