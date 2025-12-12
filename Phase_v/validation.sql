-- ============================================
-- PHASE V FINAL VALIDATION
-- ============================================

SET SERVEROUTPUT ON
PROMPT ========== PHASE V VALIDATION REPORT ==========

-- 1. FINAL COUNTS
PROMPT 1. FINAL TABLE COUNTS:
SELECT 'FARMERS' as "TABLE", COUNT(*) as "RECORDS" FROM farmers
UNION ALL SELECT 'FARM_ZONES', COUNT(*) FROM farm_zones
UNION ALL SELECT 'SENSORS', COUNT(*) FROM sensors
UNION ALL SELECT 'IRRIGATION_VALVES', COUNT(*) FROM irrigation_valves
UNION ALL SELECT 'SENSOR_DATA', COUNT(*) FROM sensor_data
UNION ALL SELECT 'IRRIGATION_LOGS', COUNT(*) FROM irrigation_logs;

-- 2. DATA QUALITY CHECKS
PROMPT 
PROMPT 2. DATA QUALITY CHECKS:

-- No NULLs in required fields
SELECT 'No NULL usernames: ' || 
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL - ' || COUNT(*) || ' found' END
FROM farmers WHERE username IS NULL
UNION ALL
SELECT 'No NULL zone names: ' || 
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL - ' || COUNT(*) || ' found' END
FROM farm_zones WHERE zone_name IS NULL
UNION ALL
SELECT 'No NULL sensor codes: ' || 
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL - ' || COUNT(*) || ' found' END
FROM sensors WHERE sensor_code IS NULL;

-- Constraint checks
SELECT 'Valid moisture values: ' || 
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL - ' || COUNT(*) || ' invalid' END
FROM sensor_data WHERE moisture_value < 0 OR moisture_value > 100
UNION ALL
SELECT 'Valid battery levels: ' || 
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL - ' || COUNT(*) || ' invalid' END
FROM sensors WHERE battery_level < 0 OR battery_level > 100
UNION ALL
SELECT 'Positive area values: ' || 
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL - ' || COUNT(*) || ' invalid' END
FROM farm_zones WHERE area_sqm <= 0;

-- 3. REFERENTIAL INTEGRITY
PROMPT 
PROMPT 3. REFERENTIAL INTEGRITY:

SELECT 'No orphaned farm zones: ' || 
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL - ' || COUNT(*) || ' found' END
FROM farm_zones fz 
WHERE NOT EXISTS (SELECT 1 FROM farmers f WHERE f.farmer_id = fz.farmer_id)
UNION ALL
SELECT 'No orphaned sensors: ' || 
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL - ' || COUNT(*) || ' found' END
FROM sensors s 
WHERE NOT EXISTS (SELECT 1 FROM farm_zones fz WHERE fz.zone_id = s.zone_id)
UNION ALL
SELECT 'No orphaned sensor data: ' || 
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL - ' || COUNT(*) || ' found' END
FROM sensor_data sd 
WHERE NOT EXISTS (SELECT 1 FROM sensors s WHERE s.sensor_id = sd.sensor_id);

-- 4. BUSINESS LOGIC VALIDATION
PROMPT 
PROMPT 4. BUSINESS LOGIC:

-- Check irrigation volume calculation consistency
SELECT 'Irrigation volume matches flow rate: ' ||
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'CHECK - ' || COUNT(*) || ' mismatches' END
FROM irrigation_logs il
JOIN irrigation_valves iv ON il.valve_id = iv.valve_id
WHERE il.water_volume IS NOT NULL 
AND il.end_time IS NOT NULL 
AND il.start_time IS NOT NULL
AND ABS(il.water_volume - (iv.flow_rate * 
    EXTRACT(MINUTE FROM (il.end_time - il.start_time))/60)) > 0.1;

-- Check moisture improvement after irrigation
SELECT 'Moisture improves after irrigation: ' ||
       CASE WHEN ROUND(AVG(CASE WHEN final_moisture > initial_moisture THEN 1 ELSE 0 END)*100, 1) > 70 
            THEN 'PASS (' || ROUND(AVG(CASE WHEN final_moisture > initial_moisture THEN 1 ELSE 0 END)*100, 1) || '%)'
            ELSE 'CHECK - Only ' || ROUND(AVG(CASE WHEN final_moisture > initial_moisture THEN 1 ELSE 0 END)*100, 1) || '% improved' END
FROM irrigation_logs 
WHERE status = 'COMPLETED' 
AND initial_moisture IS NOT NULL 
AND final_moisture IS NOT NULL;

-- 5. SAMPLE DATA FOR SCREENSHOTS
PROMPT 
PROMPT 5. SAMPLE DATA (First 3 rows each):
PROMPT --- FARMERS ---
SELECT * FROM farmers WHERE ROWNUM <= 3;

PROMPT --- FARM_ZONES ---
SELECT zone_id, farmer_id, zone_name, crop_type, optimal_moisture, status 
FROM farm_zones WHERE ROWNUM <= 3;

PROMPT --- SENSORS ---
SELECT sensor_id, sensor_code, battery_level, status 
FROM sensors WHERE ROWNUM <= 3;

PROMPT --- IRRIGATION_VALVES ---
SELECT valve_id, valve_code, flow_rate, status, total_water_volume 
FROM irrigation_valves WHERE ROWNUM <= 3;

PROMPT --- RECENT SENSOR DATA ---
SELECT data_id, sensor_id, moisture_value, reading_time, temperature 
FROM sensor_data 
WHERE reading_time > SYSDATE - 1
AND ROWNUM <= 3;

PROMPT --- RECENT IRRIGATION LOGS ---
SELECT log_id, valve_id, trigger_source, water_volume, status 
FROM irrigation_logs 
WHERE start_time > SYSDATE - 7
AND ROWNUM <= 3;

PROMPT ========== VALIDATION COMPLETE ==========