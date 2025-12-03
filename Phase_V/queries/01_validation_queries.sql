-- ============================================
-- AQUASMART DATA VALIDATION QUERIES
-- ============================================

-- Connect as application user
CONNECT aqua_app_user/AquaSmart2025@localhost:1521/D_27897_Uwineza_AquaSmart_DB;

SET SERVEROUTPUT ON;
SET FEEDBACK ON;
SET LINESIZE 200;
SET PAGESIZE 50;

-- ============================================
-- 1. DATA COMPLETENESS VALIDATION
-- ============================================

PROMPT =========== DATA COMPLETENESS CHECK ===========

-- Check total record counts
SELECT 'FARMERS' AS table_name, COUNT(*) AS record_count FROM farmers
UNION ALL
SELECT 'FARM_ZONES', COUNT(*) FROM farm_zones
UNION ALL
SELECT 'SENSORS', COUNT(*) FROM sensors
UNION ALL
SELECT 'SENSOR_DATA', COUNT(*) FROM sensor_data
UNION ALL
SELECT 'IRRIGATION_VALVES', COUNT(*) FROM irrigation_valves
UNION ALL
SELECT 'IRRIGATION_LOGS', COUNT(*) FROM irrigation_logs
UNION ALL
SELECT 'WEATHER_DATA', COUNT(*) FROM weather_data
ORDER BY record_count DESC;

-- Check for NULL values in critical columns
PROMPT =========== NULL VALUE CHECK ===========

SELECT 'FARMERS.username' AS column_name, COUNT(*) AS null_count 
FROM farmers WHERE username IS NULL
UNION ALL
SELECT 'FARMERS.email', COUNT(*) FROM farmers WHERE email IS NULL
UNION ALL
SELECT 'FARM_ZONES.zone_name', COUNT(*) FROM farm_zones WHERE zone_name IS NULL
UNION ALL
SELECT 'FARM_ZONES.optimal_moisture', COUNT(*) FROM farm_zones WHERE optimal_moisture IS NULL
UNION ALL
SELECT 'SENSOR_DATA.moisture_value', COUNT(*) FROM sensor_data WHERE moisture_value IS NULL
UNION ALL
SELECT 'SENSOR_DATA.reading_time', COUNT(*) FROM sensor_data WHERE reading_time IS NULL
UNION ALL
SELECT 'IRRIGATION_LOGS.start_time', COUNT(*) FROM irrigation_logs WHERE start_time IS NULL
UNION ALL
SELECT 'IRRIGATION_LOGS.water_volume', COUNT(*) FROM irrigation_logs WHERE water_volume IS NULL;

-- ============================================
-- 2. DATA INTEGRITY VALIDATION
-- ============================================

PROMPT =========== FOREIGN KEY INTEGRITY ===========

-- Check for orphan records
SELECT 'farm_zones without farmer' AS issue, COUNT(*) AS count
FROM farm_zones z
WHERE NOT EXISTS (SELECT 1 FROM farmers f WHERE f.farmer_id = z.farmer_id)
UNION ALL
SELECT 'sensors without zone', COUNT(*)
FROM sensors s
WHERE NOT EXISTS (SELECT 1 FROM farm_zones z WHERE z.zone_id = s.zone_id)
UNION ALL
SELECT 'sensor_data without sensor', COUNT(*)
FROM sensor_data sd
WHERE NOT EXISTS (SELECT 1 FROM sensors s WHERE s.sensor_id = sd.sensor_id)
UNION ALL
SELECT 'valves without zone', COUNT(*)
FROM irrigation_valves v
WHERE NOT EXISTS (SELECT 1 FROM farm_zones z WHERE z.zone_id = v.zone_id)
UNION ALL
SELECT 'logs without valve', COUNT(*)
FROM irrigation_logs l
WHERE NOT EXISTS (SELECT 1 FROM irrigation_valves v WHERE v.valve_id = l.valve_id)
UNION ALL
SELECT 'logs without zone', COUNT(*)
FROM irrigation_logs l
WHERE NOT EXISTS (SELECT 1 FROM farm_zones z WHERE z.zone_id = l.zone_id);

