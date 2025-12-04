-- ============================================
-- AquaSmart: INSERT DATA Script
-- Student: Uwineza Delphine | ID: 27897
-- Date: 2025-12-04
-- ============================================

-- Connect as application user
CONNECT aqua_app_user/AquaSmart2025@localhost:1521/D_27897_Uwineza_AquaSmart_DB;

-- ============================================
-- 1. INSERT FARMERS (5 farmers)
-- ============================================

INSERT INTO farmers (username, first_name, last_name, email, phone, password_hash) VALUES 
('john_doe', 'John', 'Doe', 'john.doe@email.com', '+250788123456', 'hashed_password_1');

INSERT INTO farmers (username, first_name, last_name, email, phone, password_hash) VALUES 
('jane_smith', 'Jane', 'Smith', 'jane.smith@email.com', '+250788234567', 'hashed_password_2');

INSERT INTO farmers (username, first_name, last_name, email, phone, password_hash) VALUES 
('robert_k', 'Robert', 'Kagabo', 'robert.k@email.com', '+250788345678', 'hashed_password_3');

INSERT INTO farmers (username, first_name, last_name, email, phone, password_hash) VALUES 
('marie_u', 'Marie', 'Uwera', 'marie.u@email.com', '+250788456789', 'hashed_password_4');

INSERT INTO farmers (username, first_name, last_name, email, phone, password_hash) VALUES 
('paul_m', 'Paul', 'Mugisha', 'paul.m@email.com', '+250788567890', 'hashed_password_5');

COMMIT;

-- ============================================
-- 2. INSERT FARM_ZONES (15 zones)
-- ============================================

-- Farmer 1 (john_doe) - 3 zones
INSERT INTO farm_zones (farmer_id, zone_name, crop_type, optimal_moisture, area_sqm, soil_type) VALUES 
(1001, 'North Field A', 'Corn', 65.5, 5000.00, 'LOAM');

INSERT INTO farm_zones (farmer_id, zone_name, crop_type, optimal_moisture, area_sqm, soil_type) VALUES 
(1001, 'South Field B', 'Tomatoes', 70.0, 3000.00, 'SANDY_LOAM');

INSERT INTO farm_zones (farmer_id, zone_name, crop_type, optimal_moisture, area_sqm, soil_type) VALUES 
(1001, 'Greenhouse 1', 'Lettuce', 75.0, 1000.00, 'CLAY');

-- Farmer 2 (jane_smith) - 2 zones
INSERT INTO farm_zones (farmer_id, zone_name, crop_type, optimal_moisture, area_sqm, soil_type) VALUES 
(1002, 'Main Field', 'Wheat', 60.0, 8000.00, 'LOAM');

INSERT INTO farm_zones (farmer_id, zone_name, crop_type, optimal_moisture, area_sqm, soil_type) VALUES 
(1002, 'Orchard', 'Apples', 55.0, 4000.00, 'SANDY');

-- Farmer 3 (robert_k) - 3 zones
INSERT INTO farm_zones (farmer_id, zone_name, crop_type, optimal_moisture, area_sqm, soil_type) VALUES 
(1003, 'Zone A', 'Potatoes', 68.0, 3500.00, 'LOAM');

INSERT INTO farm_zones (farmer_id, zone_name, crop_type, optimal_moisture, area_sqm, soil_type) VALUES 
(1003, 'Zone B', 'Carrots', 72.0, 2500.00, 'SANDY_LOAM');

INSERT INTO farm_zones (farmer_id, zone_name, crop_type, optimal_moisture, area_sqm, soil_type) VALUES 
(1003, 'Zone C', 'Beans', 67.5, 2000.00, 'CLAY_LOAM');

-- Farmer 4 (marie_u) - 3 zones
INSERT INTO farm_zones (farmer_id, zone_name, crop_type, optimal_moisture, area_sqm, soil_type) VALUES 
(1004, 'East Field', 'Rice', 80.0, 6000.00, 'CLAY');

INSERT INTO farm_zones (farmer_id, zone_name, crop_type, optimal_moisture, area_sqm, soil_type) VALUES 
(1004, 'West Field', 'Soybeans', 62.5, 4500.00, 'LOAM');

INSERT INTO farm_zones (farmer_id, zone_name, crop_type, optimal_moisture, area_sqm, soil_type) VALUES 
(1004, 'Nursery', 'Seedlings', 85.0, 500.00, 'SANDY');

-- Farmer 5 (paul_m) - 4 zones
INSERT INTO farm_zones (farmer_id, zone_name, crop_type, optimal_moisture, area_sqm, soil_type) VALUES 
(1005, 'Field 1', 'Coffee', 58.0, 7000.00, 'VOLCANIC');

INSERT INTO farm_zones (farmer_id, zone_name, crop_type, optimal_moisture, area_sqm, soil_type) VALUES 
(1005, 'Field 2', 'Tea', 63.0, 5500.00, 'ACIDIC');

INSERT INTO farm_zones (farmer_id, zone_name, crop_type, optimal_moisture, area_sqm, soil_type) VALUES 
(1005, 'Field 3', 'Bananas', 77.0, 3000.00, 'LOAM');

