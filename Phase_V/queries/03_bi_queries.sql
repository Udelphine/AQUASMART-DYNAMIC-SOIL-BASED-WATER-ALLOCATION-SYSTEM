-- ============================================
-- AQUASMART BUSINESS INTELLIGENCE QUERIES
-- ============================================

-- Connect as application user
CONNECT aqua_app_user/AquaSmart2025@localhost:1521/D_27897_Uwineza_AquaSmart_DB;

SET SERVEROUTPUT ON;
SET FEEDBACK ON;
SET LINESIZE 200;
SET PAGESIZE 50;

-- ============================================
-- 1. EXECUTIVE SUMMARY KPIs
-- ============================================

PROMPT =========== EXECUTIVE SUMMARY KPIs ===========

-- KPI 1: Total active farmers
SELECT 'Active Farmers' AS kpi, COUNT(*) AS value
FROM farmers WHERE status = 'ACTIVE'
UNION ALL
-- KPI 2: Total irrigation zones
SELECT 'Active Zones', COUNT(*) FROM farm_zones WHERE status = 'ACTIVE'
UNION ALL
-- KPI 3: Total sensors
SELECT 'Active Sensors', COUNT(*) FROM sensors WHERE status = 'ACTIVE'
UNION ALL
-- KPI 4: Total water saved (estimated)
SELECT 'Water Saved (Liters)', 
       ROUND(SUM(
           CASE 
               WHEN trigger_source = 'AUTO' THEN water_volume * 0.3  -- 30% savings for auto
               ELSE water_volume * 0.1                               -- 10% savings for manual
           END
       ), 0)
FROM irrigation_logs 
WHERE start_time > SYSDATE - 30
UNION ALL
-- KPI 5: System uptime
SELECT 'System Uptime (%)', 
       ROUND((1 - (SELECT COUNT(*) FROM sensors WHERE status = 'FAULTY') / 
              NULLIF((SELECT COUNT(*) FROM sensors), 0)) * 100, 2)
FROM dual;

-- ============================================
-- 2. WATER USAGE ANALYTICS
-- ============================================

PROMPT =========== WATER USAGE ANALYTICS ===========

-- 2.1 Daily water consumption trend
SELECT 
    TRUNC(start_time) AS usage_date,
    COUNT(*) AS irrigation_count,
    SUM(water_volume) AS total_water_liters,
    ROUND(AVG(water_volume), 2) AS avg_per_irrigation,
    ROUND(SUM(water_volume) / 
          (SELECT SUM(area_sqm) FROM farm_zones WHERE status = 'ACTIVE'), 3) AS liters_per_sqm
FROM irrigation_logs
WHERE start_time > SYSDATE - 30
GROUP BY TRUNC(start_time)
ORDER BY usage_date DESC;

-- 2.2 Water usage by crop type
SELECT 
    z.crop_type,
    COUNT(DISTINCT z.zone_id) AS zone_count,
    SUM(l.water_volume) AS total_water,
    ROUND(AVG(l.water_volume), 2) AS avg_water_per_irrigation,
    ROUND(SUM(l.water_volume) / SUM(z.area_sqm), 3) AS water_per_sqm,
    RANK() OVER (ORDER BY SUM(l.water_volume) DESC) AS water_usage_rank
FROM farm_zones z
JOIN irrigation_logs l ON z.zone_id = l.zone_id
WHERE l.start_time > SYSDATE - 30
GROUP BY z.crop_type
ORDER BY total_water DESC;

-- 2.3 Water efficiency by farmer
SELECT 
    f.username,
    f.first_name || ' ' || f.last_name AS farmer_name,
    COUNT(DISTINCT z.zone_id) AS zone_count,
    SUM(z.area_sqm) AS total_area,
    SUM(l.water_volume) AS total_water,
    ROUND(SUM(l.water_volume) / SUM(z.area_sqm), 3) AS water_per_sqm,
    ROUND(AVG(sd.moisture_value), 2) AS avg_moisture,
    ROUND(AVG(z.optimal_moisture), 2) AS target_moisture,
    CASE 
        WHEN AVG(sd.moisture_value) >= AVG(z.optimal_moisture) * 0.9 THEN 'Efficient'
        ELSE 'Needs Improvement'
    END AS efficiency_rating
