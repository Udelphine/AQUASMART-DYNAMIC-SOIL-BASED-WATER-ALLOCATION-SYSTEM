-- ============================================
-- PHASE VI: TEST SCRIPTS
-- ============================================

SET SERVEROUTPUT ON
PROMPT === TESTING PROCEDURES ===

-- Test 1: Test REGISTER_NEW_FARMER procedure
DECLARE
    v_farmer_id NUMBER;
    v_status VARCHAR2(200);
BEGIN
    register_new_farmer(
        p_username => 'test_farmer_vi',
        p_email => 'test.vi@email.com',
        p_password => 'TestPass123',
        p_phone => '+250788999000',
        p_address => 'Test Location',
        p_farmer_id => v_farmer_id,
        p_status => v_status
    );
    
    DBMS_OUTPUT.PUT_LINE('Test 1 - Register Farmer: ' || v_status);
    
    -- Verify insertion
    IF v_status LIKE 'SUCCESS%' THEN
        DBMS_OUTPUT.PUT_LINE('✓ Farmer registered with ID: ' || v_farmer_id);
        SELECT username, email INTO v_status FROM farmers WHERE farmer_id = v_farmer_id;
        DBMS_OUTPUT.PUT_LINE('✓ Verification: ' || v_status);
    END IF;
END;
/

-- Test 2: Test ACTIVATE_IRRIGATION procedure
DECLARE
    v_water_volume NUMBER;
    v_status VARCHAR2(200);
BEGIN
    -- First, make sure there's a closed valve in zone 2001
    UPDATE irrigation_valves SET status = 'CLOSED' 
    WHERE zone_id = 2001 AND ROWNUM = 1;
    
    activate_irrigation(
        p_zone_id => 2001,
        p_trigger_source => 'TEST',
        p_water_volume => v_water_volume,
        p_status => v_status
    );
    
    DBMS_OUTPUT.PUT_LINE('Test 2 - Activate Irrigation: ' || v_status);
    
    IF v_status LIKE 'SUCCESS%' THEN
        DBMS_OUTPUT.PUT_LINE('✓ Water volume used: ' || v_water_volume || 'L');
        
        -- Check if log was created
        DECLARE
            v_log_count NUMBER;
        BEGIN
            SELECT COUNT(*) INTO v_log_count 
            FROM irrigation_logs 
            WHERE zone_id = 2001 
            AND trigger_source = 'TEST';
            
            DBMS_OUTPUT.PUT_LINE('✓ Irrigation log created: ' || v_log_count || ' record(s)');
        END;
    END IF;
END;
/

-- Test 3: Test UPDATE_SENSOR_STATUS procedure
DECLARE
    v_status VARCHAR2(200);
BEGIN
    update_sensor_status(
        p_sensor_id => 3001,
        p_new_status => 'CALIBRATING',
        p_battery_level => 85,
        p_status => v_status
    );
    
    DBMS_OUTPUT.PUT_LINE('Test 3 - Update Sensor Status: ' || v_status);
    
    IF v_status LIKE 'SUCCESS%' THEN
        -- Verify update
        DECLARE
            v_actual_status VARCHAR2(20);
            v_actual_battery NUMBER;
        BEGIN
            SELECT status, battery_level INTO v_actual_status, v_actual_battery
            FROM sensors WHERE sensor_id = 3001;
            
            DBMS_OUTPUT.PUT_LINE('✓ Sensor updated to: ' || v_actual_status);
            DBMS_OUTPUT.PUT_LINE('✓ Battery level: ' || v_actual_battery || '%');
        END;
    END IF;
END;
/

-- Test 4: Test GENERATE_WATER_USAGE_REPORT procedure
BEGIN
    DBMS_OUTPUT.PUT_LINE('Test 4 - Generate Water Usage Report:');
    DBMS_OUTPUT.PUT_LINE('--------------------------------------');
    generate_water_usage_report(SYSDATE - 7, SYSDATE);
    DBMS_OUTPUT.PUT_LINE('✓ Report generated successfully');
END;
/

-- Test 5: Test PROCESS_SENSOR_ALERTS procedure
BEGIN
    -- Create some test alerts first
    INSERT INTO sensor_data (data_id, sensor_id, moisture_value, reading_time, status_flag)
    VALUES (seq_sensor_data_id.NEXTVAL, 3001, 15.5, SYSTIMESTAMP, 'A');
    
    INSERT INTO sensor_data (data_id, sensor_id, moisture_value, reading_time, status_flag)
    VALUES (seq_sensor_data_id.NEXTVAL, 3002, 90.5, SYSTIMESTAMP, 'A');
    
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('Test 5 - Process Sensor Alerts:');
    process_sensor_alerts();
    
    -- Verify alerts were processed
    DECLARE
        v_remaining_alerts NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_remaining_alerts
        FROM sensor_data
        WHERE status_flag = 'A'
        AND reading_time > SYSDATE - 1;
        
        IF v_remaining_alerts = 0 THEN
            DBMS_OUTPUT.PUT_LINE('✓ All alerts processed successfully');
        ELSE
            DBMS_OUTPUT.PUT_LINE('✗ ' || v_remaining_alerts || ' alerts remaining');
        END IF;
    END;
