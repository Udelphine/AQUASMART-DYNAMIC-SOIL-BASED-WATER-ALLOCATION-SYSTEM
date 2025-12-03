-- ============================================
-- AQUASMART TEST QUERIES
-- ============================================

-- Connect as application user
CONNECT aqua_app_user/AquaSmart2025@localhost:1521/D_27897_Uwineza_AquaSmart_DB;

SET SERVEROUTPUT ON;
SET FEEDBACK ON;
SET LINESIZE 200;
SET PAGESIZE 50;

-- ============================================
-- 1. BASIC RETRIEVAL QUERIES (SELECT *)
-- ============================================

PROMPT =========== BASIC RETRIEVAL QUERIES ===========

-- 1.1 Select all active farmers
SELECT * FROM farmers 
WHERE status = 'ACTIVE' 
AND ROWNUM <= 5
ORDER BY farmer_id;

-- 1.2 Select all active zones with farmer info
SELECT z.zone_id, z.zone_name, z.crop_type, z.optimal_moisture,
       f.username, f.first_name, f.last_name
FROM farm_zones z
JOIN farmers f ON z.farmer_id = f.farmer_id
WHERE z.status = 'ACTIVE'
AND ROWNUM <= 10
ORDER BY z.zone_id;

-- 1.3 Select recent sensor data
SELECT * FROM sensor_data 
WHERE reading_time > SYSDATE - 1
ORDER BY reading_time DESC
FETCH FIRST 10 ROWS ONLY;

-- ============================================
-- 2. JOIN QUERIES (Multi-table queries)
-- ============================================

PROMPT =========== JOIN QUERIES ===========

-- 2.1 Farmer with all their zones and sensors
SELECT 
    f.username AS farmer,
    z.zone_name,
    z.crop_type,
    COUNT(s.sensor_id) AS sensor_count,
    COUNT(v.valve_id) AS valve_count
FROM farmers f
JOIN farm_zones z ON f.farmer_id = z.farmer_id
LEFT JOIN sensors s ON z.zone_id = s.zone_id
LEFT JOIN irrigation_valves v ON z.zone_id = v.zone_id
WHERE f.status = 'ACTIVE' AND z.status = 'ACTIVE'
GROUP BY f.username, z.zone_name, z.crop_type
ORDER BY f.username, z.zone_name
FETCH FIRST 15 ROWS ONLY;

-- 2.2 Sensor data with zone and farmer info
SELECT 
    sd.data_id,
    sd.reading_time,
    sd.moisture_value,
    sd.temperature,
    z.zone_name,
    z.crop_type,
    f.username AS farmer
FROM sensor_data sd
JOIN sensors s ON sd.sensor_id = s.sensor_id
JOIN farm_zones z ON s.zone_id = z.zone_id
JOIN farmers f ON z.farmer_id = f.farmer_id
WHERE sd.reading_time > SYSDATE - 7
ORDER BY sd.reading_time DESC
FETCH FIRST 10 ROWS ONLY;

-- 2.3 Irrigation logs with complete hierarchy
SELECT 
    l.log_id,
    l.start_time,
    l.water_volume,
    l.trigger_source,
    v.valve_code,
    z.zone_name,
    z.crop_type,
    f.username AS farmer
FROM irrigation_logs l
JOIN irrigation_valves v ON l.valve_id = v.valve_id
JOIN farm_zones z ON l.zone_id = z.zone_id
JOIN farmers f ON z.farmer_id = f.farmer_id
WHERE l.start_time > SYSDATE - 30
ORDER BY l.start_time DESC
FETCH FIRST 10 ROWS ONLY;

-- ============================================
-- 3. AGGREGATION QUERIES (GROUP BY)
-- ============================================

PROMPT =========== AGGREGATION QUERIES ===========

-- 3.1 Water usage by farmer
SELECT 
    f.username,
    COUNT(l.log_id) AS irrigation_count,
    SUM(l.water_volume) AS total_water_liters,
    ROUND(AVG(l.water_volume), 2) AS avg_water_per_irrigation,
    MIN(l.start_time) AS first_irrigation,
    MAX(l.start_time) AS last_irrigation
FROM farmers f
JOIN farm_zones z ON f.farmer_id = z.farmer_id
JOIN irrigation_logs l ON z.zone_id = l.zone_id
GROUP BY f.username
ORDER BY total_water_liters DESC
FETCH FIRST 10 ROWS ONLY;

-- 3.2 Sensor readings by hour of day
SELECT 
    EXTRACT(HOUR FROM reading_time) AS hour_of_day,
    COUNT(*) AS reading_count,
    ROUND(AVG(moisture_value), 2) AS avg_moisture,
    ROUND(AVG(temperature), 2) AS avg_temperature
FROM sensor_data
WHERE reading_time > SYSDATE - 7
GROUP BY EXTRACT(HOUR FROM reading_time)
ORDER BY hour_of_day;

