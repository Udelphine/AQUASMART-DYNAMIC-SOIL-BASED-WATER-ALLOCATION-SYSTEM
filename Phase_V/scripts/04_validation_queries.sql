-- ============================================
-- AquaSmart: VALIDATION QUERIES Script
-- Student: Uwineza Delphine | ID: 27897
-- Date: 2025-12-04
-- 
-- REQUIRED: Basic retrieval, joins, aggregations, subqueries
-- ============================================

-- Connect as application user
CONNECT aqua_app_user/AquaSmart2025@localhost:1521/D_27897_Uwineza_AquaSmart_DB;

-- ============================================
-- 1. BASIC RETRIEVAL (SELECT) - REQUIRED
-- ============================================

PROMPT === 1. BASIC RETRIEVAL QUERIES ===

-- 1.1 Select all active farmers
SELECT * FROM farmers WHERE status = 'ACTIVE';

-- 1.2 Select zones with area greater than 2000 sqm
SELECT zone_id, zone_name, crop_type, area_sqm 
FROM farm_zones 
WHERE area_sqm > 2000 
ORDER BY area_sqm DESC;

-- 1.3 Select sensor readings with moisture below 50%
SELECT data_id, sensor_id, moisture_value, reading_time 
FROM sensor_data 
WHERE moisture_value < 50 
ORDER BY reading_time DESC;

-- 1.4 Select irrigation logs from the last 7 days
SELECT log_id, valve_id, zone_id, start_time, water_volume 
FROM irrigation_logs 
WHERE start_time > SYSTIMESTAMP - INTERVAL '7' DAY 
AND status = 'COMPLETED';

-- 1.5 Select sensors with low battery (< 30%)
SELECT sensor_id, sensor_code, zone_id, battery_level, status
FROM sensors 
WHERE battery_level < 30 
AND status = 'ACTIVE';

-- ============================================
-- 2. JOINS (Multi-table queries) - REQUIRED
-- ============================================

PROMPT === 2. JOIN QUERIES ===

-- 2.1 Farmers with their zones (INNER JOIN)
SELECT f.username, f.first_name || ' ' || f.last_name as farmer_name,
       fz.zone_name, fz.crop_type, fz.optimal_moisture, fz.area_sqm
FROM farmers f
INNER JOIN farm_zones fz ON f.farmer_id = fz.farmer_id
WHERE f.status = 'ACTIVE'
ORDER BY f.username, fz.zone_name;

-- 2.2 All sensors with their zone and crop info (3-table JOIN)
SELECT s.sensor_code, fz.zone_name, fz.crop_type, 
       s.battery_level, s.installation_date,
       f.username as farmer_username
FROM sensors s
JOIN farm_zones fz ON s.zone_id = fz.zone_id
JOIN farmers f ON fz.farmer_id = f.farmer_id
WHERE s.status = 'ACTIVE'
ORDER BY fz.zone_name, s.sensor_code;

-- 2.3 Complete irrigation history with details (4-table JOIN)
SELECT il.log_id, v.valve_code, fz.zone_name, fz.crop_type,
       f.username as farmer_name,
       il.start_time, il.end_time,
       ROUND((il.end_time - il.start_time) * 24 * 60, 2) as duration_minutes,
       il.water_volume, il.trigger_source, il.status
FROM irrigation_logs il
JOIN irrigation_valves v ON il.valve_id = v.valve_id
JOIN farm_zones fz ON il.zone_id = fz.zone_id
JOIN farmers f ON fz.farmer_id = f.farmer_id
ORDER BY il.start_time DESC;

-- 2.4 LEFT JOIN: All zones with their sensors (even zones without sensors)
SELECT fz.zone_name, fz.crop_type,
       COUNT(s.sensor_id) as sensor_count,
       LISTAGG(s.sensor_code, ', ') WITHIN GROUP (ORDER BY s.sensor_code) as sensor_codes
FROM farm_zones fz
LEFT JOIN sensors s ON fz.zone_id = s.zone_id
GROUP BY fz.zone_name, fz.crop_type
ORDER BY fz.zone_name;

-- ============================================
-- 3. AGGREGATIONS (GROUP BY) - REQUIRED
-- ============================================

PROMPT === 3. AGGREGATION QUERIES ===

-- 3.1 Average moisture by zone (with HAVING clause)
SELECT fz.zone_name, fz.crop_type, fz.optimal_moisture,
       ROUND(AVG(sd.moisture_value), 2) as avg_current_moisture,
       MIN(sd.moisture_value) as min_moisture,
       MAX(sd.moisture_value) as max_moisture,
       COUNT(*) as readings_count
FROM sensor_data sd
JOIN sensors s ON sd.sensor_id = s.sensor_id
JOIN farm_zones fz ON s.zone_id = fz.zone_id
WHERE sd.reading_time > SYSTIMESTAMP - INTERVAL '1' DAY
GROUP BY fz.zone_name, fz.crop_type, fz.optimal_moisture
HAVING AVG(sd.moisture_value) < fz.optimal_moisture * 0.9  -- Zones needing irrigation
ORDER BY avg_current_moisture ASC;