FROM farmers f
JOIN farm_zones z ON f.farmer_id = z.farmer_id
LEFT JOIN sensors s ON z.zone_id = s.zone_id
LEFT JOIN sensor_data sd ON s.sensor_id = sd.sensor_id AND sd.reading_time > SYSDATE - 7
LEFT JOIN irrigation_logs l ON z.zone_id = l.zone_id AND l.start_time > SYSDATE - 30
WHERE f.status = 'ACTIVE'
GROUP BY f.username, f.first_name, f.last_name
ORDER BY water_per_sqm ASC  -- Most efficient first
FETCH FIRST 15 ROWS ONLY;

-- ============================================
-- 3. CROP PERFORMANCE ANALYTICS
-- ============================================

PROMPT =========== CROP PERFORMANCE ANALYTICS ===========

-- 3.1 Moisture consistency by crop
SELECT 
    z.crop_type,
    COUNT(DISTINCT z.zone_id) AS zones_monitored,
    ROUND(AVG(z.optimal_moisture), 2) AS target_moisture,
    ROUND(AVG(sd.moisture_value), 2) AS actual_avg_moisture,
    ROUND(STDDEV(sd.moisture_value), 2) AS moisture_std_dev,
    ROUND(AVG(ABS(sd.moisture_value - z.optimal_moisture)), 2) AS avg_deviation_from_target,
    SUM(CASE WHEN sd.moisture_value < z.optimal_moisture * 0.9 THEN 1 ELSE 0 END) 
        / COUNT(sd.data_id) * 100 AS pct_readings_below_target
FROM farm_zones z
JOIN sensors s ON z.zone_id = s.zone_id
JOIN sensor_data sd ON s.sensor_id = sd.sensor_id
WHERE sd.reading_time > SYSDATE - 7
GROUP BY z.crop_type
ORDER BY avg_deviation_from_target;

-- 3.2 Irrigation frequency by crop
SELECT 
    z.crop_type,
    COUNT(DISTINCT l.log_id) / COUNT(DISTINCT z.zone_id) AS avg_irrigations_per_zone,
    ROUND(AVG(l.water_volume), 2) AS avg_water_per_irrigation,
    MIN(l.start_time) AS first_irrigation,
    MAX(l.start_time) AS last_irrigation,
    ROUND((MAX(l.start_time) - MIN(l.start_time)) / COUNT(DISTINCT l.log_id), 2) AS avg_days_between_irrigations
FROM farm_zones z
LEFT JOIN irrigation_logs l ON z.zone_id = l.zone_id
WHERE l.start_time > SYSDATE - 30 OR l.log_id IS NULL
GROUP BY z.crop_type
ORDER BY avg_irrigations_per_zone DESC;

-- ============================================
-- 4. SENSOR HEALTH & MAINTENANCE ANALYTICS
-- ============================================

PROMPT =========== SENSOR HEALTH ANALYTICS ===========

-- 4.1 Sensor battery status
SELECT 
    CASE 
        WHEN battery_level < 20 THEN 'Critical (<20%)'
        WHEN battery_level < 40 THEN 'Low (20-40%)'
        WHEN battery_level < 60 THEN 'Medium (40-60%)'
        WHEN battery_level < 80 THEN 'Good (60-80%)'
        ELSE 'Excellent (80-100%)'
    END AS battery_status,
    COUNT(*) AS sensor_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM sensors), 2) AS percentage
FROM sensors
WHERE status = 'ACTIVE'
GROUP BY 
    CASE 
        WHEN battery_level < 20 THEN 'Critical (<20%)'
        WHEN battery_level < 40 THEN 'Low (20-40%)'
        WHEN battery_level < 60 THEN 'Medium (40-60%)'
        WHEN battery_level < 80 THEN 'Good (60-80%)'
        ELSE 'Excellent (80-100%)'
    END
ORDER BY MIN(battery_level);

