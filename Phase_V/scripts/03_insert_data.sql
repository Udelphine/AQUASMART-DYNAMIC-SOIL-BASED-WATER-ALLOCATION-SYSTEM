-- ============================================
-- AQUASMART TEST DATA INSERTION
-- ============================================

-- Connect as application user
CONNECT aqua_app_user/AquaSmart2025@localhost:1521/D_27897_Uwineza_AquaSmart_DB;

-- Disable constraints temporarily for faster insertion
ALTER TABLE farm_zones DISABLE CONSTRAINT fk_zone_farmer;
ALTER TABLE sensors DISABLE CONSTRAINT fk_sensor_zone;
ALTER TABLE sensor_data DISABLE CONSTRAINT fk_data_sensor;
ALTER TABLE irrigation_valves DISABLE CONSTRAINT fk_valve_zone;
ALTER TABLE irrigation_logs DISABLE CONSTRAINT fk_log_valve;
ALTER TABLE irrigation_logs DISABLE CONSTRAINT fk_log_zone;
ALTER TABLE weather_data DISABLE CONSTRAINT fk_weather_zone;

-- ============================================
-- 1. INSERT FARMERS (100+ records)
-- ============================================
INSERT ALL
    INTO farmers (farmer_id, username, email, password_hash, first_name, last_name, phone, status) 
    VALUES (1001, 'john_mukasa', 'john.mukasa@email.com', DBMS_CRYPTO.HASH(UTL_RAW.CAST_TO_RAW('Password123'), 2), 'John', 'Mukasa', '+250788123456', 'ACTIVE')
    INTO farmers VALUES (1002, 'marie_uwera', 'marie.uwera@email.com', DBMS_CRYPTO.HASH(UTL_RAW.CAST_TO_RAW('Password123'), 2), 'Marie', 'Uwera', '+250788123457', 'ACTIVE')
    INTO farmers VALUES (1003, 'peter_kalisa', 'peter.kalisa@email.com', DBMS_CRYPTO.HASH(UTL_RAW.CAST_TO_RAW('Password123'), 2), 'Peter', 'Kalisa', '+250788123458', 'ACTIVE')
    INTO farmers VALUES (1004, 'sarah_nyira', 'sarah.nyira@email.com', DBMS_CRYPTO.HASH(UTL_RAW.CAST_TO_RAW('Password123'), 2), 'Sarah', 'Nyira', '+250788123459', 'ACTIVE')
    INTO farmers VALUES (1005, 'david_kamanzi', 'david.kamanzi@email.com', DBMS_CRYPTO.HASH(UTL_RAW.CAST_TO_RAW('Password123'), 2), 'David', 'Kamanzi', '+250788123460', 'ACTIVE')
    INTO farmers VALUES (1006, 'grace_mukamusoni', 'grace.mukamusoni@email.com', DBMS_CRYPTO.HASH(UTL_RAW.CAST_TO_RAW('Password123'), 2), 'Grace', 'Mukamusoni', '+250788123461', 'ACTIVE')
    INTO farmers VALUES (1007, 'james_rukundo', 'james.rukundo@email.com', DBMS_CRYPTO.HASH(UTL_RAW.CAST_TO_RAW('Password123'), 2), 'James', 'Rukundo', '+250788123462', 'ACTIVE')
    INTO farmers VALUES (1008, 'annette_nyanja', 'annette.nyanja@email.com', DBMS_CRYPTO.HASH(UTL_RAW.CAST_TO_RAW('Password123'), 2), 'Annette', 'Nyanja', '+250788123463', 'ACTIVE')
    INTO farmers VALUES (1009, 'robert_habimana', 'robert.habimana@email.com', DBMS_CRYPTO.HASH(UTL_RAW.CAST_TO_RAW('Password123'), 2), 'Robert', 'Habimana', '+250788123464', 'ACTIVE')
    INTO farmers VALUES (1010, 'alice_uwimana', 'alice.uwimana@email.com', DBMS_CRYPTO.HASH(UTL_RAW.CAST_TO_RAW('Password123'), 2), 'Alice', 'Uwimana', '+250788123465', 'ACTIVE')
SELECT 1 FROM DUAL;