-- 3.2 Water usage summary per farmer
SELECT f.username, 
       f.first_name || ' ' || f.last_name as farmer_name,
       COUNT(DISTINCT fz.zone_id) as zones_owned,
       COUNT(il.log_id) as total_irrigations,
       SUM(il.water_volume) as total_water_liters,
       ROUND(AVG(il.water_volume), 2) as avg_water_per_irrigation,
       MIN(il.start_time) as first_irrigation,
       MAX(il.start_time) as last_irrigation
FROM farmers f
JOIN farm_zones fz ON f.farmer_id = fz.farmer_id
LEFT JOIN irrigation_logs il ON fz.zone_id = il.zone_id
GROUP BY f.username, f.first_name, f.last_name
ORDER BY total_water_liters DESC;

-- 3.3 Monthly water usage trend
SELECT 
    TO_CHAR(TRUNC(start_time, 'MM'), 'YYYY-MM') as month,
    COUNT(*) as irrigation_count,
    SUM(water_volume) as total_water_liters,
    ROUND(AVG(water_volume), 2) as avg_water_per_event,
    MIN(water_volume) as min_water,
    MAX(water_volume) as max_water
FROM irrigation_logs
WHERE status = 'COMPLETED'
GROUP BY TO_CHAR(TRUNC(start_time, 'MM'), 'YYYY-MM')
ORDER BY month DESC;

-- 3.4 Sensor performance statistics
SELECT 
    CASE 
        WHEN battery_level > 80 THEN 'HIGH (80-100%)'
        WHEN battery_level > 50 THEN 'MEDIUM (50-80%)'
        WHEN battery_level > 20 THEN 'LOW (20-50%)'
        ELSE 'CRITICAL (<20%)'
    END as battery_status,
    COUNT(*) as sensor_count,
    ROUND(AVG(battery_level), 2) as avg_battery,
    MIN(battery_level) as min_battery,
    MAX(battery_level) as max_battery
FROM sensors
WHERE status = 'ACTIVE'
GROUP BY 
    CASE 
        WHEN battery_level > 80 THEN 'HIGH (80-100%)'
        WHEN battery_level > 50 THEN 'MEDIUM (50-80%)'
        WHEN battery_level > 20 THEN 'LOW (20-50%)'
        ELSE 'CRITICAL (<20%)'
    END
ORDER BY sensor_count DESC;

-- ============================================
-- 4. SUBQUERIES - REQUIRED
-- ============================================

PROMPT === 4. SUBQUERY EXAMPLES ===

-- 4.1 Correlated subquery: Zones needing immediate irrigation
SELECT zone_name, crop_type, optimal_moisture,
       (SELECT ROUND(AVG(moisture_value), 2)
        FROM sensor_data sd
        JOIN sensors s ON sd.sensor_id = s.sensor_id
        WHERE s.zone_id = fz.zone_id
        AND sd.reading_time > SYSTIMESTAMP - INTERVAL '3' HOUR) as current_avg_moisture
FROM farm_zones fz
WHERE (SELECT ROUND(AVG(moisture_value), 2)
       FROM sensor_data sd
       JOIN sensors s ON sd.sensor_id = s.sensor_id
       WHERE s.zone_id = fz.zone_id
       AND sd.reading_time > SYSTIMESTAMP - INTERVAL '3' HOUR) < optimal_moisture * 0.85
ORDER BY current_avg_moisture ASC;

-- 4.2 Nested subquery: Farmers with above-average zones
SELECT username, email,
       (SELECT COUNT(*) FROM farm_zones WHERE farmer_id = f.farmer_id) as zone_count
FROM farmers f
WHERE (SELECT COUNT(*) FROM farm_zones WHERE farmer_id = f.farmer_id) > 
      (SELECT AVG(zone_count) FROM 
        (SELECT farmer_id, COUNT(*) as zone_count FROM farm_zones GROUP BY farmer_id))
ORDER BY zone_count DESC;

-- 4.3 IN subquery: Zones that have been irrigated in the last 24 hours
SELECT zone_name, crop_type, area_sqm
FROM farm_zones
WHERE zone_id IN (
    SELECT DISTINCT zone_id
    FROM irrigation_logs
    WHERE start_time > SYSTIMESTAMP - INTERVAL '1' DAY
    AND status = 'COMPLETED'
)
ORDER BY zone_name;

-- 4.4 EXISTS subquery: Sensors that have reported data today
SELECT s.sensor_code, s.battery_level, fz.zone_name
FROM sensors s
JOIN farm_zones fz ON s.zone_id = fz.zone_id
WHERE EXISTS (
    SELECT 1
    FROM sensor_data sd
    WHERE sd.sensor_id = s.sensor_id
    AND sd.reading_time > TRUNC(SYSTIMESTAMP)
)
ORDER BY s.sensor_code;