-- 4.2 Sensors needing calibration
SELECT 
    s.sensor_code,
    z.zone_name,
    s.last_calibration,
    ROUND(SYSDATE - s.last_calibration) AS days_since_calibration,
    s.battery_level,
    CASE 
        WHEN SYSDATE - s.last_calibration > 180 THEN 'OVERDUE (>6 months)'
        WHEN SYSDATE - s.last_calibration > 90 THEN 'DUE SOON (3-6 months)'
        ELSE 'WITHIN SCHEDULE'
    END AS calibration_status
FROM sensors s
JOIN farm_zones z ON s.zone_id = z.zone_id
WHERE s.status = 'ACTIVE'
ORDER BY days_since_calibration DESC NULLS LAST
FETCH FIRST 15 ROWS ONLY;

-- 4.3 Sensor data quality metrics
SELECT 
    s.sensor_code,
    z.zone_name,
    COUNT(sd.data_id) AS total_readings,
    SUM(CASE WHEN sd.status_flag = 'E' THEN 1 ELSE 0 END) AS error_readings,
    ROUND(SUM(CASE WHEN sd.status_flag = 'E' THEN 1 ELSE 0 END) * 100.0 / 
          NULLIF(COUNT(sd.data_id), 0), 2) AS error_rate_percent,
    ROUND(AVG(sd.signal_strength), 2) AS avg_signal_strength,
    MIN(sd.reading_time) AS first_reading,
    MAX(sd.reading_time) AS last_reading
FROM sensors s
JOIN farm_zones z ON s.zone_id = z.zone_id
LEFT JOIN sensor_data sd ON s.sensor_id = sd.sensor_id
WHERE s.status = 'ACTIVE'
AND sd.reading_time > SYSDATE - 7
GROUP BY s.sensor_code, z.zone_name
ORDER BY error_rate_percent DESC NULLS LAST
FETCH FIRST 10 ROWS ONLY;

-- ============================================
-- 5. PREDICTIVE ANALYTICS (Using window functions)
-- ============================================

PROMPT =========== PREDICTIVE ANALYTICS ===========

-- 5.1 Moisture trend prediction
WITH moisture_trends AS (
    SELECT 
        s.zone_id,
        z.zone_name,
        sd.reading_time,
        sd.moisture_value,
        LAG(sd.moisture_value, 1) OVER (PARTITION BY s.zone_id ORDER BY sd.reading_time) AS prev_moisture,
        LAG(sd.moisture_value, 2) OVER (PARTITION BY s.zone_id ORDER BY sd.reading_time) AS prev_moisture2,
        ROUND(AVG(sd.moisture_value) OVER (
            PARTITION BY s.zone_id 
            ORDER BY sd.reading_time 
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        ), 2) AS moving_avg_7
    FROM sensor_data sd
    JOIN sensors s ON sd.sensor_id = s.sensor_id
    JOIN farm_zones z ON s.zone_id = z.zone_id
    WHERE sd.reading_time > SYSDATE - 3
)
SELECT 
    zone_name,
    reading_time,
    moisture_value,
    prev_moisture,
    ROUND(moisture_value - prev_moisture, 2) AS change_since_last,
    moving_avg_7,
    CASE 
        WHEN moisture_value < moving_avg_7 * 0.9 THEN 'DECREASING TREND'
        WHEN moisture_value > moving_avg_7 * 1.1 THEN 'INCREASING TREND'
        ELSE 'STABLE'
    END AS trend
FROM moisture_trends
WHERE prev_moisture IS NOT NULL
AND zone_id = (SELECT MIN(zone_id) FROM farm_zones WHERE status = 'ACTIVE')
ORDER BY reading_time DESC
FETCH FIRST 20 ROWS ONLY;

