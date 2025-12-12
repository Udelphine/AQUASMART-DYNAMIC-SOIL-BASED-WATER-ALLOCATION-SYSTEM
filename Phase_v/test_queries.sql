-- ============================================
-- PHASE V TEST QUERIES
-- As per project requirements
-- ============================================

-- 1. BASIC RETRIEVAL (SELECT *)
PROMPT === 1. BASIC RETRIEVAL ===
SELECT * FROM farmers WHERE ROWNUM <= 5;
SELECT * FROM farm_zones WHERE ROWNUM <= 5;
SELECT * FROM sensors WHERE ROWNUM <= 5;

-- 2. JOINS (Multi-table queries)
PROMPT === 2. JOIN QUERIES ===
-- Farmers with their zones
SELECT f.username, f.email, fz.zone_name, fz.crop_type, fz.area_sqm
FROM farmers f
JOIN farm_zones fz ON f.farmer_id = fz.farmer_id
ORDER BY f.username, fz.zone_name;

-- Complete sensor information with zone details
SELECT s.sensor_code, fz.zone_name, f.username, s.battery_level, s.status
FROM sensors s
JOIN farm_zones fz ON s.zone_id = fz.zone_id
JOIN farmers f ON fz.farmer_id = f.farmer_id
WHERE s.status = 'ACTIVE'
ORDER BY f.username, fz.zone_name;

-- 3. AGGREGATIONS (GROUP BY)
PROMPT === 3. AGGREGATION QUERIES ===
-- Water usage by farmer
SELECT f.username, 
       COUNT(il.log_id) as irrigation_count,
       ROUND(SUM(il.water_volume), 2) as total_water_liters,
       ROUND(AVG(il.water_volume), 2) as avg_per_event
FROM farmers f
JOIN farm_zones fz ON f.farmer_id = fz.farmer_id
JOIN irrigation_logs il ON fz.zone_id = il.zone_id
GROUP BY f.username
ORDER BY total_water_liters DESC;

-- Average moisture by crop type
SELECT fz.crop_type,
       ROUND(AVG(sd.moisture_value), 2) as avg_moisture,
       COUNT(sd.data_id) as reading_count
FROM farm_zones fz
JOIN sensors s ON fz.zone_id = s.zone_id
JOIN sensor_data sd ON s.sensor_id = sd.sensor_id
GROUP BY fz.crop_type
ORDER BY avg_moisture DESC;

-- 4. SUBQUERIES
PROMPT === 4. SUBQUERY EXAMPLES ===
-- Farmers with zones needing irrigation (moisture < optimal - 15%)
SELECT f.username, fz.zone_name, fz.crop_type, 
       fz.optimal_moisture, current_moisture.avg_moisture,
       ROUND(fz.optimal_moisture - current_moisture.avg_moisture, 2) as moisture_deficit
FROM farmers f
JOIN farm_zones fz ON f.farmer_id = fz.farmer_id
JOIN (
    SELECT s.zone_id, ROUND(AVG(sd.moisture_value), 2) as avg_moisture
    FROM sensors s
    JOIN sensor_data sd ON s.sensor_id = sd.sensor_id
    WHERE sd.reading_time > SYSDATE - 1  -- Last 24 hours
    GROUP BY s.zone_id
) current_moisture ON fz.zone_id = current_moisture.zone_id
WHERE current_moisture.avg_moisture < (fz.optimal_moisture - 15)
AND fz.status = 'ACTIVE'
ORDER BY moisture_deficit DESC;

-- Sensors with latest reading
SELECT s.sensor_code, fz.zone_name,
       (SELECT moisture_value 
        FROM sensor_data sd2 
        WHERE sd2.sensor_id = s.sensor_id 
        AND sd2.reading_time = (
            SELECT MAX(reading_time) 
            FROM sensor_data sd3 
            WHERE sd3.sensor_id = s.sensor_id
        )) as latest_moisture
FROM sensors s
JOIN farm_zones fz ON s.zone_id = fz.zone_id
WHERE s.status = 'ACTIVE'
ORDER BY fz.zone_name;

PROMPT === TEST QUERIES COMPLETED ===