-- ============================================
-- 3. DATA QUALITY VALIDATION
-- ============================================

PROMPT =========== DATA QUALITY CHECKS ===========

-- Check moisture values within valid range (0-100%)
SELECT 'Invalid moisture values' AS check_type, COUNT(*) AS count
FROM sensor_data 
WHERE moisture_value < 0 OR moisture_value > 100;

-- Check temperature values (reasonable for agriculture)
SELECT 'Extreme temperature values' AS check_type, COUNT(*) AS count
FROM sensor_data 
WHERE temperature < -10 OR temperature > 60;

-- Check battery levels
SELECT 'Invalid battery levels' AS check_type, COUNT(*) AS count
FROM sensors 
WHERE battery_level < 0 OR battery_level > 100;

-- Check area values
SELECT 'Invalid area values' AS check_type, COUNT(*) AS count
FROM farm_zones 
WHERE area_sqm <= 0;

-- Check water volume values
SELECT 'Invalid water volume' AS check_type, COUNT(*) AS count
FROM irrigation_logs 
WHERE water_volume < 0;

-- ============================================
-- 4. BUSINESS RULE VALIDATION
-- ============================================

PROMPT =========== BUSINESS RULE VALIDATION ===========

-- Rule 1: Final moisture should be >= initial moisture after irrigation
SELECT 'Irrigation logs with final < initial moisture' AS rule_violation, COUNT(*) AS count
FROM irrigation_logs 
WHERE final_moisture < initial_moisture;

-- Rule 2: End time should be after start time
SELECT 'Irrigation logs with end <= start time' AS rule_violation, COUNT(*) AS count
FROM irrigation_logs 
WHERE end_time <= start_time;

-- Rule 3: Active farmers should have active zones
SELECT 'Active farmers with no active zones' AS rule_violation, COUNT(DISTINCT f.farmer_id) AS count
FROM farmers f
LEFT JOIN farm_zones z ON f.farmer_id = z.farmer_id AND z.status = 'ACTIVE'
WHERE f.status = 'ACTIVE' AND z.zone_id IS NULL;

-- Rule 4: Sensors should have recent data (within last 7 days)
SELECT 'Active sensors with no recent data' AS rule_violation, COUNT(*) AS count
FROM sensors s
WHERE s.status = 'ACTIVE'
AND NOT EXISTS (
    SELECT 1 FROM sensor_data sd 
    WHERE sd.sensor_id = s.sensor_id 
    AND sd.reading_time > SYSDATE - 7
);

-- ============================================
-- 5. CONSTRAINT VALIDATION
-- ============================================

PROMPT =========== CONSTRAINT VALIDATION ===========

-- Check unique constraints
SELECT 'Duplicate usernames' AS constraint_check, COUNT(*) - COUNT(DISTINCT username) AS violations
FROM farmers
UNION ALL
SELECT 'Duplicate emails', COUNT(*) - COUNT(DISTINCT email)
FROM farmers
UNION ALL
SELECT 'Duplicate zone names per farmer', COUNT(*) - COUNT(DISTINCT farmer_id || zone_name)
FROM farm_zones
UNION ALL
SELECT 'Duplicate sensor codes', COUNT(*) - COUNT(DISTINCT sensor_code)
FROM sensors
UNION ALL
SELECT 'Duplicate valve codes', COUNT(*) - COUNT(DISTINCT valve_code)
FROM irrigation_valves;

-- ============================================
-- 6. DATA CONSISTENCY VALIDATION
-- ============================================

PROMPT =========== DATA CONSISTENCY CHECKS ===========