INSERT INTO farm_zones (farmer_id, zone_name, crop_type, optimal_moisture, area_sqm, soil_type) VALUES 
(1005, 'Field 4', 'Avocado', 59.0, 2500.00, 'WELL_DRAINED');

COMMIT;

-- ============================================
-- 3. INSERT SENSORS (30 sensors - 2 per zone)
-- ============================================

-- Generate 30 sensors (2 for each of 15 zones)
BEGIN
    FOR z IN 2001..2015 LOOP
        -- Sensor A
        INSERT INTO sensors (zone_id, sensor_code, battery_level) 
        VALUES (z, 'SENSOR_' || z || '_A', ROUND(DBMS_RANDOM.VALUE(70, 100)));
        
        -- Sensor B  
        INSERT INTO sensors (zone_id, sensor_code, battery_level)
        VALUES (z, 'SENSOR_' || z || '_B', ROUND(DBMS_RANDOM.VALUE(70, 100)));
    END LOOP;
    COMMIT;
END;
/

-- ============================================
-- 4. INSERT SENSOR_DATA (100+ readings)
-- ============================================

BEGIN
    FOR s IN 3001..3030 LOOP  -- 30 sensors
        FOR r IN 1..5 LOOP    -- 5 readings per sensor = 150 total
            INSERT INTO sensor_data (sensor_id, moisture_value, temperature, reading_time)
            VALUES (
                s,
                ROUND(DBMS_RANDOM.VALUE(40, 80), 2),
                ROUND(DBMS_RANDOM.VALUE(15, 35), 1),
                SYSTIMESTAMP - INTERVAL '7' DAY + INTERVAL '3' HOUR * ((s-3001)*5 + r)
            );
        END LOOP;
    END LOOP;
    COMMIT;
END;
/

-- ============================================
-- 5. INSERT IRRIGATION_VALVES (15 valves)
-- ============================================

BEGIN
    FOR z IN 2001..2015 LOOP
        INSERT INTO irrigation_valves (zone_id, valve_code, flow_rate)
        VALUES (z, 'VALVE_' || z, ROUND(DBMS_RANDOM.VALUE(8, 20), 1));
    END LOOP;
    COMMIT;
END;
/

-- ============================================
-- 6. INSERT IRRIGATION_LOGS (50+ events)
-- ============================================

BEGIN
    FOR i IN 1..50 LOOP
        INSERT INTO irrigation_logs (valve_id, zone_id, trigger_source, start_time, end_time, water_volume, initial_moisture, final_moisture, status)
        VALUES (
            5000 + MOD(i, 15) + 1,  -- Random valve (5001-5015)
            2000 + MOD(i, 15) + 1,  -- Corresponding zone (2001-2015)
            CASE MOD(i, 10) 
                WHEN 0 THEN 'MANUAL' 
                WHEN 5 THEN 'SCHEDULED'
                ELSE 'AUTO' 
            END,
            SYSTIMESTAMP - INTERVAL '30' DAY + INTERVAL '12' HOUR * i,
            SYSTIMESTAMP - INTERVAL '30' DAY + INTERVAL '12' HOUR * i + NUMTODSINTERVAL(DBMS_RANDOM.VALUE(10, 40), 'MINUTE'),
            ROUND(DBMS_RANDOM.VALUE(200, 800), 2),
            ROUND(DBMS_RANDOM.VALUE(40, 60), 2),
            ROUND(DBMS_RANDOM.VALUE(65, 80), 2),
            CASE MOD(i, 20) 
                WHEN 0 THEN 'FAILED' 
                WHEN 10 THEN 'INTERRUPTED'
                ELSE 'COMPLETED' 
            END
        );
    END LOOP;
    COMMIT;
END;
/

-- ============================================
-- 7. VERIFY DATA INSERTION
-- ============================================

PROMPT === DATA COUNT VERIFICATION ===

SELECT 'FARMERS' as table_name, COUNT(*) as row_count FROM farmers
UNION ALL
SELECT 'FARM_ZONES', COUNT(*) FROM farm_zones
UNION ALL
SELECT 'SENSORS', COUNT(*) FROM sensors
UNION ALL
SELECT 'SENSOR_DATA', COUNT(*) FROM sensor_data
UNION ALL
SELECT 'VALVES', COUNT(*) FROM irrigation_valves
UNION ALL
SELECT 'IRRIGATION_LOGS', COUNT(*) FROM irrigation_logs
ORDER BY 1;

PROMPT === Sample data (first 2 rows each) ===
SELECT * FROM farmers WHERE ROWNUM <= 2;
SELECT * FROM farm_zones WHERE ROWNUM <= 2;
SELECT * FROM sensors WHERE ROWNUM <= 2;
SELECT * FROM sensor_data WHERE ROWNUM <= 2;
SELECT * FROM irrigation_valves WHERE ROWNUM <= 2;
SELECT * FROM irrigation_logs WHERE ROWNUM <= 2;

PROMPT === Data insertion completed successfully! ===