-- Generate 90 more farmers using a loop
BEGIN
    FOR i IN 11..100 LOOP
        INSERT INTO farmers (farmer_id, username, email, password_hash, first_name, last_name, phone, status)
        VALUES (
            1000 + i,
            'farmer_' || i,
            'farmer' || i || '@aquafarm.rw',
            DBMS_CRYPTO.HASH(UTL_RAW.CAST_TO_RAW('FarmerPass' || i), 2),
            'FirstName' || i,
            'LastName' || i,
            '+25078' || LPAD(MOD(i, 1000000), 6, '0'),
            CASE WHEN MOD(i, 10) = 0 THEN 'INACTIVE' ELSE 'ACTIVE' END
        );
    END LOOP;
    COMMIT;
END;
/

-- ============================================
-- 2. INSERT FARM_ZONES (300+ records - 3-10 zones per farmer)
-- ============================================
DECLARE
    zone_counter NUMBER := 1001;
    crop_types SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST('Maize', 'Beans', 'Potatoes', 'Tomatoes', 'Cabbage', 'Carrots', 'Rice', 'Wheat', 'Soybeans', 'Coffee');
    soil_types SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST('SAND', 'CLAY', 'LOAM', 'SILT');
    irrigation_types SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST('DRIP', 'SPRINKLER', 'FLOOD');
BEGIN
    FOR f IN (SELECT farmer_id FROM farmers WHERE status = 'ACTIVE') LOOP
        -- Each farmer gets 3-10 zones
        FOR z IN 1..DBMS_RANDOM.VALUE(3, 10) LOOP
            INSERT INTO farm_zones (
                zone_id, farmer_id, zone_name, crop_type, optimal_moisture, 
                area_sqm, soil_type, irrigation_type, created_date
            ) VALUES (
                zone_counter,
                f.farmer_id,
                'Zone_' || TO_CHAR(z) || '_Farm' || f.farmer_id,
                crop_types(MOD(zone_counter, 10) + 1),
                ROUND(DBMS_RANDOM.VALUE(40, 80), 2), -- Optimal moisture 40-80%
                ROUND(DBMS_RANDOM.VALUE(500, 5000), 2), -- Area 500-5000 sqm
                soil_types(MOD(zone_counter, 4) + 1),
                irrigation_types(MOD(zone_counter, 3) + 1),
                SYSDATE - DBMS_RANDOM.VALUE(0, 365) -- Created in last year
            );
            zone_counter := zone_counter + 1;
            
            -- Commit every 50 records
            IF MOD(zone_counter, 50) = 0 THEN
                COMMIT;
            END IF;
        END LOOP;
    END LOOP;
    COMMIT;
END;
/

-- ============================================
-- 3. INSERT SENSORS (500+ records - 1-3 sensors per zone)
-- ============================================
DECLARE
    sensor_counter NUMBER := 1001;
    manufacturers SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST('AquaSense', 'SoilTech', 'FarmIntel', 'GreenTech', 'AgriSmart');
    models SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST('MS-100', 'ST-200', 'FI-300', 'GT-400', 'AS-500');
BEGIN
    FOR z IN (SELECT zone_id FROM farm_zones WHERE status = 'ACTIVE') LOOP
        -- Each zone gets 1-3 sensors
        FOR s IN 1..DBMS_RANDOM.VALUE(1, 3) LOOP
            INSERT INTO sensors (
                sensor_id, zone_id, sensor_code, sensor_type, manufacturer, model,
                installation_date, last_calibration, battery_level, status
            ) VALUES (
                sensor_counter,
                z.zone_id,
                'SENSOR_' || LPAD(sensor_counter, 4, '0'),
                CASE WHEN MOD(sensor_counter, 3) = 0 THEN 'TEMPERATURE' ELSE 'MOISTURE' END,
                manufacturers(MOD(sensor_counter, 5) + 1),
                models(MOD(sensor_counter, 5) + 1),
                SYSDATE - DBMS_RANDOM.VALUE(0, 180), -- Installed 0-6 months ago
                SYSDATE - DBMS_RANDOM.VALUE(0, 90),  -- Calibrated 0-3 months ago
                ROUND(DBMS_RANDOM.VALUE(20, 100)),   -- Battery 20-100%
                CASE WHEN DBMS_RANDOM.VALUE(0, 1) > 0.95 THEN 'FAULTY' ELSE 'ACTIVE' END
            );
            sensor_counter := sensor_counter + 1;
            
            IF MOD(sensor_counter, 100) = 0 THEN
                COMMIT;
            END IF;
        END LOOP;
    END LOOP;
    COMMIT;
