-- ============================================
-- PHASE VI: CURSORS
-- ============================================

-- Cursor 1: Explicit cursor for sensor data processing
DECLARE
    CURSOR sensor_cursor IS
        SELECT s.sensor_id, s.sensor_code, s.battery_level,
               fz.zone_name, f.username
        FROM sensors s
        JOIN farm_zones fz ON s.zone_id = fz.zone_id
        JOIN farmers f ON fz.farmer_id = f.farmer_id
        WHERE s.status = 'ACTIVE'
        ORDER BY s.battery_level;
    
    v_sensor_id sensors.sensor_id%TYPE;
    v_sensor_code sensors.sensor_code%TYPE;
    v_battery_level sensors.battery_level%TYPE;
    v_zone_name farm_zones.zone_name%TYPE;
    v_username farmers.username%TYPE;
    v_low_battery_count NUMBER := 0;
BEGIN
    DBMS_OUTPUT.PUT_LINE('ACTIVE SENSORS REPORT');
    DBMS_OUTPUT.PUT_LINE('======================');
    
    OPEN sensor_cursor;
    LOOP
        FETCH sensor_cursor INTO v_sensor_id, v_sensor_code, v_battery_level, v_zone_name, v_username;
        EXIT WHEN sensor_cursor%NOTFOUND;
        
        IF v_battery_level < 30 THEN
            DBMS_OUTPUT.PUT_LINE('⚠ LOW BATTERY: ' || v_sensor_code || ' (' || v_zone_name || 
                                ') - ' || v_battery_level || '% - Farmer: ' || v_username);
            v_low_battery_count := v_low_battery_count + 1;
        END IF;
    END LOOP;
    CLOSE sensor_cursor;
    
    DBMS_OUTPUT.PUT_LINE('Total sensors with low battery (<30%): ' || v_low_battery_count);
END;
/

-- Cursor 2: Parameterized cursor for zone irrigation history
DECLARE
    CURSOR zone_history_cursor(p_zone_id NUMBER) IS
        SELECT il.start_time, il.water_volume, il.trigger_source, il.status,
               ROW_NUMBER() OVER (ORDER BY il.start_time DESC) as rn
        FROM irrigation_logs il
        WHERE il.zone_id = p_zone_id
        AND il.start_time > SYSDATE - 7
        ORDER BY il.start_time DESC;
    
    v_total_water NUMBER := 0;
    v_event_count NUMBER := 0;
BEGIN
    DBMS_OUTPUT.PUT_LINE('LAST 7 DAYS IRRIGATION FOR ZONE 2001');
    DBMS_OUTPUT.PUT_LINE('=====================================');
    
    FOR rec IN zone_history_cursor(2001) LOOP
        IF rec.rn <= 10 THEN  -- Show only last 10 events
            DBMS_OUTPUT.PUT_LINE(
                TO_CHAR(rec.start_time, 'DD-MON HH24:MI') || ' | ' ||
                LPAD(ROUND(rec.water_volume, 2), 8) || 'L | ' ||
                RPAD(rec.trigger_source, 10) || ' | ' ||
                rec.status
            );
        END IF;
        
        v_total_water := v_total_water + rec.water_volume;
        v_event_count := v_event_count + 1;
    END LOOP;
    
    DBMS_OUTPUT.PUT_LINE('=====================================');
    DBMS_OUTPUT.PUT_LINE('Total: ' || v_event_count || ' events, ' || ROUND(v_total_water, 2) || ' liters');
END;
/

-- Cursor 3: Cursor FOR LOOP with BULK COLLECT (optimized)
DECLARE
    TYPE sensor_array IS TABLE OF sensors%ROWTYPE;
    v_sensors sensor_array;
    v_updated_count NUMBER := 0;
BEGIN
    -- Bulk collect sensors needing calibration
    SELECT * BULK COLLECT INTO v_sensors
    FROM sensors
    WHERE calibration_due_date IS NOT NULL
    AND calibration_due_date < SYSDATE
    AND status = 'ACTIVE';
    
    DBMS_OUTPUT.PUT_LINE('SENSORS NEEDING CALIBRATION: ' || v_sensors.COUNT);
    
    -- Process in bulk
    FOR i IN 1..v_sensors.COUNT LOOP
        DBMS_OUTPUT.PUT_LINE('Calibrating: ' || v_sensors(i).sensor_code || ' - Due: ' || 
                            TO_CHAR(v_sensors(i).calibration_due_date, 'DD-MON-YYYY'));
        
        UPDATE sensors 
        SET calibration_due_date = SYSDATE + 30,
            last_maintenance_date = SYSDATE
        WHERE sensor_id = v_sensors(i).sensor_id;
        
        v_updated_count := v_updated_count + 1;
    END LOOP;
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE(v_updated_count || ' sensors calibrated and updated.');
END;
/

PROMPT Cursors executed successfully!