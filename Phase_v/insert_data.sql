-- ============================================
-- AQUASMART DATA INSERTION SCRIPT
-- Student: Uwineza Delphine (ID: 27897)
-- Phase V: Data Insertion
-- Date: December 12, 2025
-- ============================================

SET SERVEROUTPUT ON
PROMPT === STARTING DATA INSERTION FOR AQUASMART ===

-- Clear existing data if any (optional - comment out in production)
/*
BEGIN
    EXECUTE IMMEDIATE 'DELETE FROM irrigation_logs';
    EXECUTE IMMEDIATE 'DELETE FROM sensor_data';
    EXECUTE IMMEDIATE 'DELETE FROM irrigation_valves';
    EXECUTE IMMEDIATE 'DELETE FROM sensors';
    EXECUTE IMMEDIATE 'DELETE FROM farm_zones';
    EXECUTE IMMEDIATE 'DELETE FROM farmers';
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('All existing data cleared');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('No data to clear or error: ' || SQLERRM);
END;
/
*/

-- PART 1: INSERT FARMERS
PROMPT Inserting farmers...
BEGIN
    INSERT INTO farmers (farmer_id, username, email, password_hash, phone_number, address) 
    VALUES (seq_farmers_id.NEXTVAL, 'john_doe', 'john.doe@email.com', 
            'hashed_password_1', '+250788123456', 'Kigali, Gasabo District');

    INSERT INTO farmers (farmer_id, username, email, password_hash, phone_number, address) 
    VALUES (seq_farmers_id.NEXTVAL, 'mary_smith', 'mary.smith@farm.com', 
            'hashed_password_2', '+250788654321', 'Musanze, Northern Province');

    INSERT INTO farmers (farmer_id, username, email, password_hash, phone_number, address) 
    VALUES (seq_farmers_id.NEXTVAL, 'peter_ngoma', 'peter.n@agri.com', 
            'hashed_password_3', '+250728111222', 'Huye, Southern Province');

    INSERT INTO farmers (farmer_id, username, email, password_hash, phone_number, address) 
    VALUES (seq_farmers_id.NEXTVAL, 'sarah_k', 'sarah.k@water.com', 
            'hashed_password_4', '+250788333444', 'Rubavu, Western Province');

    INSERT INTO farmers (farmer_id, username, email, password_hash, phone_number, address, status) 
    VALUES (seq_farmers_id.NEXTVAL, 'inactive_farmer', 'inactive@test.com', 
            'hashed_password_5', '+250788555666', 'Kayonza, Eastern Province', 'INACTIVE');
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('✓ 5 farmers inserted');
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        DBMS_OUTPUT.PUT_LINE('Farmers already exist, skipping...');
END;
/

-- PART 2: INSERT FARM ZONES
PROMPT Inserting farm zones...
DECLARE
    v_farmer_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_farmer_count FROM farmers;
    
    IF v_farmer_count > 0 THEN
        -- Farmer 1001 zones
        INSERT INTO farm_zones (zone_id, farmer_id, zone_name, crop_type, optimal_moisture, area_sqm, soil_type)
        VALUES (seq_farm_zones_id.NEXTVAL, 1001, 'North Field A', 'Maize', 65.5, 2500.00, 'Loamy');
        
        INSERT INTO farm_zones (zone_id, farmer_id, zone_name, crop_type, optimal_moisture, area_sqm, soil_type)
        VALUES (seq_farm_zones_id.NEXTVAL, 1001, 'South Field B', 'Tomatoes', 70.0, 1200.00, 'Clay');
        
        INSERT INTO farm_zones (zone_id, farmer_id, zone_name, crop_type, optimal_moisture, area_sqm, soil_type, status)
        VALUES (seq_farm_zones_id.NEXTVAL, 1001, 'East Field C', 'Beans', 60.0, 800.00, 'Sandy', 'MAINTENANCE');
        
        -- Farmer 1002 zones
        INSERT INTO farm_zones (zone_id, farmer_id, zone_name, crop_type, optimal_moisture, area_sqm, soil_type)
        VALUES (seq_farm_zones_id.NEXTVAL, 1002, 'Main Plot A', 'Potatoes', 68.0, 3500.00, 'Loamy');
        
        INSERT INTO farm_zones (zone_id, farmer_id, zone_name, crop_type, optimal_moisture, area_sqm, soil_type, irrigation_method)
        VALUES (seq_farm_zones_id.NEXTVAL, 1002, 'Greenhouse B', 'Strawberries', 75.5, 500.00, 'Peat', 'DRIP');
        
        -- Farmer 1003 zones
        INSERT INTO farm_zones (zone_id, farmer_id, zone_name, crop_type, optimal_moisture, area_sqm, soil_type)
        VALUES (seq_farm_zones_id.NEXTVAL, 1003, 'Coffee Field', 'Coffee', 62.0, 5000.00, 'Volcanic');
        
        INSERT INTO farm_zones (zone_id, farmer_id, zone_name, crop_type, optimal_moisture, area_sqm, soil_type, irrigation_method)
        VALUES (seq_farm_zones_id.NEXTVAL, 1003, 'Nursery Zone', 'Seedlings', 80.0, 300.00, 'Compost', 'SPRINKLER');
        
        -- Farmer 1004 zones
        INSERT INTO farm_zones (zone_id, farmer_id, zone_name, crop_type, optimal_moisture, area_sqm, soil_type)
        VALUES (seq_farm_zones_id.NEXTVAL, 1004, 'Rice Paddy A', 'Rice', 85.0, 4200.00, 'Clay');
        
        COMMIT;
        DBMS_OUTPUT.PUT_LINE('✓ 8 farm zones inserted');
    ELSE
        DBMS_OUTPUT.PUT_LINE('No farmers found, skipping zone insertion');
    END IF;
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        DBMS_OUTPUT.PUT_LINE('Farm zones already exist, skipping...');
        COMMIT;
