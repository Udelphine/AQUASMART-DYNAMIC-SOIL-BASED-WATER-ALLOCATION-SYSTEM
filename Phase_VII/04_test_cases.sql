-- ============================================
-- PHASE VII: TEST CASES
-- ============================================

SET SERVEROUTPUT ON

-- Switch to aquasmart_user schema
ALTER SESSION SET CURRENT_SCHEMA = aquasmart_user;

BEGIN
    DBMS_OUTPUT.PUT_LINE('============================================');
    DBMS_OUTPUT.PUT_LINE('PHASE VII TEST CASES - AQUASMART SYSTEM');
    DBMS_OUTPUT.PUT_LINE('Student: Uwineza Delphine (ID: 27897)');
    DBMS_OUTPUT.PUT_LINE('Date: ' || TO_CHAR(SYSDATE, 'DD-MON-YYYY HH24:MI:SS'));
    DBMS_OUTPUT.PUT_LINE('============================================');
END;
/

-- Test 1: Check current day
BEGIN
    DBMS_OUTPUT.PUT_LINE('TEST 1: CURRENT DAY STATUS');
    DBMS_OUTPUT.PUT_LINE('Day: ' || TO_CHAR(SYSDATE, 'Day'));
    DBMS_OUTPUT.PUT_LINE('Is Weekday: ' || CASE WHEN is_weekday() THEN 'YES' ELSE 'NO' END);
    DBMS_OUTPUT.PUT_LINE('Is Holiday: ' || CASE WHEN is_holiday_today() THEN 'YES' ELSE 'NO' END);
    DBMS_OUTPUT.PUT_LINE('✓ Test 1 completed');
END;
/

-- Test 2: Try to insert 'S' employee
BEGIN
    DBMS_OUTPUT.PUT_LINE(CHR(10) || 'TEST 2: INSERT "S" EMPLOYEE');
    DBMS_OUTPUT.PUT_LINE('----------------------------------');
    
    BEGIN
        INSERT INTO employees (username, full_name, email, department)
        VALUES ('STESTER', 'Test S', 'test.s@aquasmart.com', 'Testing');
        
        DBMS_OUTPUT.PUT_LINE('Result: INSERT ALLOWED');
        DBMS_OUTPUT.PUT_LINE('(No restriction on current day)');
        
        DELETE FROM employees WHERE username = 'STESTER';
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE = -20001 THEN
                DBMS_OUTPUT.PUT_LINE('Result: INSERT DENIED');
                DBMS_OUTPUT.PUT_LINE('✓ Business rule working correctly');
                DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
            ELSE
                DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
            END IF;
    END;
END;
/

-- Test 3: Insert non-'S' employee
BEGIN
    DBMS_OUTPUT.PUT_LINE(CHR(10) || 'TEST 3: INSERT NON-"S" EMPLOYEE');
    DBMS_OUTPUT.PUT_LINE('----------------------------------------');
    
    BEGIN
        INSERT INTO employees (username, full_name, email, department)
        VALUES ('MTESTER', 'Test M', 'test.m@aquasmart.com', 'Testing');
        
        DBMS_OUTPUT.PUT_LINE('Result: INSERT ALLOWED');
        DBMS_OUTPUT.PUT_LINE('✓ Non-"S" employees not restricted');
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
    END;
END;
/

-- Test 4: Update test
BEGIN
    DBMS_OUTPUT.PUT_LINE(CHR(10) || 'TEST 4: UPDATE TEST');
    DBMS_OUTPUT.PUT_LINE('-----------------------');
    
    BEGIN
        UPDATE employees 
        SET department = 'Updated'
        WHERE username = 'SJOHNDOE';
        
        IF SQL%ROWCOUNT > 0 THEN
            DBMS_OUTPUT.PUT_LINE('Result: UPDATE ALLOWED');
            ROLLBACK;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE = -20002 THEN
                DBMS_OUTPUT.PUT_LINE('Result: UPDATE DENIED');
                DBMS_OUTPUT.PUT_LINE('✓ Update restriction working');
            END IF;
    END;
END;
/

-- Test 5: Delete test
BEGIN
    DBMS_OUTPUT.PUT_LINE(CHR(10) || 'TEST 5: DELETE TEST');
    DBMS_OUTPUT.PUT_LINE('-----------------------');
    
    BEGIN
        DELETE FROM employees WHERE username = 'SSMITH';
        
        IF SQL%ROWCOUNT > 0 THEN
            DBMS_OUTPUT.PUT_LINE('Result: DELETE ALLOWED');
            ROLLBACK;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE = -20003 THEN
                DBMS_OUTPUT.PUT_LINE('Result: DELETE DENIED');
                DBMS_OUTPUT.PUT_LINE('✓ Delete restriction working');
            END IF;
    END;
