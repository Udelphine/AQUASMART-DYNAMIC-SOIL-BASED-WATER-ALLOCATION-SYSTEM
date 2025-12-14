-- ============================================
-- BUSINESS INTELLIGENCE QUERIES
-- Using YOUR AquaSmart Tables
-- Student: Uwineza Delphine (ID: 27897)
-- ============================================

SET SERVEROUTPUT ON

-- Query 1: Water Usage Summary
SELECT 
    z.zone_name,
    z.crop_type,
    COUNT(l.log_id) as irrigation_count,
    SUM(l.water_volume) as total_water_used,
    ROUND(AVG(l.water_volume), 2) as avg_water_per_irrigation
FROM farm_zones z
LEFT JOIN irrigation_logs l ON z.zone_id = l.zone_id
GROUP BY z.zone_name, z.crop_type
ORDER BY total_water_used DESC;

-- Query 2: Sensor Data Analysis
SELECT 
    z.zone_name,
    TO_CHAR(s.reading_timestamp, 'DD-MON-YYYY') as reading_date,
    ROUND(AVG(s.sensor_moisture_reading), 2) as avg_moisture,
    MIN(s.sensor_moisture_reading) as min_moisture,
    MAX(s.sensor_moisture_reading) as max_moisture,
    COUNT(*) as readings_count
FROM sensor_data s
JOIN farm_zones z ON s.zone_id = z.zone_id
WHERE s.reading_timestamp >= TRUNC(SYSDATE) - 7
GROUP BY z.zone_name, TO_CHAR(s.reading_timestamp, 'DD-MON-YYYY')
ORDER BY reading_date DESC, z.zone_name;

-- Query 3: Irrigation Efficiency
SELECT 
    z.zone_name,
    z.optimal_moisture_level as target_moisture,
    ROUND(AVG(s.sensor_moisture_reading), 2) as avg_actual_moisture,
    ROUND(AVG(ABS(z.optimal_moisture_level - s.sensor_moisture_reading)), 2) as avg_deviation,
    CASE 
        WHEN AVG(ABS(z.optimal_moisture_level - s.sensor_moisture_reading)) <= 5 THEN 'OPTIMAL'
        WHEN AVG(z.optimal_moisture_level - s.sensor_moisture_reading) > 5 THEN 'TOO DRY'
        ELSE 'TOO WET'
    END as efficiency_status
FROM farm_zones z
JOIN sensor_data s ON z.zone_id = s.zone_id
WHERE s.reading_timestamp >= SYSDATE - 1
GROUP BY z.zone_name, z.optimal_moisture_level
ORDER BY avg_deviation;

-- Query 4: Business Rule Compliance Report (Phase VII)
SELECT 
    TO_CHAR(operation_date, 'DD-MON-YYYY') as operation_date,
    username,
    COUNT(*) as total_operations,
    SUM(CASE WHEN restricted_attempt = 'Y' THEN 1 ELSE 0 END) as restricted_ops,
    SUM(CASE WHEN restricted_attempt = 'N' THEN 1 ELSE 0 END) as allowed_ops,
    ROUND(SUM(CASE WHEN restricted_attempt = 'N' THEN 1 ELSE 0 END) * 100.0 / 
          NULLIF(COUNT(*), 0), 2) as compliance_percentage
FROM audit_log
WHERE operation_date >= TRUNC(SYSDATE) - 30
GROUP BY TO_CHAR(operation_date, 'DD-MON-YYYY'), username
ORDER BY operation_date DESC;

-- Query 5: Employee Activity Summary (Phase VII)
SELECT 
    e.username,
    e.full_name,
    e.department,
    COUNT(a.audit_id) as total_operations,
    SUM(CASE WHEN a.operation_type = 'INSERT' THEN 1 ELSE 0 END) as insert_count,
    SUM(CASE WHEN a.operation_type = 'UPDATE' THEN 1 ELSE 0 END) as update_count,
    SUM(CASE WHEN a.operation_type = 'DELETE' THEN 1 ELSE 0 END) as delete_count,
    SUM(CASE WHEN a.restricted_attempt = 'Y' THEN 1 ELSE 0 END) as restricted_count
FROM employees e
LEFT JOIN audit_log a ON e.username = a.username
GROUP BY e.username, e.full_name, e.department
ORDER BY total_operations DESC;