-- 5.2 Irrigation prediction model
SELECT 
    z.zone_id,
    z.zone_name,
    z.crop_type,
    z.optimal_moisture,
    (SELECT sd.moisture_value 
     FROM sensor_data sd 
     JOIN sensors s ON sd.sensor_id = s.sensor_id
     WHERE s.zone_id = z.zone_id 
     ORDER BY sd.reading_time DESC 
     FETCH FIRST 1 ROW ONLY) AS current_moisture,
    (SELECT AVG(moisture_value)
     FROM sensor_data sd 
     JOIN sensors s ON sd.sensor_id = s.sensor_id
     WHERE s.zone_id = z.zone_id 
     AND sd.reading_time > SYSDATE - 1) AS avg_last_24h,
    (SELECT AVG(water_volume)
     FROM irrigation_logs 
     WHERE zone_id = z.zone_id 
     AND start_time > SYSDATE - 7) AS avg_recent_water,
    CASE 
        WHEN (SELECT sd.moisture_value 
              FROM sensor_data sd 
              JOIN sensors s ON sd.sensor_id = s.sensor_id
              WHERE s.zone_id = z.zone_id 
              ORDER BY sd.reading_time DESC 
              FETCH FIRST 1 ROW ONLY) < z.optimal_moisture * 0.85 
        THEN 'IMMEDIATE IRRIGATION NEEDED'
        WHEN (SELECT sd.moisture_value 
              FROM sensor_data sd 
              JOIN sensors s ON sd.sensor_id = s.sensor_id
              WHERE s.zone_id = z.zone_id 
              ORDER BY sd.reading_time DESC 
              FETCH FIRST 1 ROW ONLY) < z.optimal_moisture * 0.90 
        THEN 'IRRIGATION SOON (Next 12 hours)'
        WHEN (SELECT AVG(moisture_value)
              FROM sensor_data sd 
              JOIN sensors s ON sd.sensor_id = s.sensor_id
              WHERE s.zone_id = z.zone_id 
              AND sd.reading_time > SYSDATE - 6) < z.optimal_moisture * 0.92 
        THEN 'MONITOR CLOSELY'
        ELSE 'OPTIMAL'
    END AS irrigation_recommendation
FROM farm_zones z
WHERE z.status = 'ACTIVE'
ORDER BY 
    CASE 
        WHEN (SELECT sd.moisture_value 
              FROM sensor_data sd 
              JOIN sensors s ON sd.sensor_id = s.sensor_id
              WHERE s.zone_id = z.zone_id 
              ORDER BY sd.reading_time DESC 
              FETCH FIRST 1 ROW ONLY) < z.optimal_moisture * 0.85 
        THEN 1
        WHEN (SELECT sd.moisture_value 
              FROM sensor_data sd 
              JOIN sensors s ON sd.sensor_id = s.sensor_id
              WHERE s.zone_id = z.zone_id 
              ORDER BY sd.reading_time DESC 
              FETCH FIRST 1 ROW ONLY) < z.optimal_moisture * 0.90 
        THEN 2
        ELSE 3
    END,
    current_moisture
FETCH FIRST 15 ROWS ONLY;

-- ============================================
-- 6. BUSINESS INTELLIGENCE DASHBOARD QUERIES
-- ============================================

PROMPT =========== DASHBOARD QUERIES ===========

-- 6.1 Daily system performance dashboard
SELECT 
    'Today' AS period,
    (SELECT COUNT(DISTINCT zone_id) FROM irrigation_logs WHERE TRUNC(start_time) = TRUNC(SYSDATE)) AS zones_irrigated_today,
    (SELECT SUM(water_volume) FROM irrigation_logs WHERE TRUNC(start_time) = TRUNC(SYSDATE)) AS water_used_today,
    (SELECT COUNT(*) FROM sensor_data WHERE TRUNC(reading_time) = TRUNC(SYSDATE)) AS sensor_readings_today,
    (SELECT COUNT(*) FROM sensors WHERE battery_level < 20 AND status = 'ACTIVE') AS critical_battery_sensors
FROM dual
UNION ALL
SELECT 
    'Last 7 Days',
    (SELECT COUNT(DISTINCT zone_id) FROM irrigation_logs WHERE start_time > SYSDATE - 7),
    (SELECT SUM(water_volume) FROM irrigation_logs WHERE start_time > SYSDATE - 7),
    (SELECT COUNT(*) FROM sensor_data WHERE reading_time > SYSDATE - 7),
    (SELECT COUNT(*) FROM sensors WHERE battery_level < 30 AND status = 'ACTIVE')
FROM dual
UNION ALL
SELECT 
    'Last 30 Days',
    (SELECT COUNT(DISTINCT zone_id) FROM irrigation_logs WHERE start_time > SYSDATE - 30),
    (SELECT SUM(water_volume) FROM irrigation_logs WHERE start_time > SYSDATE - 30),
    (SELECT COUNT(*) FROM sensor_data WHERE reading_time > SYSDATE - 30),
    (SELECT COUNT(*) FROM sensors WHERE battery_level < 40 AND status = 'ACTIVE')