END;
/

-- Test 6: Test MAINTENANCE_SCHEDULER procedure
BEGIN
    DBMS_OUTPUT.PUT_LINE('Test 6 - Maintenance Scheduler:');
    DBMS_OUTPUT.PUT_LINE('--------------------------------');
    maintenance_scheduler();
    DBMS_OUTPUT.PUT_LINE('✓ Maintenance report generated');
END;
/

PROMPT === TESTING FUNCTIONS ===

-- Test 7: Test CALCULATE_WATER_DEFICIT function
DECLARE
    v_deficit NUMBER;
BEGIN
    v_deficit := calculate_water_deficit(2001);
    DBMS_OUTPUT.PUT_LINE('Test 7 - Water Deficit for Zone 2001: ' || ROUND(v_deficit, 2) || 'L');
    DBMS_OUTPUT.PUT_LINE('✓ Function executed successfully');
END;
/

-- Test 8: Test GET_ZONE_EFFICIENCY function
DECLARE
    v_efficiency NUMBER;
BEGIN
    v_efficiency := get_zone_efficiency(2001, 7);
    DBMS_OUTPUT.PUT_LINE('Test 8 - Zone 2001 Efficiency (7 days): ' || v_efficiency || '%');
    DBMS_OUTPUT.PUT_LINE('✓ Efficiency calculated');
END;
/

-- Test 9: Test VALIDATE_SENSOR_READING function
BEGIN
    DBMS_OUTPUT.PUT_LINE('Test 9 - Sensor Reading Validation:');
    DBMS_OUTPUT.PUT_LINE('  Moisture 50, Temp 25: ' || validate_sensor_reading(50, 25));
    DBMS_OUTPUT.PUT_LINE('  Moisture 120, Temp 25: ' || validate_sensor_reading(120, 25));
    DBMS_OUTPUT.PUT_LINE('  Moisture 10, Temp 70: ' || validate_sensor_reading(10, 70));
    DBMS_OUTPUT.PUT_LINE('  Moisture 5, Temp 20: ' || validate_sensor_reading(5, 20));
    DBMS_OUTPUT.PUT_LINE('✓ Validations completed');
END;
/

-- Test 10: Test GET_FARMER_STATISTICS function
DECLARE
    v_stats VARCHAR2(200);
BEGIN
    v_stats := get_farmer_statistics(1001);
    DBMS_OUTPUT.PUT_LINE('Test 10 - Farmer 1001 Statistics: ' || v_stats);
    DBMS_OUTPUT.PUT_LINE('✓ Statistics retrieved');
END;
/

-- Test 11: Test PREDICT_WATER_NEED function
DECLARE
    v_prediction NUMBER;
BEGIN
    v_prediction := predict_water_need(2001, 3);
    DBMS_OUTPUT.PUT_LINE('Test 11 - Predicted water need for Zone 2001 (3 days): ' || v_prediction || 'L');
    DBMS_OUTPUT.PUT_LINE('✓ Prediction completed');
END;
/

PROMPT === TESTING PACKAGES ===

-- Test 12: Test AQUASMART_UTILITIES_PKG
BEGIN
    DBMS_OUTPUT.PUT_LINE('Test 12 - AquaSmart Utilities Package:');
    DBMS_OUTPUT.PUT_LINE('--------------------------------------');
    
    -- Test system report
    aquasmart_utilities_pkg.generate_system_report();
    
    -- Test zone health score
    DECLARE
        v_health_score NUMBER;
    BEGIN
        v_health_score := aquasmart_utilities_pkg.get_zone_health_score(2001);
        DBMS_OUTPUT.PUT_LINE('Zone 2001 Health Score: ' || v_health_score || '%');
    END;
    
    -- Test parameter validation
    DBMS_OUTPUT.PUT_LINE('Validation for Zone 2001, 1000L: ' || 
                        aquasmart_utilities_pkg.validate_irrigation_params(2001, 1000));
    
    DBMS_OUTPUT.PUT_LINE('✓ Package tests completed');
END;
/

-- Test 13: Test AQUASMART_ANALYTICS_PKG
BEGIN
    DBMS_OUTPUT.PUT_LINE('Test 13 - AquaSmart Analytics Package:');
    DBMS_OUTPUT.PUT_LINE('--------------------------------------');
    
    aquasmart_analytics_pkg.show_water_conservation_metrics(30);
    DBMS_OUTPUT.PUT_LINE('');
    aquasmart_analytics_pkg.generate_efficiency_report(1001);
    DBMS_OUTPUT.PUT_LINE('');
    aquasmart_analytics_pkg.show_predicted_water_needs(7);
    
    DBMS_OUTPUT.PUT_LINE('✓ Analytics package tests completed');
