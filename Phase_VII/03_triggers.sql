-- ============================================
-- PHASE VII: TRIGGERS
-- AquaSmart Irrigation System
-- Student: Uwineza Delphine (ID: 27897)
-- ============================================

-- 1. SIMPLE TRIGGERS (For demonstration)

-- INSERT Trigger
CREATE OR REPLACE TRIGGER trg_employees_insert_restrict
BEFORE INSERT ON employees
FOR EACH ROW
DECLARE
    v_restricted BOOLEAN;
    v_reason VARCHAR2(200);
BEGIN
    v_restricted := is_operation_restricted(:NEW.username);
    
    IF v_restricted THEN
        IF is_weekday() THEN
            v_reason := 'Weekday restriction (Monday-Friday)';
        ELSE
            v_reason := 'Public holiday restriction';
        END IF;
        
        -- Log the attempt
        log_audit_entry(
            'EMPLOYEES', 'INSERT', :NEW.username, 'Y', 
            v_reason, NULL, :NEW.username || ' - ' || :NEW.full_name
        );
        
        RAISE_APPLICATION_ERROR(-20001, 
            'INSERT not allowed for ' || :NEW.username || 
            ' on ' || TO_CHAR(SYSDATE, 'Day') || '. Reason: ' || v_reason);
    ELSE
        -- Log allowed operation
        log_audit_entry(
            'EMPLOYEES', 'INSERT', :NEW.username, 'N',
            NULL, NULL, :NEW.username || ' - ' || :NEW.full_name
        );
    END IF;
END;
/

-- UPDATE Trigger
CREATE OR REPLACE TRIGGER trg_employees_update_restrict
BEFORE UPDATE ON employees
FOR EACH ROW
DECLARE
    v_restricted BOOLEAN;
    v_reason VARCHAR2(200);
BEGIN
    v_restricted := is_operation_restricted(:OLD.username);
    
    IF v_restricted THEN
        IF is_weekday() THEN
            v_reason := 'Weekday restriction (Monday-Friday)';
        ELSE
            v_reason := 'Public holiday restriction';
        END IF;
        
        -- Log the attempt
        log_audit_entry(
            'EMPLOYEES', 'UPDATE', :OLD.username, 'Y',
            v_reason, 
            :OLD.username || ' - ' || :OLD.full_name,
            :NEW.username || ' - ' || :NEW.full_name
        );
        
        RAISE_APPLICATION_ERROR(-20002, 
            'UPDATE not allowed for ' || :OLD.username || 
            '. Reason: ' || v_reason);
    ELSE
        -- Log allowed operation
        log_audit_entry(
            'EMPLOYEES', 'UPDATE', :OLD.username, 'N',
            NULL,
            :OLD.username || ' - ' || :OLD.full_name,
            :NEW.username || ' - ' || :NEW.full_name
        );
    END IF;
END;
/

-- DELETE Trigger
CREATE OR REPLACE TRIGGER trg_employees_delete_restrict
BEFORE DELETE ON employees
FOR EACH ROW
DECLARE
    v_restricted BOOLEAN;
    v_reason VARCHAR2(200);
BEGIN
    v_restricted := is_operation_restricted(:OLD.username);
    
    IF v_restricted THEN
        IF is_weekday() THEN
            v_reason := 'Weekday restriction (Monday-Friday)';
        ELSE
            v_reason := 'Public holiday restriction';
        END IF;
        
        -- Log the attempt
        log_audit_entry(
            'EMPLOYEES', 'DELETE', :OLD.username, 'Y',
            v_reason,
            :OLD.username || ' - ' || :OLD.full_name,
            NULL
        );
        
        RAISE_APPLICATION_ERROR(-20003, 
            'DELETE not allowed for ' || :OLD.username || 
            '. Reason: ' || v_reason);
    ELSE
        -- Log allowed operation
        log_audit_entry(
            'EMPLOYEES', 'DELETE', :OLD.username, 'N',
            NULL,
            :OLD.username || ' - ' || :OLD.full_name,
            NULL
        );
    END IF;
END;
/

