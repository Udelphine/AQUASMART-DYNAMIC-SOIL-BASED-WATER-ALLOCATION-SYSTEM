-- ============================================
-- PHASE VI: EXCEPTION HANDLING
-- ============================================

-- Example 1: Comprehensive exception handling in irrigation procedure
CREATE OR REPLACE PROCEDURE safe_activate_irrigation(
    p_zone_id IN NUMBER,
    p_trigger_source IN VARCHAR2 DEFAULT 'MANUAL'
) AS
    v_water_volume NUMBER;
    v_status VARCHAR2(500);
    v_error_code NUMBER;
    v_error_msg VARCHAR2(500);
    
    -- Custom exceptions
    zone_not_found EXCEPTION;
    no_active_valve EXCEPTION;
    insufficient_moisture_data EXCEPTION;
    
    PRAGMA EXCEPTION_INIT(zone_not_found, -20001);
    PRAGMA EXCEPTION_INIT(no_active_valve, -20002);
    PRAGMA EXCEPTION_INIT(insufficient_moisture_data, -20003);
BEGIN
    DBMS_OUTPUT.PUT_LINE('Starting irrigation procedure for zone: ' || p_zone_id);
    
    -- Validate zone exists and is active
    DECLARE
        v_zone_count NUMBER;
        v_zone_status VARCHAR2(20);
    BEGIN
        SELECT COUNT(*), MAX(status) INTO v_zone_count, v_zone_status
        FROM farm_zones WHERE zone_id = p_zone_id;
        
        IF v_zone_count = 0 THEN
            RAISE zone_not_found;
        ELSIF v_zone_status != 'ACTIVE' THEN
            RAISE_APPLICATION_ERROR(-20004, 'Zone ' || p_zone_id || ' is not active. Status: ' || v_zone_status);
        END IF;
    END;
    
    -- Check for active valves
    DECLARE
        v_valve_count NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_valve_count
        FROM irrigation_valves
        WHERE zone_id = p_zone_id
        AND status IN ('CLOSED', 'OPEN');
        
        IF v_valve_count = 0 THEN
            RAISE no_active_valve;
        END IF;
    END;
    
    -- Check for recent moisture data
    DECLARE
        v_recent_readings NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_recent_readings
        FROM sensor_data sd
        JOIN sensors s ON sd.sensor_id = s.sensor_id
        WHERE s.zone_id = p_zone_id
        AND sd.reading_time > SYSDATE - 1;
        
        IF v_recent_readings = 0 THEN
            RAISE insufficient_moisture_data;
        END IF;
    END;
    
    -- Call the main irrigation procedure
    activate_irrigation(
        p_zone_id => p_zone_id,
        p_trigger_source => p_trigger_source,
        p_water_volume => v_water_volume,
        p_status => v_status
    );
    
    -- Log successful execution
    INSERT INTO irrigation_logs (
        log_id, valve_id, zone_id, trigger_source,
        start_time, status, notes
    ) VALUES (
        seq_irrigation_logs_id.NEXTVAL,
        NULL, -- Will be filled by activate_irrigation
        p_zone_id,
        'SYSTEM_AUDIT',
        SYSTIMESTAMP,
        'AUDIT',
        'Safe irrigation procedure completed: ' || v_status
    );
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('SUCCESS: ' || v_status);
    
