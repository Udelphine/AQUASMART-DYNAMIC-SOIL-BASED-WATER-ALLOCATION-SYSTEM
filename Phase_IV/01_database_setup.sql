-- ====================================================
-- AQUASMART DATABASE CREATION SCRIPT
-- Student: Uwineza Delphine (ID: 27897)
-- Course: Database Development with PL/SQL
-- Phase IV: Database Creation
-- ====================================================

-- PART 1: CREATE PLUGGABLE DATABASE (Run as SYSDBA)
/*
-- Step 1: Connect as sysdba
-- CONNECT sys AS sysdba;

-- Step 2: Create PDB
CREATE PLUGGABLE DATABASE d_27897_delphine_aquasmart_db
ADMIN USER aquasmart_admin IDENTIFIED BY Delphine
CREATE_FILE_DEST = 'C:\APP\KABANDANA\PRODUCT\21C\ORADATA\XE';

-- Step 3: Open PDB
ALTER PLUGGABLE DATABASE d_27897_delphine_aquasmart_db OPEN;
*/

-- PART 2: CREATE TABLESPACES (Run as aquasmart_admin)
-- Step 4: Connect to your PDB
-- CONNECT aquasmart_admin/Delphine@localhost:1521/d_27897_delphine_aquasmart_db

PROMPT === CREATING TABLESPACES ===

-- Create DATA tablespace
CREATE TABLESPACE aquasmart_data
DATAFILE 'aquasmart_data01.dbf'
SIZE 100M
AUTOEXTEND ON NEXT 50M MAXSIZE 500M;

-- Create INDEX tablespace
CREATE TABLESPACE aquasmart_index
DATAFILE 'aquasmart_index01.dbf'
SIZE 50M
AUTOEXTEND ON NEXT 25M MAXSIZE 200M;

-- Create TEMPORARY tablespace
CREATE TEMPORARY TABLESPACE aquasmart_temp
TEMPFILE 'aquasmart_temp01.dbf'
SIZE 50M
AUTOEXTEND ON NEXT 25M MAXSIZE 200M;

PROMPT === CREATING APPLICATION USER ===

-- Create application user
CREATE USER aquasmart_app IDENTIFIED BY AppPass123
DEFAULT TABLESPACE aquasmart_data
TEMPORARY TABLESPACE aquasmart_temp
QUOTA 50M ON aquasmart_data;

GRANT CONNECT, CREATE SESSION TO aquasmart_app;

PROMPT === VERIFICATION QUERIES ===

-- 1. Tablespaces created
SELECT 'Tablespaces:' as verification FROM dual;
SELECT tablespace_name, status, contents FROM user_tablespaces;

-- 2. Data files
SELECT 'Data Files:' as verification FROM dual;
SELECT file_name, tablespace_name, bytes/1024/1024 as size_mb
FROM dba_data_files;

-- 3. Users
SELECT 'Users Created:' as verification FROM dual;
SELECT username, account_status, created 
FROM dba_users 
WHERE username LIKE 'AQUASMART%';

PROMPT === PHASE IV COMPLETED SUCCESSFULLY ===
PROMPT Database: d_27897_delphine_aquasmart_db
PROMPT Admin User: aquasmart_admin
PROMPT Tablespaces: aquasmart_data, aquasmart_index, aquasmart_temp
PROMPT Application User: aquasmart_app