-- ============================================
-- PHASE VII: AUDIT TABLES
-- ============================================

-- Create AUDIT_LOG table to track all restricted operations
CREATE TABLE audit_log (
    audit_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    table_name VARCHAR2(50) NOT NULL,
    operation_type VARCHAR2(10) NOT NULL CHECK (operation_type IN ('INSERT', 'UPDATE', 'DELETE')),
    username VARCHAR2(50) NOT NULL,
    operation_date TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
    restricted_attempt CHAR(1) NOT NULL CHECK (restricted_attempt IN ('Y', 'N')),
    restriction_reason VARCHAR2(200),
    original_data CLOB,
    new_data CLOB,
    ip_address VARCHAR2(45),
    session_id VARCHAR2(50),
    machine_name VARCHAR2(100)
);

COMMENT ON TABLE audit_log IS 'Audit trail for all database operations, especially restricted ones';
COMMENT ON COLUMN audit_log.restricted_attempt IS 'Y if operation was restricted/blocked, N if allowed';
COMMENT ON COLUMN audit_log.restriction_reason IS 'Reason for restriction (weekday, holiday, etc.)';

-- Create indexes for performance
CREATE INDEX idx_audit_log_username ON audit_log(username);
CREATE INDEX idx_audit_log_date ON audit_log(operation_date);
CREATE INDEX idx_audit_log_restricted ON audit_log(restricted_attempt);

-- Create function to log audit entries
CREATE OR REPLACE FUNCTION log_audit_entry(
    p_table_name IN VARCHAR2,
    p_operation_type IN VARCHAR2,
    p_username IN VARCHAR2,
    p_restricted_attempt IN CHAR,
    p_restriction_reason IN VARCHAR2 DEFAULT NULL,
    p_original_data IN CLOB DEFAULT NULL,
    p_new_data IN CLOB DEFAULT NULL
) RETURN NUMBER AS
    PRAGMA AUTONOMOUS_TRANSACTION;
    v_audit_id NUMBER;
    v_ip_address VARCHAR2(45);
    v_session_id VARCHAR2(50);
    v_machine_name VARCHAR2(100);
BEGIN
    -- Get session information
    BEGIN
        SELECT SYS_CONTEXT('USERENV', 'IP_ADDRESS'),
               SYS_CONTEXT('USERENV', 'SESSIONID'),
               SYS_CONTEXT('USERENV', 'HOST')
        INTO v_ip_address, v_session_id, v_machine_name
        FROM DUAL;
    EXCEPTION
        WHEN OTHERS THEN
            v_ip_address := NULL;
            v_session_id := NULL;
            v_machine_name := NULL;
    END;
    
    -- Insert audit record
    INSERT INTO audit_log (
        table_name, operation_type, username,
        restricted_attempt, restriction_reason,
        original_data, new_data,
        ip_address, session_id, machine_name
    ) VALUES (
        p_table_name, p_operation_type, p_username,
        p_restricted_attempt, p_restriction_reason,
        p_original_data, p_new_data,
        v_ip_address, v_session_id, v_machine_name
    )
    RETURNING audit_id INTO v_audit_id;
    
    COMMIT;
    RETURN v_audit_id;
    
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END log_audit_entry;
/

-- Create view for easy audit reporting
CREATE OR REPLACE VIEW audit_report AS
SELECT 
    audit_id,
    table_name,
    operation_type,
    username,
    TO_CHAR(operation_date, 'DD-MON-YYYY HH24:MI:SS') as operation_date,
    restricted_attempt,
    restriction_reason,
    ip_address,
    session_id,
    machine_name
FROM audit_log
ORDER BY operation_date DESC;

-- Create procedure to generate audit summary
CREATE OR REPLACE PROCEDURE generate_audit_summary(
    p_start_date IN DATE DEFAULT SYSDATE - 7,
    p_end_date IN DATE DEFAULT SYSDATE
) AS
    v_total_attempts NUMBER;
    v_restricted_count NUMBER;
    v_allowed_count NUMBER;
    v_common_reason VARCHAR2(200);