EXCEPTION
    WHEN zone_not_found THEN
        v_error_msg := 'Zone ' || p_zone_id || ' not found in database';
        DBMS_OUTPUT.PUT_LINE('ERROR: ' || v_error_msg);
        log_error('safe_activate_irrigation', v_error_msg, p_zone_id);
        
    WHEN no_active_valve THEN
        v_error_msg := 'No active valves found for zone ' || p_zone_id;
        DBMS_OUTPUT.PUT_LINE('ERROR: ' || v_error_msg);
        log_error('safe_activate_irrigation', v_error_msg, p_zone_id);
        
    WHEN insufficient_moisture_data THEN
        v_error_msg := 'Insufficient moisture data for zone ' || p_zone_id;
        DBMS_OUTPUT.PUT_LINE('WARNING: ' || v_error_msg);
        -- Continue anyway with default values
        
    WHEN OTHERS THEN
        v_error_code := SQLCODE;
        v_error_msg := SQLERRM;
        
        DBMS_OUTPUT.PUT_LINE('UNEXPECTED ERROR [' || v_error_code || ']: ' || v_error_msg);
        DBMS_OUTPUT.PUT_LINE('Backtrace: ' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        DBMS_OUTPUT.PUT_LINE('Call stack: ' || DBMS_UTILITY.FORMAT_CALL_STACK);
        
        -- Log detailed error
        log_error('safe_activate_irrigation', v_error_msg, p_zone_id, v_error_code);
        
        ROLLBACK;
        RAISE;
END safe_activate_irrigation;
/

-- Error logging table and procedure
CREATE TABLE error_log (
    error_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    procedure_name VARCHAR2(100),
    error_message VARCHAR2(1000),
    zone_id NUMBER,
    error_code NUMBER,
    error_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP,
    additional_info CLOB
);

CREATE OR REPLACE PROCEDURE log_error(
    p_procedure_name IN VARCHAR2,
    p_error_message IN VARCHAR2,
    p_zone_id IN NUMBER DEFAULT NULL,
    p_error_code IN NUMBER DEFAULT NULL,
    p_additional_info IN CLOB DEFAULT NULL
) AS
    PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
    INSERT INTO error_log (
        procedure_name, error_message, zone_id, 
        error_code, additional_info
    ) VALUES (
        p_procedure_name, p_error_message, p_zone_id,
        p_error_code, p_additional_info
    );
    
    COMMIT;
END log_error;
/

-- Example 2: Retry logic with exponential backoff
CREATE OR REPLACE PROCEDURE retry_irrigation_with_backoff(
    p_zone_id IN NUMBER,
    p_max_retries IN NUMBER DEFAULT 3
) AS
    v_retry_count NUMBER := 0;
    v_success BOOLEAN := FALSE;
    v_wait_seconds NUMBER;
    v_status VARCHAR2(500);
    v_water_volume NUMBER;
BEGIN
    WHILE v_retry_count < p_max_retries AND NOT v_success LOOP
        BEGIN
            v_retry_count := v_retry_count + 1;
            
            IF v_retry_count > 1 THEN
                -- Exponential backoff: 2, 4, 8 seconds
                v_wait_seconds := POWER(2, v_retry_count - 1);
                DBMS_OUTPUT.PUT_LINE('Retry ' || v_retry_count || ': Waiting ' || v_wait_seconds || ' seconds');
                DBMS_LOCK.SLEEP(v_wait_seconds);
            END IF;
            
            DBMS_OUTPUT.PUT_LINE('Attempt ' || v_retry_count || ' for zone ' || p_zone_id);
            
            activate_irrigation(
                p_zone_id => p_zone_id,
                p_trigger_source => 'RETRY_' || v_retry_count,
                p_water_volume => v_water_volume,
                p_status => v_status
            );
            
            IF v_status LIKE 'SUCCESS%' THEN
                v_success := TRUE;
                DBMS_OUTPUT.PUT_LINE('SUCCESS on attempt ' || v_retry_count || ': ' || v_status);
            ELSE
                DBMS_OUTPUT.PUT_LINE('FAILED attempt ' || v_retry_count || ': ' || v_status);
                
                -- Log failure
                log_error('retry_irrigation_with_backoff', 
                         'Attempt ' || v_retry_count || ' failed: ' || v_status,
                         p_zone_id);
            END IF;
            
        EXCEPTION
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('EXCEPTION on attempt ' || v_retry_count || ': ' || SQLERRM);
                log_error('retry_irrigation_with_backoff', 
                         'Attempt ' || v_retry_count || ' exception: ' || SQLERRM,
                         p_zone_id, SQLCODE);
        END;
    END LOOP;
    
    IF NOT v_success THEN
        DBMS_OUTPUT.PUT_LINE('FAILED: All ' || p_max_retries || ' attempts failed for zone ' || p_zone_id);
        RAISE_APPLICATION_ERROR(-20010, 'Irrigation failed after ' || p_max_retries || ' retries');
    END IF;
END retry_irrigation_with_backoff;
/

-- Example 3: Bulk operation with error continuation
CREATE OR REPLACE PROCEDURE bulk_update_sensor_status(
    p_status_array IN SYS.ODCIVARCHAR2LIST,
    p_sensor_ids IN SYS.ODCINUMBERLIST
) AS
    v_errors NUMBER := 0;
    v_updated NUMBER := 0;
    v_error_details VARCHAR2(4000);
BEGIN
    DBMS_OUTPUT.PUT_LINE('Starting bulk update of ' || p_sensor_ids.COUNT || ' sensors');
    
    FOR i IN 1..p_sensor_ids.COUNT LOOP
        BEGIN
            UPDATE sensors 
            SET status = p_status_array(i),
                last_maintenance_date = CASE 
                    WHEN p_status_array(i) = 'CALIBRATING' THEN SYSDATE
                    ELSE last_maintenance_date
                END
            WHERE sensor_id = p_sensor_ids(i);
            
            IF SQL%ROWCOUNT = 1 THEN
                v_updated := v_updated + 1;
            ELSE
                v_errors := v_errors + 1;
                v_error_details := v_error_details || 'Sensor ' || p_sensor_ids(i) || ' not found; ';
            END IF;
            
        EXCEPTION
            WHEN OTHERS THEN
                v_errors := v_errors + 1;
                v_error_details := v_error_details || 'Sensor ' || p_sensor_ids(i) || ': ' || SQLERRM || '; ';
                
                -- Log individual error but continue
                log_error('bulk_update_sensor_status', 
                         'Sensor ' || p_sensor_ids(i) || ': ' || SQLERRM,
                         NULL, SQLCODE);
        END;
    END LOOP;
    
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('Bulk update completed:');
    DBMS_OUTPUT.PUT_LINE('  Successfully updated: ' || v_updated);
    DBMS_OUTPUT.PUT_LINE('  Errors: ' || v_errors);
    
    IF v_errors > 0 THEN
        DBMS_OUTPUT.PUT_LINE('Error details: ' || SUBSTR(v_error_details, 1, 1000));
    END IF;
    
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('FATAL ERROR in bulk update: ' || SQLERRM);
        ROLLBACK;
        RAISE;
END bulk_update_sensor_status;
/

-- Example 4: Validate and clean sensor data
CREATE OR REPLACE PROCEDURE clean_sensor_data(
    p_days_old IN NUMBER DEFAULT 90
) AS
    v_total_records NUMBER;
    v_deleted_records NUMBER;
    v_invalid_records NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('Starting sensor data cleanup (older than ' || p_days_old || ' days)');
    
    -- Count total records
    SELECT COUNT(*) INTO v_total_records
    FROM sensor_data
    WHERE reading_time < SYSDATE - p_days_old;
    
    -- Delete invalid records first (moisture out of range)
    DELETE FROM sensor_data
    WHERE reading_time < SYSDATE - p_days_old
    AND (moisture_value < 0 OR moisture_value > 100);
    
    v_invalid_records := SQL%ROWCOUNT;
    
    -- Archive valid old records (simulated)
    DBMS_OUTPUT.PUT_LINE('Archiving ' || (v_total_records - v_invalid_records) || ' valid records...');
    
    -- Delete archived records
    DELETE FROM sensor_data
    WHERE reading_time < SYSDATE - p_days_old;
    
    v_deleted_records := SQL%ROWCOUNT;
    
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('Cleanup completed:');
    DBMS_OUTPUT.PUT_LINE('  Total old records: ' || v_total_records);
    DBMS_OUTPUT.PUT_LINE('  Invalid records removed: ' || v_invalid_records);
    DBMS_OUTPUT.PUT_LINE('  Valid records archived/deleted: ' || v_deleted_records);
    
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('ERROR during cleanup: ' || SQLERRM);
        ROLLBACK;
        
        -- Re-raise for calling procedure
        RAISE_APPLICATION_ERROR(-20020, 
            'Sensor data cleanup failed: ' || SQLERRM);
END clean_sensor_data;
/

PROMPT Exception handling procedures created successfully!