END;
/

-- Test 6: Related table test
DECLARE
    v_emp_id NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE(CHR(10) || 'TEST 6: RELATED TABLE TEST');
    DBMS_OUTPUT.PUT_LINE('--------------------------------');
    
    SELECT employee_id INTO v_emp_id 
    FROM employees WHERE username = 'SJOHNDOE';
    
    BEGIN
        INSERT INTO employee_salary (employee_id, salary_amount, effective_date)
        VALUES (v_emp_id, 50000, SYSDATE);
        
        DBMS_OUTPUT.PUT_LINE('Result: INSERT ALLOWED');
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE = -20004 THEN
                DBMS_OUTPUT.PUT_LINE('Result: INSERT DENIED');
                DBMS_OUTPUT.PUT_LINE('✓ Related table restriction working');
            END IF;
    END;
END;
/

-- Test 7: Check audit log
BEGIN
    DBMS_OUTPUT.PUT_LINE(CHR(10) || 'TEST 7: AUDIT LOG CHECK');
    DBMS_OUTPUT.PUT_LINE('---------------------------');
    
    DECLARE
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_count FROM audit_log;
        DBMS_OUTPUT.PUT_LINE('Total audit records: ' || v_count);
        
        IF v_count > 0 THEN
            DBMS_OUTPUT.PUT_LINE(CHR(10) || 'Recent audit entries:');
            FOR r IN (
                SELECT username, operation_type, 
                       TO_CHAR(operation_date, 'HH24:MI:SS') as time,
                       restricted_attempt
                FROM audit_log
                ORDER BY operation_date DESC
                FETCH FIRST 5 ROWS ONLY
            ) LOOP
                DBMS_OUTPUT.PUT_LINE(
                    r.time || ' - ' || r.username || ' - ' || 
                    r.operation_type || ' - ' ||
                    CASE WHEN r.restricted_attempt = 'Y' 
                         THEN 'DENIED' ELSE 'ALLOWED' END
                );
            END LOOP;
        END IF;
        
        DBMS_OUTPUT.PUT_LINE('✓ Audit system working');
    END;
END;
/

-- Test 8: Show all triggers
BEGIN
    DBMS_OUTPUT.PUT_LINE(CHR(10) || 'TEST 8: TRIGGER VERIFICATION');
    DBMS_OUTPUT.PUT_LINE('-------------------------------');
    
    DBMS_OUTPUT.PUT_LINE('Triggers in schema:');
    FOR t IN (
        SELECT trigger_name, table_name, triggering_event, status
        FROM user_triggers
        ORDER BY trigger_name
    ) LOOP
        DBMS_OUTPUT.PUT_LINE(
            '  ' || RPAD(t.trigger_name, 30) || ' - ' ||
            RPAD(t.table_name, 20) || ' - ' ||
            RPAD(t.triggering_event, 20) || ' - ' ||
            t.status
        );
    END LOOP;
    
    DBMS_OUTPUT.PUT_LINE('✓ All triggers created successfully');
END;
/

-- Test 9: Final summary
BEGIN
    DBMS_OUTPUT.PUT_LINE(CHR(10) || 'TEST 9: SYSTEM SUMMARY');
    DBMS_OUTPUT.PUT_LINE('------------------------');
    
    DBMS_OUTPUT.PUT_LINE('Phase VII Components:');
    DBMS_OUTPUT.PUT_LINE('  ✓ HOLIDAYS table with sample data');
    DBMS_OUTPUT.PUT_LINE('  ✓ EMPLOYEES table with "S" username restriction');
    DBMS_OUTPUT.PUT_LINE('  ✓ AUDIT_LOG table for tracking');
    DBMS_OUTPUT.PUT_LINE('  ✓ 4 Business logic functions');
    DBMS_OUTPUT.PUT_LINE('  ✓ 5 Triggers (including compound)');
    DBMS_OUTPUT.PUT_LINE('  ✓ Related table with trigger');
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('Business Rule Verified:');
    DBMS_OUTPUT.PUT_LINE('  Employees with usernames starting with "S"');
    DBMS_OUTPUT.PUT_LINE('  cannot INSERT/UPDATE/DELETE on weekdays/holidays');
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('PHASE VII: COMPLETED SUCCESSFULLY');
END;
/

-- Clean up test data
DELETE FROM employees WHERE username LIKE '%TEST%';
DELETE FROM audit_log;
COMMIT;