-- ============================================
-- 5. DATA INTEGRITY VALIDATION
-- ============================================

PROMPT === 5. DATA INTEGRITY CHECKS ===

-- 5.1 Check for orphaned records (foreign key violations)
SELECT 'Farm zones without valid farmer' as issue, COUNT(*) as count
FROM farm_zones fz
WHERE NOT EXISTS (SELECT 1 FROM farmers f WHERE f.farmer_id = fz.farmer_id)
UNION ALL
SELECT 'Sensors without valid zone', COUNT(*)
FROM sensors s
WHERE NOT EXISTS (SELECT 1 FROM farm_zones fz WHERE fz.zone_id = s.zone_id)
UNION ALL
SELECT 'Sensor data without valid sensor', COUNT(*)
FROM sensor_data sd
WHERE NOT EXISTS (SELECT 1 FROM sensors s WHERE s.sensor_id = sd.sensor_id)
UNION ALL
SELECT 'Irrigation logs without valid valve', COUNT(*)
FROM irrigation_logs il
WHERE NOT EXISTS (SELECT 1 FROM irrigation_valves v WHERE v.valve_id = il.valve_id);

-- 5.2 Check for data consistency issues
SELECT 'Irrigation events with no water volume' as anomaly, COUNT(*) as count
FROM irrigation_logs
WHERE water_volume IS NULL OR water_volume <= 0
UNION ALL
SELECT 'Irrigation events with end time before start', COUNT(*)
FROM irrigation_logs
WHERE end_time IS NOT NULL AND end_time <= start_time
UNION ALL
SELECT 'Sensors active with critical battery', COUNT(*)
FROM sensors
WHERE status = 'ACTIVE' AND battery_level < 10
UNION ALL
SELECT 'Farmers never logged in', COUNT(*)
FROM farmers
WHERE last_login IS NULL AND registration_date < SYSDATE - 30;

-- ============================================
-- 6. BUSINESS LOGIC VALIDATION
-- ============================================

PROMPT === 6. BUSINESS LOGIC VALIDATION ===

-- 6.1 Irrigation effectiveness (moisture increase)
SELECT 'Irrigation Effectiveness Analysis' as analysis;
SELECT zone_id, 
       COUNT(*) as irrigation_count,
       ROUND(AVG(final_moisture - initial_moisture), 2) as avg_moisture_increase,
       ROUND(MIN(final_moisture - initial_moisture), 2) as min_increase,
       ROUND(MAX(final_moisture - initial_moisture), 2) as max_increase,
       CASE 
           WHEN AVG(final_moisture - initial_moisture) > 10 THEN 'EXCELLENT'
           WHEN AVG(final_moisture - initial_moisture) > 5 THEN 'GOOD'
           WHEN AVG(final_moisture - initial_moisture) > 0 THEN 'ADEQUATE'
           ELSE 'NEEDS REVIEW'
       END as effectiveness_rating
FROM irrigation_logs
WHERE status = 'COMPLETED'
AND final_moisture IS NOT NULL
AND initial_moisture IS NOT NULL
GROUP BY zone_id
ORDER BY avg_moisture_increase DESC;

-- 6.2 Auto vs manual irrigation comparison
SELECT 'Trigger Source Analysis' as analysis;
SELECT trigger_source, 
       COUNT(*) as event_count,
       ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM irrigation_logs), 2) as percentage,
       ROUND(AVG(water_volume), 2) as avg_water_volume,
       ROUND(AVG(final_moisture - initial_moisture), 2) as avg_moisture_increase
FROM irrigation_logs
WHERE status = 'COMPLETED'
GROUP BY trigger_source
ORDER BY event_count DESC;

-- ============================================
-- 7. FINAL VALIDATION SUMMARY
-- ============================================

PROMPT === 7. FINAL VALIDATION SUMMARY ===

SELECT 'TOTAL RECORDS' as metric, COUNT(*) as value FROM farmers
UNION ALL
SELECT 'ACTIVE FARMERS', COUNT(*) FROM farmers WHERE status = 'ACTIVE'
UNION ALL
SELECT 'TOTAL ZONES', COUNT(*) FROM farm_zones
UNION ALL
SELECT 'ACTIVE SENSORS', COUNT(*) FROM sensors WHERE status = 'ACTIVE'
UNION ALL
SELECT 'SENSOR READINGS', COUNT(*) FROM sensor_data
UNION ALL
SELECT 'IRRIGATION EVENTS', COUNT(*) FROM irrigation_logs
UNION ALL
SELECT 'TOTAL WATER USED (L)', SUM(water_volume) FROM irrigation_logs
UNION ALL
SELECT 'AVG MOISTURE INCREASE', ROUND(AVG(final_moisture - initial_moisture), 2) 
FROM irrigation_logs WHERE status = 'COMPLETED';

PROMPT === VALIDATION COMPLETED SUCCESSFULLY ===
