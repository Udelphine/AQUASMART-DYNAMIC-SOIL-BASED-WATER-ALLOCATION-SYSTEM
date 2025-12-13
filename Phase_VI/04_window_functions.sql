-- ============================================
-- PHASE VI: WINDOW FUNCTIONS
-- ============================================

-- Example 1: ROW_NUMBER() - Rank sensors by battery level per zone
SELECT 
    zone_id,
    sensor_code,
    battery_level,
    ROW_NUMBER() OVER (PARTITION BY zone_id ORDER BY battery_level DESC) as battery_rank,
    ROUND(battery_level - AVG(battery_level) OVER (PARTITION BY zone_id), 2) as diff_from_zone_avg
FROM sensors
WHERE status = 'ACTIVE'
ORDER BY zone_id, battery_rank;

-- Example 2: RANK() and DENSE_RANK() - Rank farmers by water usage
SELECT 
    f.username,
    fz.zone_name,
    ROUND(SUM(il.water_volume), 2) as total_water,
    RANK() OVER (ORDER BY SUM(il.water_volume) DESC) as usage_rank,
    DENSE_RANK() OVER (ORDER BY SUM(il.water_volume) DESC) as dense_usage_rank,
    ROUND(AVG(SUM(il.water_volume)) OVER (), 2) as overall_avg_water
FROM farmers f
JOIN farm_zones fz ON f.farmer_id = fz.farmer_id
JOIN irrigation_logs il ON fz.zone_id = il.zone_id
WHERE il.start_time > SYSDATE - 30
AND il.status = 'COMPLETED'
GROUP BY f.username, fz.zone_name
ORDER BY usage_rank;

-- Example 3: LAG() and LEAD() - Compare consecutive sensor readings
SELECT 
    sensor_id,
    TO_CHAR(reading_time, 'DD-MON HH24:MI') as reading_time,
    moisture_value,
    temperature,
    LAG(moisture_value) OVER (PARTITION BY sensor_id ORDER BY reading_time) as prev_moisture,
    moisture_value - LAG(moisture_value) OVER (PARTITION BY sensor_id ORDER BY reading_time) as moisture_change,
    LEAD(reading_time) OVER (PARTITION BY sensor_id ORDER BY reading_time) as next_reading_time
FROM sensor_data
WHERE sensor_id IN (3001, 3002, 3003)
AND reading_time > SYSDATE - 1
ORDER BY sensor_id, reading_time;

-- Example 4: Running totals and moving averages
SELECT 
    TRUNC(start_time) as irrigation_date,
    COUNT(log_id) as daily_events,
    SUM(water_volume) as daily_water,
    SUM(COUNT(log_id)) OVER (ORDER BY TRUNC(start_time)) as running_total_events,
    SUM(SUM(water_volume)) OVER (ORDER BY TRUNC(start_time)) as running_total_water,
    ROUND(AVG(SUM(water_volume)) OVER (ORDER BY TRUNC(start_time) ROWS BETWEEN 6 PRECEDING AND CURRENT ROW), 2) as weekly_moving_avg
FROM irrigation_logs
WHERE start_time > SYSDATE - 30
AND status = 'COMPLETED'
GROUP BY TRUNC(start_time)
ORDER BY irrigation_date;

-- Example 5: NTILE() - Divide zones into efficiency quartiles
WITH zone_stats AS (
    SELECT 
        zone_id,
        zone_name,
        COUNT(il.log_id) as irrigation_count,
        ROUND(SUM(il.water_volume), 2) as total_water,
        ROUND(AVG(il.water_volume), 2) as avg_per_event
    FROM farm_zones fz
    LEFT JOIN irrigation_logs il ON fz.zone_id = il.zone_id
    AND il.start_time > SYSDATE - 30
    AND il.status = 'COMPLETED'
    WHERE fz.status = 'ACTIVE'
    GROUP BY zone_id, zone_name
)
SELECT 
    zone_id,
    zone_name,
    irrigation_count,
    total_water,
    avg_per_event,
    NTILE(4) OVER (ORDER BY total_water DESC) as efficiency_quartile,
    CASE NTILE(4) OVER (ORDER BY total_water DESC)
        WHEN 1 THEN 'High Efficiency'
        WHEN 2 THEN 'Medium-High Efficiency'
        WHEN 3 THEN 'Medium-Low Efficiency'
        WHEN 4 THEN 'Low Efficiency'
    END as efficiency_category
FROM zone_stats
ORDER BY efficiency_quartile, total_water DESC;

PROMPT Window functions demonstrated successfully!