END;
/

-- PART 3: INSERT SENSORS
PROMPT Inserting sensors...
DECLARE
    v_sensor_count NUMBER := 0;
BEGIN
    -- Insert 2-3 sensors for each zone
    FOR zone_rec IN (SELECT zone_id FROM farm_zones ORDER BY zone_id) LOOP
        -- Sensor 1: Soil moisture (always present)
        INSERT INTO sensors (sensor_id, zone_id, sensor_code, battery_level, sensor_type)
        VALUES (
            seq_sensors_id.NEXTVAL,
            zone_rec.zone_id,
            'SM-' || zone_rec.zone_id || '-01',
            TRUNC(DBMS_RANDOM.VALUE(60, 100)),
            'SOIL_MOISTURE'
        );
        v_sensor_count := v_sensor_count + 1;
        
        -- Sensor 2: Temperature (for 50% of zones)
        IF MOD(zone_rec.zone_id, 2) = 0 THEN
            INSERT INTO sensors (sensor_id, zone_id, sensor_code, battery_level, sensor_type)
            VALUES (
                seq_sensors_id.NEXTVAL,
                zone_rec.zone_id,
                'TEMP-' || zone_rec.zone_id || '-01',
                TRUNC(DBMS_RANDOM.VALUE(70, 100)),
                'TEMPERATURE'
            );
            v_sensor_count := v_sensor_count + 1;
        END IF;
        
        -- Sensor 3: Extra soil moisture for large zones
        DECLARE
            v_area NUMBER;
        BEGIN
            SELECT area_sqm INTO v_area FROM farm_zones WHERE zone_id = zone_rec.zone_id;
            IF v_area > 2000 THEN
                INSERT INTO sensors (sensor_id, zone_id, sensor_code, battery_level, sensor_type)
                VALUES (
                    seq_sensors_id.NEXTVAL,
                    zone_rec.zone_id,
                    'SM-' || zone_rec.zone_id || '-02',
                    TRUNC(DBMS_RANDOM.VALUE(50, 90)),
                    'SOIL_MOISTURE'
                );
                v_sensor_count := v_sensor_count + 1;
            END IF;
        END;
    END LOOP;
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('✓ ' || v_sensor_count || ' sensors inserted');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error inserting sensors: ' || SQLERRM);
        ROLLBACK;
END;
/

-- PART 4: INSERT IRRIGATION VALVES
PROMPT Inserting irrigation valves...
DECLARE
    v_valve_count NUMBER := 0;
    TYPE valve_array IS VARRAY(3) OF VARCHAR2(20);
    v_valve_types valve_array := valve_array('SOLENOID', 'MOTORIZED', 'MANUAL');
    v_statuses valve_array := valve_array('CLOSED', 'OPEN', 'FAULTY');