-- Query 6: Holiday Management Report (Phase VII)
SELECT 
    holiday_name,
    holiday_date,
    description,
    is_recurring,
    CASE 
        WHEN holiday_date = TRUNC(SYSDATE) THEN 'TODAY'
        WHEN holiday_date > TRUNC(SYSDATE) THEN 'UPCOMING'
        ELSE 'PASSED'
    END as status
FROM holidays
ORDER BY holiday_date;

-- Query 7: System Valve Status
SELECT 
    v.valve_id,
    z.zone_name,
    v.valve_status,
    COUNT(l.log_id) as times_used,
    SUM(l.water_volume) as total_water_delivered
FROM irrigation_valves v
JOIN farm_zones z ON v.zone_id = z.zone_id
LEFT JOIN irrigation_logs l ON v.zone_id = l.zone_id
GROUP BY v.valve_id, z.zone_name, v.valve_status
ORDER BY v.valve_id;

-- Query 8: Water Savings Calculation
-- Assuming traditional irrigation uses 50% more water
SELECT 
    z.zone_name,
    SUM(l.water_volume) as actual_water_used,
    ROUND(SUM(l.water_volume) * 1.5, 2) as traditional_water_use,
    ROUND(SUM(l.water_volume) * 1.5 - SUM(l.water_volume), 2) as water_saved,
    ROUND((SUM(l.water_volume) * 1.5 - SUM(l.water_volume)) * 100.0 / 
          (SUM(l.water_volume) * 1.5), 2) as savings_percentage
FROM farm_zones z
JOIN irrigation_logs l ON z.zone_id = l.zone_id
WHERE l.start_time >= TRUNC(SYSDATE, 'MM')
GROUP BY z.zone_name
ORDER BY water_saved DESC;

-- Query 9: Peak Usage Times
SELECT 
    TO_CHAR(start_time, 'HH24') as hour_of_day,
    COUNT(*) as irrigation_events,
    SUM(water_volume) as total_water_volume,
    ROUND(AVG(water_volume), 2) as avg_volume_per_event
FROM irrigation_logs
GROUP BY TO_CHAR(start_time, 'HH24')
ORDER BY total_water_volume DESC;

-- Query 10: Executive Summary
SELECT 
    'TOTAL ZONES' as metric,
    TO_CHAR(COUNT(*)) as value
FROM farm_zones
UNION ALL
SELECT 
    'ACTIVE IRRIGATIONS THIS MONTH',
    TO_CHAR(COUNT(*))
FROM irrigation_logs 
WHERE start_time >= TRUNC(SYSDATE, 'MM')
UNION ALL
SELECT 
    'TOTAL WATER USED THIS MONTH (L)',
    TO_CHAR(COALESCE(SUM(water_volume), 0))
FROM irrigation_logs 
WHERE start_time >= TRUNC(SYSDATE, 'MM')
UNION ALL
SELECT 
    'BUSINESS RULE COMPLIANCE %',
    TO_CHAR(ROUND(
        SUM(CASE WHEN restricted_attempt = 'N' THEN 1 ELSE 0 END) * 100.0 /
        NULLIF(COUNT(*), 0), 2
    ))
FROM audit_log 
WHERE operation_date >= TRUNC(SYSDATE, 'MM');

-- Completion Message
BEGIN
    DBMS_OUTPUT.PUT_LINE('============================================');
    DBMS_OUTPUT.PUT_LINE('BUSINESS INTELLIGENCE QUERIES COMPLETE');
    DBMS_OUTPUT.PUT_LINE('10 Queries Executed Using YOUR Tables:');
    DBMS_OUTPUT.PUT_LINE('1. Water Usage Summary');
    DBMS_OUTPUT.PUT_LINE('2. Sensor Data Analysis');
    DBMS_OUTPUT.PUT_LINE('3. Irrigation Efficiency');
    DBMS_OUTPUT.PUT_LINE('4. Business Rule Compliance');
    DBMS_OUTPUT.PUT_LINE('5. Employee Activity');
    DBMS_OUTPUT.PUT_LINE('6. Holiday Management');
    DBMS_OUTPUT.PUT_LINE('7. System Valve Status');
    DBMS_OUTPUT.PUT_LINE('8. Water Savings Calculation');
    DBMS_OUTPUT.PUT_LINE('9. Peak Usage Times');
    DBMS_OUTPUT.PUT_LINE('10. Executive Summary');
    DBMS_OUTPUT.PUT_LINE('============================================');
END;
/