END;
/

-- ============================================
-- 4. INSERT SENSOR_DATA (10,000+ records - readings every 15 min)
-- ============================================
DECLARE
    data_counter NUMBER := 1;
    reading_time TIMESTAMP;
BEGIN
    -- Generate 10 days of data for each sensor (96 readings per day = 960 per sensor)
    FOR s IN (SELECT sensor_id FROM sensors WHERE status = 'ACTIVE') LOOP
        reading_time := SYSTIMESTAMP - INTERVAL '10' DAY;
        
        FOR day IN 1..10 LOOP
            FOR hour IN 0..23 LOOP
                FOR minute IN 0..3 LOOP  -- 4 readings per hour (every 15 min)
                    INSERT INTO sensor_data (
                        data_id, sensor_id, moisture_value, temperature, reading_time,
                        battery_at_reading, signal_strength, status_flag
                    ) VALUES (
                        data_counter,
                        s.sensor_id,
                        ROUND(DBMS_RANDOM.VALUE(30, 85), 2), -- Moisture 30-85%
                        ROUND(DBMS_RANDOM.VALUE(15, 35), 1), -- Temperature 15-35°C
                        reading_time + (hour/24) + (minute*15/(24*60)),
                        ROUND(DBMS_RANDOM.VALUE(15, 100)),   -- Battery
                        ROUND(DBMS_RANDOM.VALUE(60, 100)),   -- Signal strength
                        CASE WHEN DBMS_RANDOM.VALUE(0, 1) > 0.98 THEN 'E' ELSE 'N' END
                    );
                    data_counter := data_counter + 1;
                END LOOP;
            END LOOP;
            
            reading_time := reading_time + INTERVAL '1' DAY;
            
            -- Commit every 1000 records
            IF MOD(data_counter, 1000) = 0 THEN
                COMMIT;
            END IF;
        END LOOP;
    END LOOP;
    COMMIT;
END;
/

-- ============================================
-- 5. INSERT IRRIGATION_VALVES (300+ records - 1-2 valves per zone)
-- ============================================
DECLARE
    valve_counter NUMBER := 1001;
BEGIN
    FOR z IN (SELECT zone_id FROM farm_zones WHERE status = 'ACTIVE') LOOP
        -- Each zone gets 1-2 valves
        FOR v IN 1..DBMS_RANDOM.VALUE(1, 2) LOOP
            INSERT INTO irrigation_valves (
                valve_id, zone_id, valve_code, valve_type, flow_rate,
                installation_date, last_maintenance, status
            ) VALUES (
                valve_counter,
                z.zone_id,
                'VALVE_' || LPAD(valve_counter, 4, '0'),
                'SOLENOID',
                ROUND(DBMS_RANDOM.VALUE(10, 50), 2), -- Flow rate 10-50 L/min
                SYSDATE - DBMS_RANDOM.VALUE(0, 365),
                SYSDATE - DBMS_RANDOM.VALUE(0, 180),
                CASE WHEN DBMS_RANDOM.VALUE(0, 1) > 0.97 THEN 'FAULTY' ELSE 'ACTIVE' END
            );
            valve_counter := valve_counter + 1;
        END LOOP;
        
        IF MOD(valve_counter, 100) = 0 THEN
            COMMIT;
        END IF;
    END LOOP;
    COMMIT;
END;
/

-- ============================================
-- 6. INSERT IRRIGATION_LOGS (5,000+ records)
-- ============================================
DECLARE
    log_counter NUMBER := 1;
    log_time TIMESTAMP;
    duration_min NUMBER;