BEGIN
    FOR zone_rec IN (SELECT zone_id, area_sqm FROM farm_zones ORDER BY zone_id) LOOP
        -- Determine number of valves based on zone area
        DECLARE
            v_num_valves NUMBER;
        BEGIN
            IF zone_rec.area_sqm < 1000 THEN
                v_num_valves := 1;
            ELSIF zone_rec.area_sqm < 3000 THEN
                v_num_valves := 2;
            ELSE
                v_num_valves := 3;
            END IF;
            
            -- Insert valves
            FOR i IN 1..v_num_valves LOOP
                INSERT INTO irrigation_valves (
                    valve_id, zone_id, valve_code, flow_rate, 
                    valve_type, status, total_water_volume
                ) VALUES (
                    seq_valves_id.NEXTVAL,
                    zone_rec.zone_id,
                    'VLV-' || zone_rec.zone_id || '-' || LPAD(i, 2, '0'),
                    ROUND(DBMS_RANDOM.VALUE(5.0, 25.0), 1),
                    v_valve_types(TRUNC(DBMS_RANDOM.VALUE(1, 4))),
                    v_statuses(TRUNC(DBMS_RANDOM.VALUE(1, 4))),
                    ROUND(DBMS_RANDOM.VALUE(0, 1000.0), 2)
                );
                v_valve_count := v_valve_count + 1;
            END LOOP;
        END;
    END LOOP;
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('✓ ' || v_valve_count || ' irrigation valves inserted');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error inserting valves: ' || SQLERRM);
        ROLLBACK;
END;
/

-- PART 5: INSERT SENSOR DATA (100+ records)
PROMPT Inserting sensor data (this may take a moment)...
DECLARE
    v_total_readings NUMBER := 0;
    v_days_ago NUMBER := 30; -- Generate data for last 30 days
    v_readings_per_day NUMBER := 24; -- Hourly readings
    v_start_timestamp TIMESTAMP;
BEGIN
    -- Get current timestamp for reference
    v_start_timestamp := SYSTIMESTAMP - v_days_ago;
    
    -- For each active sensor
    FOR sensor_rec IN (SELECT sensor_id FROM sensors WHERE status = 'ACTIVE') LOOP
        -- Generate hourly readings for past 30 days
        FOR day_offset IN 0..v_days_ago-1 LOOP
            FOR hour_offset IN 0..23 LOOP
                INSERT INTO sensor_data (
                    data_id, sensor_id, moisture_value, reading_time,
                    temperature, status_flag, reading_quality
                ) VALUES (
                    seq_sensor_data_id.NEXTVAL,
                    sensor_rec.sensor_id,
                    ROUND(DBMS_RANDOM.VALUE(30.0, 85.0), 2),
                    v_start_timestamp + day_offset + (hour_offset/24) + DBMS_RANDOM.VALUE(0, 0.04),
                    CASE 
                        WHEN (SELECT sensor_type FROM sensors WHERE sensor_id = sensor_rec.sensor_id) = 'TEMPERATURE'
                        THEN ROUND(DBMS_RANDOM.VALUE(15.0, 35.0), 1)
                        ELSE NULL
                    END,
                    CASE 
                        WHEN DBMS_RANDOM.VALUE < 0.05 THEN 'E'  -- 5% errors
                        WHEN DBMS_RANDOM.VALUE < 0.15 THEN 'A'  -- 10% alerts
                        ELSE 'P'                               -- 85% normal
                    END,
                    TRUNC(DBMS_RANDOM.VALUE(80, 101))
                );
                
                v_total_readings := v_total_readings + 1;
                
                -- Progress update every 1000 records
                IF MOD(v_total_readings, 1000) = 0 THEN
                    COMMIT;
                    DBMS_OUTPUT.PUT_LINE('  Progress: ' || v_total_readings || ' readings inserted...');
                END IF;
            END LOOP;
        END LOOP;
    END LOOP;
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('✓ ' || v_total_readings || ' sensor readings inserted');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error inserting sensor data: ' || SQLERRM);
        ROLLBACK;
END;
/

-- PART 6: INSERT IRRIGATION LOGS
PROMPT Inserting irrigation logs...
DECLARE
    v_total_events NUMBER := 0;
    v_trigger_types SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST('AUTOMATIC', 'MANUAL', 'SCHEDULED', 'EMERGENCY');
    v_event_statuses SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST('COMPLETED', 'FAILED', 'CANCELLED', 'STARTED');