-- 3.3 Crop type performance analysis
SELECT 
    z.crop_type,
    COUNT(DISTINCT z.zone_id) AS zone_count,
    ROUND(AVG(z.optimal_moisture), 2) AS target_moisture,
    ROUND(AVG(sd.moisture_value), 2) AS actual_moisture,
    COUNT(DISTINCT l.log_id) AS irrigation_count,
    ROUND(SUM(l.water_volume) / SUM(z.area_sqm), 2) AS water_per_sqm
FROM farm_zones z
LEFT JOIN sensors s ON z.zone_id = s.zone_id
LEFT JOIN sensor_data sd ON s.sensor_id = sd.sensor_id AND sd.reading_time > SYSDATE - 30
LEFT JOIN irrigation_logs l ON z.zone_id = l.zone_id AND l.start_time > SYSDATE - 30
WHERE z.status = 'ACTIVE'
GROUP BY z.crop_type
ORDER BY zone_count DESC;

-- ============================================
-- 4. SUBQUERIES
-- ============================================

PROMPT =========== SUBQUERY EXAMPLES ===========

-- 4.1 Farmers with above average number of zones
SELECT 
    f.username,
    f.first_name || ' ' || f.last_name AS full_name,
    (SELECT COUNT(*) FROM farm_zones z WHERE z.farmer_id = f.farmer_id) AS zone_count
FROM farmers f
WHERE (SELECT COUNT(*) FROM farm_zones z WHERE z.farmer_id = f.farmer_id) > 
      (SELECT AVG(zone_count) FROM (
          SELECT farmer_id, COUNT(*) AS zone_count 
          FROM farm_zones 
          GROUP BY farmer_id
      ))
ORDER BY zone_count DESC
FETCH FIRST 10 ROWS ONLY;

-- 4.2 Zones that need irrigation (moisture below optimal)
SELECT 
    z.zone_id,
    z.zone_name,
    z.crop_type,
    z.optimal_moisture,
    (SELECT sd.moisture_value 
     FROM sensor_data sd 
     JOIN sensors s ON sd.sensor_id = s.sensor_id
     WHERE s.zone_id = z.zone_id 
     AND sd.reading_time = (
         SELECT MAX(reading_time) 
         FROM sensor_data sd2 
         JOIN sensors s2 ON sd2.sensor_id = s2.sensor_id
         WHERE s2.zone_id = z.zone_id
     )) AS current_moisture
FROM farm_zones z
WHERE z.status = 'ACTIVE'
AND (SELECT sd.moisture_value 
     FROM sensor_data sd 
     JOIN sensors s ON sd.sensor_id = s.sensor_id
     WHERE s.zone_id = z.zone_id 
     AND sd.reading_time = (
         SELECT MAX(reading_time) 
         FROM sensor_data sd2 
         JOIN sensors s2 ON sd2.sensor_id = s2.sensor_id
         WHERE s2.zone_id = z.zone_id
     )) < z.optimal_moisture * 0.9
ORDER BY z.zone_id
FETCH FIRST 10 ROWS ONLY;

-- 4.3 Most active sensors (most readings in last 24 hours)
SELECT 
    s.sensor_code,
    z.zone_name,
    (SELECT COUNT(*) 
     FROM sensor_data sd 
     WHERE sd.sensor_id = s.sensor_id 
     AND sd.reading_time > SYSDATE - 1) AS readings_last_24h,
    (SELECT ROUND(AVG(moisture_value), 2)
     FROM sensor_data sd 
     WHERE sd.sensor_id = s.sensor_id 
     AND sd.reading_time > SYSDATE - 1) AS avg_moisture
FROM sensors s
JOIN farm_zones z ON s.zone_id = z.zone_id
WHERE s.status = 'ACTIVE'
ORDER BY readings_last_24h DESC
FETCH FIRST 10 ROWS ONLY;

-- ============================================
-- 5. ADVANCED QUERIES (Window functions preview)
-- ============================================

PROMPT =========== ADVANCED QUERIES ===========

-- 5.1 Rank farmers by water usage
SELECT 
    username,
    total_water,
    RANK() OVER (ORDER BY total_water DESC) AS water_usage_rank,
    ROUND(PERCENT_RANK() OVER (ORDER BY total_water DESC) * 100, 2) AS percentile
FROM (
    SELECT 
        f.username,
        SUM(l.water_volume) AS total_water
    FROM farmers f
    JOIN farm_zones z ON f.farmer_id = z.farmer_id
    JOIN irrigation_logs l ON z.zone_id = l.zone_id
    WHERE l.start_time > SYSDATE - 30
    GROUP BY f.username
)
ORDER BY water_usage_rank
FETCH FIRST 10 ROWS ONLY;

-- 5.2 Moisture trends over time for a specific zone
SELECT 
    reading_time,
    moisture_value,
    ROUND(AVG(moisture_value) OVER (
        ORDER BY reading_time 
        ROWS BETWEEN 3 PRECEDING AND 3 FOLLOWING
    ), 2) AS moving_avg,
    moisture_value - LAG(moisture_value, 1) OVER (ORDER BY reading_time) AS change_from_previous