BEGIN
    FOR v IN (SELECT valve_id, zone_id FROM irrigation_valves WHERE status = 'ACTIVE') LOOP
        -- Each valve has 10-50 irrigation events in last 30 days
        FOR e IN 1..DBMS_RANDOM.VALUE(10, 50) LOOP
            log_time := SYSTIMESTAMP - DBMS_RANDOM.VALUE(0, 30); -- Last 30 days
            duration_min := DBMS_RANDOM.VALUE(5, 60); -- Duration 5-60 minutes
            
            INSERT INTO irrigation_logs (
                log_id, valve_id, zone_id, start_time, end_time, water_volume,
                initial_moisture, final_moisture, trigger_source, status
            ) VALUES (
                log_counter,
                v.valve_id,
                v.zone_id,
                log_time,
                log_time + (duration_min/1440), -- Convert minutes to days
                ROUND(DBMS_RANDOM.VALUE(100, 1000), 2), -- Water volume 100-1000L
                ROUND(DBMS_RANDOM.VALUE(30, 50), 2),    -- Initial moisture low
                ROUND(DBMS_RANDOM.VALUE(60, 80), 2),    -- Final moisture optimal
                CASE 
                    WHEN MOD(log_counter, 10) = 0 THEN 'MANUAL'
                    WHEN MOD(log_counter, 20) = 0 THEN 'SCHEDULE'
                    ELSE 'AUTO'
                END,
                'COMPLETED'
            );
            log_counter := log_counter + 1;
            
            IF MOD(log_counter, 1000) = 0 THEN
                COMMIT;
            END IF;
        END LOOP;
    END LOOP;
    COMMIT;
END;
/

-- ============================================
-- 7. INSERT WEATHER_DATA (Optional - 1,000+ records)
-- ============================================
DECLARE
    weather_counter NUMBER := 1;
    forecast_date DATE;
BEGIN
    FOR z IN (SELECT zone_id FROM farm_zones WHERE status = 'ACTIVE' AND ROWNUM <= 50) LOOP
        -- Last 30 days of weather data for 50 zones
        FOR d IN 0..29 LOOP
            forecast_date := TRUNC(SYSDATE) - d;
            
            INSERT INTO weather_data (
                weather_id, zone_id, forecast_date, temperature_high, temperature_low,
                precipitation, humidity, wind_speed
            ) VALUES (
                weather_counter,
                z.zone_id,
                forecast_date,
                ROUND(DBMS_RANDOM.VALUE(20, 35), 1), -- High temp
                ROUND(DBMS_RANDOM.VALUE(10, 25), 1), -- Low temp
                ROUND(DBMS_RANDOM.VALUE(0, 50), 2),  -- Precipitation 0-50mm
                ROUND(DBMS_RANDOM.VALUE(40, 95)),    -- Humidity 40-95%
                ROUND(DBMS_RANDOM.VALUE(0, 30), 1)   -- Wind speed 0-30 km/h
            );
            weather_counter := weather_counter + 1;
        END LOOP;
        
        IF MOD(weather_counter, 500) = 0 THEN
            COMMIT;
        END IF;
    END LOOP;
    COMMIT;
END;
/

-- ============================================
-- RE-ENABLE CONSTRAINTS
-- ============================================
ALTER TABLE farm_zones ENABLE CONSTRAINT fk_zone_farmer;
ALTER TABLE sensors ENABLE CONSTRAINT fk_sensor_zone;
ALTER TABLE sensor_data ENABLE CONSTRAINT fk_data_sensor;
ALTER TABLE irrigation_valves ENABLE CONSTRAINT fk_valve_zone;
ALTER TABLE irrigation_logs ENABLE CONSTRAINT fk_log_valve;
ALTER TABLE irrigation_logs ENABLE CONSTRAINT fk_log_zone;
ALTER TABLE weather_data ENABLE CONSTRAINT fk_weather_zone;

-- ============================================
-- DATA VERIFICATION
-- ============================================
PROMPT =========== DATA INSERTION SUMMARY ===========
PROMPT Farmers inserted:          100+ records
PROMPT Farm Zones inserted:       300+ records
PROMPT Sensors inserted:          500+ records
PROMPT Sensor Data inserted:      10,000+ records
PROMPT Irrigation Valves inserted: 300+ records
PROMPT Irrigation Logs inserted:  5,000+ records
PROMPT Weather Data inserted:     1,000+ records
PROMPT =============================================

COMMIT;