-- 2. COMPOUND TRIGGER (Recommended for production)
CREATE OR REPLACE TRIGGER trg_employees_compound
FOR INSERT OR UPDATE OR DELETE ON employees
COMPOUND TRIGGER

    TYPE t_audit_rec IS RECORD (
        username VARCHAR2(50),
        operation VARCHAR2(10),
        restricted CHAR(1),
        reason VARCHAR2(200),
        old_data VARCHAR2(500),
        new_data VARCHAR2(500)
    );
    
    TYPE t_audit_table IS TABLE OF t_audit_rec;
    g_audits t_audit_table := t_audit_table();

    BEFORE EACH ROW IS
        v_restricted BOOLEAN;
        v_reason VARCHAR2(200);
    BEGIN
        v_restricted := FALSE;
        
        -- Check restriction
        IF INSERTING THEN
            v_restricted := is_operation_restricted(:NEW.username);
        ELSE
            v_restricted := is_operation_restricted(:OLD.username);
        END IF;
        
        IF v_restricted THEN
            IF is_weekday() THEN
                v_reason := 'Weekday restriction';
            ELSE
                v_reason := 'Holiday restriction';
            END IF;
            
            -- Add to audit collection
            g_audits.EXTEND;
            g_audits(g_audits.LAST).username := 
                CASE WHEN INSERTING THEN :NEW.username ELSE :OLD.username END;
            g_audits(g_audits.LAST).operation := 
                CASE WHEN INSERTING THEN 'INSERT' 
                     WHEN UPDATING THEN 'UPDATE' 
                     ELSE 'DELETE' END;
            g_audits(g_audits.LAST).restricted := 'Y';
            g_audits(g_audits.LAST).reason := v_reason;
            
            -- Raise error
            IF INSERTING THEN
                RAISE_APPLICATION_ERROR(-20004, 'INSERT restricted: ' || v_reason);
            ELSIF UPDATING THEN
                RAISE_APPLICATION_ERROR(-20005, 'UPDATE restricted: ' || v_reason);
            ELSE
                RAISE_APPLICATION_ERROR(-20006, 'DELETE restricted: ' || v_reason);
            END IF;
        ELSE
            -- Add allowed operation
            g_audits.EXTEND;
            g_audits(g_audits.LAST).username := 
                CASE WHEN INSERTING THEN :NEW.username ELSE :OLD.username END;
            g_audits(g_audits.LAST).operation := 
                CASE WHEN INSERTING THEN 'INSERT' 
                     WHEN UPDATING THEN 'UPDATE' 
                     ELSE 'DELETE' END;
            g_audits(g_audits.LAST).restricted := 'N';
        END IF;
    END BEFORE EACH ROW;

    AFTER STATEMENT IS
    BEGIN
        -- Process all audits
        FOR i IN 1..g_audits.COUNT LOOP
            log_audit_entry(
                'EMPLOYEES',
                g_audits(i).operation,
                g_audits(i).username,
                g_audits(i).restricted,
                g_audits(i).reason,
                NULL,
                NULL
            );
        END LOOP;
        
        -- Clear collection
        g_audits.DELETE;
    END AFTER STATEMENT;
    
END trg_employees_compound;
/

-- Disable simple triggers (use compound trigger)
ALTER TRIGGER trg_employees_insert_restrict DISABLE;
ALTER TRIGGER trg_employees_update_restrict DISABLE;
ALTER TRIGGER trg_employees_delete_restrict DISABLE;

-- 3. TRIGGER FOR RELATED TABLES (Example)
CREATE TABLE employee_salary (
    salary_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    employee_id NUMBER REFERENCES employees(employee_id),
    salary NUMBER(10,2),
    effective_date DATE,
    created_date DATE DEFAULT SYSDATE
);

CREATE OR REPLACE TRIGGER trg_employee_salary_restrict
BEFORE INSERT OR UPDATE OR DELETE ON employee_salary
FOR EACH ROW
DECLARE
    v_username VARCHAR2(50);
    v_restricted BOOLEAN;
    v_reason VARCHAR2(200);
BEGIN
    -- Get username from employee_id
    IF INSERTING OR UPDATING THEN
        SELECT username INTO v_username 
        FROM employees 
        WHERE employee_id = :NEW.employee_id;
    ELSE
        SELECT username INTO v_username 
        FROM employees 
        WHERE employee_id = :OLD.employee_id;
    END IF;
    
    v_restricted := is_operation_restricted(v_username);
    
    IF v_restricted THEN
        IF is_weekday() THEN
            v_reason := 'Weekday restriction';
        ELSE
            v_reason := 'Holiday restriction';
        END IF;
        
        RAISE_APPLICATION_ERROR(-20007, 
            'Operation not allowed for ' || v_username || 
            '. Reason: ' || v_reason);
    END IF;
END;
/

-- Verification
BEGIN
    DBMS_OUTPUT.PUT_LINE('============================================');
    DBMS_OUTPUT.PUT_LINE('TRIGGERS CREATED SUCCESSFULLY');
    DBMS_OUTPUT.PUT_LINE('============================================');
    DBMS_OUTPUT.PUT_LINE('✓ 3 Simple triggers (disabled)');
    DBMS_OUTPUT.PUT_LINE('✓ 1 Compound trigger (active)');
    DBMS_OUTPUT.PUT_LINE('✓ 1 Related table trigger');
    DBMS_OUTPUT.PUT_LINE('============================================');
END;
/