FROM sensor_data sd
JOIN sensors s ON sd.sensor_id = s.sensor_id
WHERE s.zone_id = (SELECT MIN(zone_id) FROM farm_zones)
AND reading_time > SYSDATE - 3
ORDER BY reading_time
FETCH FIRST 20 ROWS ONLY;

-- ============================================
-- 6. PERFORMANCE TESTING QUERIES
-- ============================================

PROMPT =========== PERFORMANCE TESTING ===========

-- 6.1 Query execution time test
SET TIMING ON;

-- Test 1: Simple count
SELECT COUNT(*) AS total_sensor_readings FROM sensor_data;

-- Test 2: Complex join with aggregation
SELECT 
    f.username,
    COUNT(DISTINCT z.zone_id) AS zones,
    COUNT(DISTINCT s.sensor_id) AS sensors,
    SUM(l.water_volume) AS total_water
FROM farmers f
JOIN farm_zones z ON f.farmer_id = z.farmer_id
LEFT JOIN sensors s ON z.zone_id = s.zone_id
LEFT JOIN irrigation_logs l ON z.zone_id = l.zone_id
WHERE f.status = 'ACTIVE'
GROUP BY f.username
ORDER BY total_water DESC;

-- Test 3: Subquery performance
SELECT 
    zone_id,
    zone_name,
    (SELECT COUNT(*) FROM sensors s WHERE s.zone_id = z.zone_id) AS sensor_count,
    (SELECT COUNT(*) FROM irrigation_logs l WHERE l.zone_id = z.zone_id) AS irrigation_count
FROM farm_zones z
WHERE z.status = 'ACTIVE'
FETCH FIRST 20 ROWS ONLY;

SET TIMING OFF;

-- ============================================
-- 7. TEST RESULTS SUMMARY
-- ============================================

PROMPT =========== TEST SUMMARY ===========

DECLARE
    total_tests NUMBER := 0;
    successful_tests NUMBER := 0;
BEGIN
    -- Test 1: Basic retrieval
    total_tests := total_tests + 1;
    IF (SELECT COUNT(*) FROM farmers WHERE status = 'ACTIVE' AND ROWNUM <= 5) > 0 THEN
        successful_tests := successful_tests + 1;
        DBMS_OUTPUT.PUT_LINE('✅ Test 1: Basic retrieval - PASSED');
    ELSE
        DBMS_OUTPUT.PUT_LINE('❌ Test 1: Basic retrieval - FAILED');
    END IF;
    
    -- Test 2: Join query
    total_tests := total_tests + 1;
    IF (SELECT COUNT(*) FROM (
        SELECT f.username, z.zone_name
        FROM farmers f
        JOIN farm_zones z ON f.farmer_id = z.farmer_id
        WHERE ROWNUM <= 1
    )) > 0 THEN
        successful_tests := successful_tests + 1;
        DBMS_OUTPUT.PUT_LINE('✅ Test 2: Join query - PASSED');
    ELSE
        DBMS_OUTPUT.PUT_LINE('❌ Test 2: Join query - FAILED');
    END IF;
    
    -- Test 3: Aggregation
    total_tests := total_tests + 1;
    IF (SELECT COUNT(DISTINCT crop_type) FROM farm_zones) > 0 THEN
        successful_tests := successful_tests + 1;
        DBMS_OUTPUT.PUT_LINE('✅ Test 3: Aggregation - PASSED');
    ELSE
        DBMS_OUTPUT.PUT_LINE('❌ Test 3: Aggregation - FAILED');
    END IF;
    
    -- Test 4: Subquery
    total_tests := total_tests + 1;
    IF (SELECT COUNT(*) FROM (
        SELECT farmer_id, (SELECT COUNT(*) FROM farm_zones z WHERE z.farmer_id = f.farmer_id) AS zone_count
        FROM farmers f
        WHERE ROWNUM <= 1
    )) > 0 THEN
        successful_tests := successful_tests + 1;
        DBMS_OUTPUT.PUT_LINE('✅ Test 4: Subquery - PASSED');
    ELSE
        DBMS_OUTPUT.PUT_LINE('❌ Test 4: Subquery - FAILED');
    END IF;
    
    DBMS_OUTPUT.PUT_LINE('=====================================');
    DBMS_OUTPUT.PUT_LINE('Total tests: ' || total_tests);
    DBMS_OUTPUT.PUT_LINE('Successful: ' || successful_tests);
    DBMS_OUTPUT.PUT_LINE('Failed: ' || (total_tests - successful_tests));
    DBMS_OUTPUT.PUT_LINE('Success rate: ' || ROUND((successful_tests/total_tests)*100, 2) || '%');
    
    IF successful_tests = total_tests THEN
        DBMS_OUTPUT.PUT_LINE('✅ ALL TESTS PASSED SUCCESSFULLY!');
    ELSE
        DBMS_OUTPUT.PUT_LINE('⚠️  SOME TESTS FAILED. Review query results above.');
    END IF;
END;
/

COMMIT;