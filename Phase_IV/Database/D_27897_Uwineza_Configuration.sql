-- ============================================
-- AquaSmart Database Configuration
-- ============================================

-- Connect as admin
CONNECT aqua_admin/Delphine@localhost:1521/D_27897_Uwineza_AquaSmart_DB;

-- 1. TABLESPACE MONITORING AND MAINTENANCE
-- Check tablespace usage
SELECT tablespace_name, 
       ROUND(used_space/1024/1024, 2) as used_mb,
       ROUND(tablespace_size/1024/1024, 2) as total_mb,
       ROUND(used_percent, 2) as used_percent
FROM dba_tablespace_usage_metrics
WHERE tablespace_name LIKE 'AQUA%';

-- Add datafile if needed (example)
ALTER TABLESPACE aqua_data
ADD DATAFILE '/opt/oracle/oradata/XE/D_27897_Uwineza_AquaSmart_DB/aqua_data02.dbf'
SIZE 50M AUTOEXTEND ON NEXT 25M MAXSIZE 500M;

-- 2. PERFORMANCE PARAMETERS
-- Set optimizer statistics
EXEC DBMS_STATS.GATHER_DATABASE_STATS;

-- Enable query result cache
ALTER SYSTEM SET RESULT_CACHE_MODE = FORCE SCOPE=BOTH;

-- Set cursor sharing for similar queries
ALTER SYSTEM SET CURSOR_SHARING = FORCE SCOPE=BOTH;

-- 3. SECURITY CONFIGURATION
-- Enable auditing
AUDIT ALL BY aqua_app_user BY ACCESS;
AUDIT SELECT TABLE, UPDATE TABLE, INSERT TABLE, DELETE TABLE BY aqua_app_user;

-- Create audit trail table
CREATE TABLE system_audit_trail (
    audit_id NUMBER GENERATED ALWAYS AS IDENTITY,
    username VARCHAR2(30),
    action_time TIMESTAMP DEFAULT SYSTIMESTAMP,
    object_name VARCHAR2(128),
    action_type VARCHAR2(20),
    sql_text CLOB
) TABLESPACE aqua_data;

-- 4. BACKUP CONFIGURATION (Example)
-- Configure RMAN (if available)
/*
RUN {
    CONFIGURE RETENTION POLICY TO RECOVERY WINDOW OF 7 DAYS;
    CONFIGURE CONTROLFILE AUTOBACKUP ON;
    CONFIGURE CHANNEL DEVICE TYPE DISK FORMAT '/backup/%U';
}
*/

-- 5. MONITORING SETUP
-- Create monitoring views
CREATE OR REPLACE VIEW aqua_database_monitor AS
SELECT 
    (SELECT COUNT(*) FROM dba_tables WHERE owner = 'AQUA_APP_USER') as tables_count,
    (SELECT COUNT(*) FROM dba_sequences WHERE sequence_owner = 'AQUA_APP_USER') as sequences_count,
    (SELECT COUNT(*) FROM dba_indexes WHERE owner = 'AQUA_APP_USER') as indexes_count,
    (SELECT ROUND(SUM(bytes)/1024/1024, 2) FROM dba_segments WHERE owner = 'AQUA_APP_USER') as total_size_mb
FROM dual;

-- 6. DAILY MAINTENANCE JOB (Example)
BEGIN
    DBMS_SCHEDULER.CREATE_JOB (
        job_name        => 'AQUA_DAILY_MAINTENANCE',
        job_type        => 'PLSQL_BLOCK',
        job_action      => 'BEGIN 
                              DBMS_STATS.GATHER_SCHEMA_STATS(''AQUA_APP_USER''); 
                              DBMS_OUTPUT.PUT_LINE(''Stats gathered for AQUA_APP_USER'');
                           END;',
        start_date      => SYSTIMESTAMP,
        repeat_interval => 'FREQ=DAILY; BYHOUR=2; BYMINUTE=0',
        enabled         => TRUE,
        comments        => 'Daily maintenance job for AquaSmart database'
    );
END;
/

-- 7. VERIFICATION QUERIES
-- Show all configuration
SELECT * FROM v$parameter WHERE name IN (
    'sga_target', 'pga_aggregate_target', 'db_cache_size',
    'optimizer_mode', 'cursor_sharing', 'result_cache_mode'
);

-- Show tablespace configuration
SELECT tablespace_name, file_name, bytes/1024/1024 as size_mb, autoextensible
FROM dba_data_files
WHERE tablespace_name LIKE 'AQUA%'
UNION
SELECT tablespace_name, file_name, bytes/1024/1024 as size_mb, autoextensible
FROM dba_temp_files
WHERE tablespace_name LIKE 'AQUA%';