BEGIN
    -- For each valve, create irrigation events
    FOR valve_rec IN (
        SELECT v.valve_id, v.zone_id, v.flow_rate, v.status as valve_status
        FROM irrigation_valves v 
        WHERE v.status IN ('OPEN', 'CLOSED')
    ) LOOP
        -- Create 2-10 events per valve
        FOR event_num IN 1..TRUNC(DBMS_RANDOM.VALUE(2, 11)) LOOP
            DECLARE
                v_duration_minutes NUMBER := TRUNC(DBMS_RANDOM.VALUE(10, 61)); -- 10-60 minutes
                v_water_volume NUMBER := ROUND(valve_rec.flow_rate * v_duration_minutes, 2);
                v_start_time TIMESTAMP := SYSTIMESTAMP - DBMS_RANDOM.VALUE(0, 30); -- Random time in last 30 days
                v_end_time TIMESTAMP := v_start_time + (v_duration_minutes/(24*60));
                v_event_status VARCHAR2(20) := v_event_statuses(TRUNC(DBMS_RANDOM.VALUE(1, 5)));
                v_trigger_source VARCHAR2(20) := v_trigger_types(TRUNC(DBMS_RANDOM.VALUE(1, 5)));
                v_initial_moisture NUMBER(5,2) := ROUND(DBMS_RANDOM.VALUE(30.0, 60.0), 2);
                v_final_moisture NUMBER(5,2) := v_initial_moisture + ROUND(DBMS_RANDOM.VALUE(10.0, 30.0), 2);
            BEGIN
                INSERT INTO irrigation_logs (
                    log_id, valve_id, zone_id, trigger_source,
                    start_time, end_time, water_volume,
                    initial_moisture, final_moisture, status,
                    energy_consumption, notes
                ) VALUES (
                    seq_irrigation_logs_id.NEXTVAL,
                    valve_rec.valve_id,
                    valve_rec.zone_id,
                    v_trigger_source,
                    v_start_time,
                    CASE WHEN v_event_status = 'COMPLETED' THEN v_end_time ELSE NULL END,
                    CASE WHEN v_event_status = 'COMPLETED' THEN v_water_volume ELSE NULL END,
                    v_initial_moisture,
                    CASE WHEN v_event_status = 'COMPLETED' THEN v_final_moisture ELSE NULL END,
                    v_event_status,
                    ROUND(v_water_volume * 0.1, 2), -- Estimated energy (10% of water volume)
                    CASE v_event_status
                        WHEN 'FAILED' THEN 'System malfunction - requires maintenance'
                        WHEN 'CANCELLED' THEN 'Manual override by farmer'
                        WHEN 'STARTED' THEN 'Irrigation in progress'
                        ELSE 'Normal operation completed successfully'
                    END
                );
                
                v_total_events := v_total_events + 1;
                
                -- Update valve's total water volume if event completed
                IF v_event_status = 'COMPLETED' THEN
                    UPDATE irrigation_valves 
                    SET total_water_volume = NVL(total_water_volume, 0) + v_water_volume
                    WHERE valve_id = valve_rec.valve_id;
                END IF;
                
                -- Progress update
                IF MOD(v_total_events, 50) = 0 THEN
                    COMMIT;
                    DBMS_OUTPUT.PUT_LINE('  Progress: ' || v_total_events || ' irrigation events inserted...');
                END IF;
            END;
        END LOOP;
    END LOOP;
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('✓ ' || v_total_events || ' irrigation events inserted');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error inserting irrigation logs: ' || SQLERRM);
        ROLLBACK;
END;
/

-- FINAL SUMMARY
PROMPT === DATA INSERTION SUMMARY ===
BEGIN
    DBMS_OUTPUT.PUT_LINE('FARMERS:          ' || (SELECT COUNT(*) FROM farmers));
    DBMS_OUTPUT.PUT_LINE('FARM_ZONES:       ' || (SELECT COUNT(*) FROM farm_zones));
    DBMS_OUTPUT.PUT_LINE('SENSORS:          ' || (SELECT COUNT(*) FROM sensors));
    DBMS_OUTPUT.PUT_LINE('IRRIGATION_VALVES: ' || (SELECT COUNT(*) FROM irrigation_valves));
    DBMS_OUTPUT.PUT_LINE('SENSOR_DATA:      ' || (SELECT COUNT(*) FROM sensor_data));
    DBMS_OUTPUT.PUT_LINE('IRRIGATION_LOGS:  ' || (SELECT COUNT(*) FROM irrigation_logs));
    DBMS_OUTPUT.PUT_LINE('===================================');
    DBMS_OUTPUT.PUT_LINE('TOTAL RECORDS:    ' || (
        (SELECT COUNT(*) FROM farmers) +
        (SELECT COUNT(*) FROM farm_zones) +
        (SELECT COUNT(*) FROM sensors) +
        (SELECT COUNT(*) FROM irrigation_valves) +
        (SELECT COUNT(*) FROM sensor_data) +
        (SELECT COUNT(*) FROM irrigation_logs)
    ));
END;
/

PROMPT === DATA INSERTION COMPLETED SUCCESSFULLY ===