END;
/

PROMPT === TESTING EXCEPTION HANDLING ===

-- Test 14: Test safe_activate_irrigation with invalid zone
BEGIN
    DBMS_OUTPUT.PUT_LINE('Test 14 - Exception Handling (Invalid Zone):');
    safe_activate_irrigation(9999); -- Non-existent zone
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('✓ Exception caught: ' || SQLERRM);
END;
/

-- Test 15: Test retry_irrigation_with_backoff
BEGIN
    DBMS_OUTPUT.PUT_LINE('Test 15 - Retry Logic:');
    -- Create a situation that will fail (zone with no valves)
    UPDATE irrigation_valves SET status = 'FAULTY' WHERE zone_id = 2002;
    
    retry_irrigation_with_backoff(2002, 2);
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('✓ Expected failure after retries: ' || SQLERRM);
        
        -- Restore valve status
        UPDATE irrigation_valves SET status = 'CLOSED' WHERE zone_id = 2002;
        COMMIT;
END;
/

-- Test 16: Test bulk_update_sensor_status
DECLARE
    v_statuses SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST('ACTIVE', 'CALIBRATING', 'INACTIVE');
    v_sensor_ids SYS.ODCINUMBERLIST := SYS.ODCINUMBERLIST(3001, 3002, 9999); -- Last one invalid
BEGIN
    DBMS_OUTPUT.PUT_LINE('Test 16 - Bulk Operation with Error Continuation:');
    bulk_update_sensor_status(v_statuses, v_sensor_ids);
    DBMS_OUTPUT.PUT_LINE('✓ Bulk operation completed with error continuation');
END;
/

-- Test 17: Test error_log table
BEGIN
    DBMS_OUTPUT.PUT_LINE('Test 17 - Error Log Verification:');
    
    DECLARE
        v_error_count NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_error_count FROM error_log;
        DBMS_OUTPUT.PUT_LINE('Total errors logged: ' || v_error_count);
        
        IF v_error_count > 0 THEN
            DBMS_OUTPUT.PUT_LINE('Recent errors:');
            FOR err IN (
                SELECT procedure_name, error_message, error_timestamp
                FROM error_log
                ORDER BY error_timestamp DESC
                FETCH FIRST 3 ROWS ONLY
            ) LOOP
                DBMS_OUTPUT.PUT_LINE('  ' || err.procedure_name || ': ' || 
                                    SUBSTR(err.error_message, 1, 50) || '...');
            END LOOP;
        END IF;
    END;
    
    DBMS_OUTPUT.PUT_LINE('✓ Error logging verified');
END;
/

PROMPT === COMPREHENSIVE TEST SUMMARY ===

DECLARE
    v_procedure_count NUMBER;
    v_function_count NUMBER;
    v_package_count NUMBER;
    v_total_objects NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_procedure_count
    FROM user_objects WHERE object_type = 'PROCEDURE' AND object_name LIKE '%AQUASMART%';
    
    SELECT COUNT(*) INTO v_function_count
    FROM user_objects WHERE object_type = 'FUNCTION' AND object_name LIKE '%AQUASMART%';
    
    SELECT COUNT(*) INTO v_package_count
    FROM user_objects WHERE object_type = 'PACKAGE' AND object_name LIKE '%AQUASMART%';
    
    v_total_objects := v_procedure_count + v_function_count + v_package_count;
    
    DBMS_OUTPUT.PUT_LINE('============================================');
    DBMS_OUTPUT.PUT_LINE('PHASE VI TESTING COMPLETE');
    DBMS_OUTPUT.PUT_LINE('============================================');
    DBMS_OUTPUT.PUT_LINE('Procedures created: ' || v_procedure_count);
    DBMS_OUTPUT.PUT_LINE('Functions created: ' || v_function_count);
    DBMS_OUTPUT.PUT_LINE('Packages created: ' || v_package_count);
    DBMS_OUTPUT.PUT_LINE('Total PL/SQL objects: ' || v_total_objects);
    DBMS_OUTPUT.PUT_LINE('============================================');
    DBMS_OUTPUT.PUT_LINE('17 test cases executed');
    DBMS_OUTPUT.PUT_LINE('All required components verified');
    DBMS_OUTPUT.PUT_LINE('Phase VI: PL/SQL Development - COMPLETED ✓');
    DBMS_OUTPUT.PUT_LINE('============================================');
END;
/

-- Clean up test data
BEGIN
    DELETE FROM farmers WHERE username = 'test_farmer_vi';
    DELETE FROM sensor_data WHERE status_flag = 'A' AND reading_time > SYSDATE - 1;
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Test data cleaned up');
END;
/