-- Check if irrigation happened when moisture was actually low
SELECT 'Irrigation when moisture was high' AS consistency_check, COUNT(*) AS count
FROM irrigation_logs l
JOIN sensor_data sd ON l.zone_id = (
    SELECT zone_id FROM sensors WHERE sensor_id = (
        SELECT sensor_id FROM (
            SELECT sensor_id, ROW_NUMBER() OVER (ORDER BY reading_time DESC) rn
            FROM sensor_data sd2 
            JOIN sensors s2 ON sd2.sensor_id = s2.sensor_id
            WHERE s2.zone_id = l.zone_id
            AND sd2.reading_time <= l.start_time
        ) WHERE rn = 1
    )
)
WHERE sd.reading_time <= l.start_time
AND sd.moisture_value > 60; -- Moisture above 60% shouldn't need irrigation

-- Check sensor readings frequency (should be ~15 minutes)
SELECT 'Sensor reading gaps > 30 minutes' AS consistency_check, COUNT(*) AS count
FROM (
    SELECT sensor_id, reading_time,
           LAG(reading_time) OVER (PARTITION BY sensor_id ORDER BY reading_time) AS prev_time
    FROM sensor_data
) 
WHERE prev_time IS NOT NULL 
AND (reading_time - prev_time) * 1440 > 30; -- Gap > 30 minutes

-- ============================================
-- 7. SUMMARY REPORT
-- ============================================

PROMPT =========== VALIDATION SUMMARY ===========

DECLARE
    total_checks NUMBER := 0;
    passed_checks NUMBER := 0;
    failed_checks NUMBER := 0;
BEGIN
    -- Count total records check
    total_checks := total_checks + 1;
    IF (SELECT COUNT(*) FROM farmers) >= 100 THEN
        passed_checks := passed_checks + 1;
    ELSE
        failed_checks := failed_checks + 1;
    END IF;
    
    -- Count NULL check
    total_checks := total_checks + 1;
    IF (SELECT SUM(null_count) FROM (
        SELECT COUNT(*) AS null_count FROM farmers WHERE username IS NULL
        UNION ALL SELECT COUNT(*) FROM farmers WHERE email IS NULL
        UNION ALL SELECT COUNT(*) FROM farm_zones WHERE zone_name IS NULL
    )) = 0 THEN
        passed_checks := passed_checks + 1;
    ELSE
        failed_checks := failed_checks + 1;
    END IF;
    
    -- Foreign key integrity check
    total_checks := total_checks + 1;
    IF (SELECT SUM(count) FROM (
        SELECT COUNT(*) AS count FROM farm_zones z
        WHERE NOT EXISTS (SELECT 1 FROM farmers f WHERE f.farmer_id = z.farmer_id)
    )) = 0 THEN
        passed_checks := passed_checks + 1;
    ELSE
        failed_checks := failed_checks + 1;
    END IF;
    
    -- Data quality check
    total_checks := total_checks + 1;
    IF (SELECT COUNT(*) FROM sensor_data WHERE moisture_value < 0 OR moisture_value > 100) = 0 THEN
        passed_checks := passed_checks + 1;
    ELSE
        failed_checks := failed_checks + 1;
    END IF;
    
    -- Business rule check
    total_checks := total_checks + 1;
    IF (SELECT COUNT(*) FROM irrigation_logs WHERE final_moisture < initial_moisture) = 0 THEN
        passed_checks := passed_checks + 1;
    ELSE
        failed_checks := failed_checks + 1;
    END IF;
    
    DBMS_OUTPUT.PUT_LINE('Total checks performed: ' || total_checks);
    DBMS_OUTPUT.PUT_LINE('Checks passed: ' || passed_checks);
    DBMS_OUTPUT.PUT_LINE('Checks failed: ' || failed_checks);
    DBMS_OUTPUT.PUT_LINE('Success rate: ' || ROUND((passed_checks/total_checks)*100, 2) || '%');
    
    IF failed_checks = 0 THEN
        DBMS_OUTPUT.PUT_LINE('✅ ALL VALIDATION CHECKS PASSED!');
    ELSE
        DBMS_OUTPUT.PUT_LINE('⚠️  SOME VALIDATION CHECKS FAILED. Review above results.');
    END IF;
END;
/

COMMIT;