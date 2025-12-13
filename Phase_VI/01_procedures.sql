-- ============================================
-- PHASE VI: PROCEDURES (6 procedures)
-- AQUASMART Irrigation System
-- Student: Uwineza Delphine (ID: 27897)
-- ============================================

-- Procedure 1: REGISTER_NEW_FARMER
CREATE OR REPLACE PROCEDURE register_new_farmer(
    p_username IN VARCHAR2,
    p_email IN VARCHAR2,
    p_password IN VARCHAR2,
    p_phone IN VARCHAR2 DEFAULT NULL,
    p_address IN VARCHAR2 DEFAULT NULL,
    p_farmer_id OUT NUMBER,
    p_status OUT VARCHAR2
) AS
    v_email_count NUMBER;
    v_username_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_email_count FROM farmers WHERE LOWER(email) = LOWER(p_email);
    IF v_email_count > 0 THEN p_status := 'ERROR: Email exists'; RETURN; END IF;
    
    SELECT COUNT(*) INTO v_username_count FROM farmers WHERE LOWER(username) = LOWER(p_username);
    IF v_username_count > 0 THEN p_status := 'ERROR: Username exists'; RETURN; END IF;
    
    p_farmer_id := seq_farmers_id.NEXTVAL;
    INSERT INTO farmers (farmer_id, username, email, password_hash, phone_number, address, registration_date, status)
    VALUES (p_farmer_id, p_username, p_email, p_password, p_phone, p_address, SYSDATE, 'ACTIVE');
    
    COMMIT;
    p_status := 'SUCCESS: Farmer ID ' || p_farmer_id;
EXCEPTION
    WHEN OTHERS THEN p_status := 'ERROR: ' || SQLERRM; ROLLBACK;
END;
/

-- Procedure 2: ACTIVATE_IRRIGATION
CREATE OR REPLACE PROCEDURE activate_irrigation(
    p_zone_id IN NUMBER,
    p_trigger_source IN VARCHAR2 DEFAULT 'MANUAL',
    p_water_volume OUT NUMBER,
    p_status OUT VARCHAR2
) AS
    v_valve_id NUMBER;
    v_flow_rate NUMBER;
    v_current_moisture NUMBER;
BEGIN
    SELECT moisture_value INTO v_current_moisture FROM (
        SELECT sd.moisture_value FROM sensor_data sd
        JOIN sensors s ON sd.sensor_id = s.sensor_id
        WHERE s.zone_id = p_zone_id AND s.sensor_type = 'SOIL_MOISTURE'
        ORDER BY sd.reading_time DESC
    ) WHERE ROWNUM = 1;
    
    SELECT valve_id, flow_rate INTO v_valve_id, v_flow_rate
    FROM irrigation_valves WHERE zone_id = p_zone_id AND status = 'CLOSED' AND ROWNUM = 1;
    
    p_water_volume := ROUND(v_flow_rate * 15, 2);
    
    UPDATE irrigation_valves SET status = 'OPEN', last_activation_date = SYSDATE WHERE valve_id = v_valve_id;
    
    INSERT INTO irrigation_logs (log_id, valve_id, zone_id, trigger_source, start_time, water_volume, initial_moisture, status)
    VALUES (seq_irrigation_logs_id.NEXTVAL, v_valve_id, p_zone_id, p_trigger_source, SYSTIMESTAMP, p_water_volume, v_current_moisture, 'STARTED');
    
    COMMIT;
    p_status := 'SUCCESS: Irrigation started. Water: ' || p_water_volume || 'L';
EXCEPTION
    WHEN NO_DATA_FOUND THEN p_status := 'ERROR: No active valve found'; p_water_volume := 0;
    WHEN OTHERS THEN p_status := 'ERROR: ' || SQLERRM; p_water_volume := 0; ROLLBACK;
END;
/

-- Procedure 3: UPDATE_SENSOR_STATUS
CREATE OR REPLACE PROCEDURE update_sensor_status(
    p_sensor_id IN NUMBER,
    p_new_status IN VARCHAR2,
    p_battery_level IN NUMBER DEFAULT NULL,
    p_status OUT VARCHAR2
) AS
    v_old_status VARCHAR2(20);