BEGIN
    DBMS_OUTPUT.PUT_LINE('============================================');
    DBMS_OUTPUT.PUT_LINE('AUDIT SUMMARY REPORT');
    DBMS_OUTPUT.PUT_LINE('Period: ' || TO_CHAR(p_start_date, 'DD-MON-YYYY') || 
                       ' to ' || TO_CHAR(p_end_date, 'DD-MON-YYYY'));
    DBMS_OUTPUT.PUT_LINE('Generated: ' || TO_CHAR(SYSDATE, 'DD-MON-YYYY HH24:MI:SS'));
    DBMS_OUTPUT.PUT_LINE('============================================');
    
    -- Get statistics
    SELECT COUNT(*) INTO v_total_attempts
    FROM audit_log
    WHERE operation_date BETWEEN p_start_date AND p_end_date;
    
    SELECT COUNT(*) INTO v_restricted_count
    FROM audit_log
    WHERE operation_date BETWEEN p_start_date AND p_end_date
    AND restricted_attempt = 'Y';
    
    SELECT COUNT(*) INTO v_allowed_count
    FROM audit_log
    WHERE operation_date BETWEEN p_start_date AND p_end_date
    AND restricted_attempt = 'N';
    
    -- Get most common restriction reason
    BEGIN
        SELECT restriction_reason INTO v_common_reason
        FROM (
            SELECT restriction_reason, COUNT(*) as reason_count
            FROM audit_log
            WHERE operation_date BETWEEN p_start_date AND p_end_date
            AND restricted_attempt = 'Y'
            AND restriction_reason IS NOT NULL
            GROUP BY restriction_reason
            ORDER BY reason_count DESC
        ) WHERE ROWNUM = 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_common_reason := 'No restrictions in period';
    END;
    
    -- Display summary
    DBMS_OUTPUT.PUT_LINE('Total Operations: ' || v_total_attempts);
    DBMS_OUTPUT.PUT_LINE('  - Allowed: ' || v_allowed_count || ' (' || 
                        ROUND(v_allowed_count * 100.0 / NULLIF(v_total_attempts, 0), 1) || '%)');
    DBMS_OUTPUT.PUT_LINE('  - Restricted: ' || v_restricted_count || ' (' || 
                        ROUND(v_restricted_count * 100.0 / NULLIF(v_total_attempts, 0), 1) || '%)');
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('Most Common Restriction Reason: ' || v_common_reason);
    DBMS_OUTPUT.PUT_LINE('');
    
    -- Show breakdown by operation type
    DBMS_OUTPUT.PUT_LINE('Breakdown by Operation Type:');
    DBMS_OUTPUT.PUT_LINE('Type     | Total | Allowed | Restricted');
    DBMS_OUTPUT.PUT_LINE('---------|-------|---------|------------');
    
    FOR rec IN (
        SELECT operation_type,
               COUNT(*) as total,
               SUM(CASE WHEN restricted_attempt = 'N' THEN 1 ELSE 0 END) as allowed,
               SUM(CASE WHEN restricted_attempt = 'Y' THEN 1 ELSE 0 END) as restricted
        FROM audit_log
        WHERE operation_date BETWEEN p_start_date AND p_end_date
        GROUP BY operation_type
        ORDER BY operation_type
    ) LOOP
        DBMS_OUTPUT.PUT_LINE(
            RPAD(rec.operation_type, 9) || '| ' ||
            LPAD(rec.total, 6) || ' | ' ||
            LPAD(rec.allowed, 7) || ' | ' ||
            LPAD(rec.restricted, 10)
        );
    END LOOP;
    
    DBMS_OUTPUT.PUT_LINE('============================================');
    
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error generating audit summary: ' || SQLERRM);
END generate_audit_summary;
/

-- Display setup confirmation
BEGIN
    DBMS_OUTPUT.PUT_LINE('============================================');
    DBMS_OUTPUT.PUT_LINE('PHASE VII: AUDIT TABLES COMPLETE');
    DBMS_OUTPUT.PUT_LINE('============================================');
    DBMS_OUTPUT.PUT_LINE('Tables created:');
    DBMS_OUTPUT.PUT_LINE('  - AUDIT_LOG: Audit trail table');
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('Functions/Procedures created:');
    DBMS_OUTPUT.PUT_LINE('  1. log_audit_entry - Logs audit records');
    DBMS_OUTPUT.PUT_LINE('  2. generate_audit_summary - Generates reports');
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('View created:');
    DBMS_OUTPUT.PUT_LINE('  - AUDIT_REPORT: Easy audit querying');
    DBMS_OUTPUT.PUT_LINE('============================================');
END;
/