FROM dual;

-- 6.2 Top performing farmers dashboard
SELECT 
    f.username,
    f.first_name || ' ' || f.last_name AS farmer_name,
    COUNT(DISTINCT z.zone_id) AS active_zones,
    ROUND(SUM(z.area_sqm), 2) AS total_area,
    (SELECT COUNT(*) FROM sensors s WHERE s.zone_id IN (
        SELECT zone_id FROM farm_zones WHERE farmer_id = f.farmer_id
    ) AND s.status = 'ACTIVE') AS active_sensors,
    (SELECT SUM(water_volume) FROM irrigation_logs l WHERE l.zone_id IN (
        SELECT zone_id FROM farm_zones WHERE farmer_id = f.farmer_id
    ) AND l.start_time > SYSDATE - 30) AS water_used_30d,
    ROUND((SELECT AVG(sd.moisture_value) FROM sensor_data sd WHERE sd.sensor_id IN (
        SELECT sensor_id FROM sensors WHERE zone_id IN (
            SELECT zone_id FROM farm_zones WHERE farmer_id = f.farmer_id
        )
    ) AND sd.reading_time > SYSDATE - 7), 2) AS avg_moisture_7d
FROM farmers f
JOIN farm_zones z ON f.farmer_id = z.farmer_id AND z.status = 'ACTIVE'
WHERE f.status = 'ACTIVE'
GROUP BY f.username, f.first_name, f.last_name, f.farmer_id
ORDER BY active_zones DESC
FETCH FIRST 10 ROWS ONLY;

-- ============================================
-- 7. BI REPORT SUMMARY
-- ============================================

PROMPT =========== BI REPORT SUMMARY ===========

DECLARE
    total_kpis NUMBER := 5;
    insights_found NUMBER := 0;
BEGIN
    -- Check water savings insight
    IF (SELECT SUM(water_volume) FROM irrigation_logs WHERE start_time > SYSDATE - 30) > 10000 THEN
        insights_found := insights_found + 1;
        DBMS_OUTPUT.PUT_LINE('✅ Insight: Significant water usage detected (>10,000L in 30 days)');
    END IF;
    
    -- Check sensor health insight
    IF (SELECT COUNT(*) FROM sensors WHERE battery_level < 20 AND status = 'ACTIVE') > 0 THEN
        insights_found := insights_found + 1;
        DBMS_OUTPUT.PUT_LINE('⚠️  Insight: ' || (SELECT COUNT(*) FROM sensors WHERE battery_level < 20 AND status = 'ACTIVE') || 
                           ' sensors have critical battery (<20%)');
    END IF;
    
    -- Check irrigation efficiency insight
    IF (SELECT AVG(final_moisture - initial_moisture) FROM irrigation_logs WHERE start_time > SYSDATE - 7) < 10 THEN
        insights_found := insights_found + 1;
        DBMS_OUTPUT.PUT_LINE('💡 Insight: Low moisture improvement from irrigation (<10% increase on average)');
    END IF;
    
    -- Check crop performance insight
    IF (SELECT COUNT(DISTINCT crop_type) FROM farm_zones) >= 5 THEN
        insights_found := insights_found + 1;
        DBMS_OUTPUT.PUT_LINE('📊 Insight: System monitoring ' || 
                           (SELECT COUNT(DISTINCT crop_type) FROM farm_zones) || ' different crop types');
    END IF;
    
    DBMS_OUTPUT.PUT_LINE('=====================================');
    DBMS_OUTPUT.PUT_LINE('BI Analytics Summary:');
    DBMS_OUTPUT.PUT_LINE('- KPIs calculated: ' || total_kpis);
    DBMS_OUTPUT.PUT_LINE('- Insights generated: ' || insights_found);
    DBMS_OUTPUT.PUT_LINE('- Data analyzed: Last 30 days');
    DBMS_OUTPUT.PUT_LINE('✅ BI queries executed successfully!');
END;
/

COMMIT;