BEGIN
    SELECT status INTO v_old_status FROM sensors WHERE sensor_id = p_sensor_id;
    
    UPDATE sensors SET status = p_new_status, battery_level = COALESCE(p_battery_level, battery_level)
    WHERE sensor_id = p_sensor_id;
    
    COMMIT;
    p_status := 'SUCCESS: Sensor updated to ' || p_new_status;
EXCEPTION
    WHEN NO_DATA_FOUND THEN p_status := 'ERROR: Sensor not found';
    WHEN OTHERS THEN p_status := 'ERROR: ' || SQLERRM; ROLLBACK;
END;
/

-- Procedure 4: GENERATE_WATER_USAGE_REPORT
CREATE OR REPLACE PROCEDURE generate_water_usage_report(
    p_start_date IN DATE DEFAULT SYSDATE - 30,
    p_end_date IN DATE DEFAULT SYSDATE
) AS
    v_total_water NUMBER := 0;
    v_total_events NUMBER := 0;
BEGIN
    DBMS_OUTPUT.PUT_LINE('WATER USAGE REPORT: ' || p_start_date || ' to ' || p_end_date);
    DBMS_OUTPUT.PUT_LINE('==========================================');
    
    FOR rec IN (
        SELECT f.username, fz.zone_name, COUNT(il.log_id) as events, SUM(il.water_volume) as water
        FROM farmers f JOIN farm_zones fz ON f.farmer_id = fz.farmer_id
        JOIN irrigation_logs il ON fz.zone_id = il.zone_id
        WHERE il.start_time BETWEEN p_start_date AND p_end_date AND il.status = 'COMPLETED'
        GROUP BY f.username, fz.zone_name
        ORDER BY f.username
    ) LOOP
        DBMS_OUTPUT.PUT_LINE(RPAD(rec.username, 15) || ' | ' || RPAD(rec.zone_name, 20) || 
                            ' | ' || LPAD(rec.events, 5) || ' events | ' || LPAD(ROUND(rec.water,2), 10) || 'L');
        v_total_water := v_total_water + rec.water;
        v_total_events := v_total_events + rec.events;
    END LOOP;
    
    DBMS_OUTPUT.PUT_LINE('==========================================');
    DBMS_OUTPUT.PUT_LINE('TOTAL: ' || v_total_events || ' events, ' || ROUND(v_total_water,2) || ' liters');
END;
/

-- Procedure 5: PROCESS_SENSOR_ALERTS
CREATE OR REPLACE PROCEDURE process_sensor_alerts AS
    v_alert_count NUMBER := 0;
BEGIN
    FOR rec IN (
        SELECT sd.data_id, sd.sensor_id, sd.moisture_value, s.zone_id
        FROM sensor_data sd JOIN sensors s ON sd.sensor_id = s.sensor_id
        WHERE sd.status_flag = 'A' AND sd.reading_time > SYSDATE - 1
    ) LOOP
        v_alert_count := v_alert_count + 1;
        UPDATE sensor_data SET status_flag = 'P' WHERE data_id = rec.data_id;
    END LOOP;
    
    DBMS_OUTPUT.PUT_LINE('Processed ' || v_alert_count || ' alerts');
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('ERROR: ' || SQLERRM); ROLLBACK;
END;
/

-- Procedure 6: MAINTENANCE_SCHEDULER
CREATE OR REPLACE PROCEDURE maintenance_scheduler AS
    v_sensor_count NUMBER := 0;
    v_valve_count NUMBER := 0;
BEGIN
    SELECT COUNT(*) INTO v_sensor_count FROM sensors WHERE battery_level < 30 AND status = 'ACTIVE';
    SELECT COUNT(*) INTO v_valve_count FROM irrigation_valves WHERE status IN ('FAULTY', 'MAINTENANCE');
    
    DBMS_OUTPUT.PUT_LINE('MAINTENANCE REPORT');
    DBMS_OUTPUT.PUT_LINE('==================');
    DBMS_OUTPUT.PUT_LINE('Sensors needing battery: ' || v_sensor_count);
    DBMS_OUTPUT.PUT_LINE('Valves needing repair: ' || v_valve_count);
    
    IF v_sensor_count = 0 AND v_valve_count = 0 THEN
        DBMS_OUTPUT.PUT_LINE('No maintenance required.');
    END IF;
END;
/

PROMPT 6 procedures created successfully!