-- ============================================
-- PHASE VI: PACKAGES (CORRECTED VERSION)
-- ============================================

-- Package 1: AQUASMART_UTILITIES_PKG
CREATE OR REPLACE PACKAGE aquasmart_utilities_pkg AS
    PROCEDURE calculate_and_irrigate(p_zone_id IN NUMBER);
    FUNCTION get_zone_health_score(p_zone_id IN NUMBER) RETURN NUMBER;
    PROCEDURE generate_system_report;
    FUNCTION validate_irrigation_params(p_zone_id IN NUMBER, p_water_volume IN NUMBER) RETURN VARCHAR2;
    c_system_version CONSTANT VARCHAR2(10) := '1.0.0';
    invalid_zone_exception EXCEPTION;
    insufficient_data_exception EXCEPTION;
END aquasmart_utilities_pkg;
/

CREATE OR REPLACE PACKAGE BODY aquasmart_utilities_pkg AS
    
    PROCEDURE calculate_and_irrigate(p_zone_id IN NUMBER) AS
        v_optimal_moisture NUMBER;
        v_current_moisture NUMBER;
        v_water_needed NUMBER;
        v_status VARCHAR2(200);
        v_water_volume NUMBER;
    BEGIN
        SELECT optimal_moisture INTO v_optimal_moisture
        FROM farm_zones WHERE zone_id = p_zone_id;
        
        BEGIN
            SELECT moisture_value INTO v_current_moisture
            FROM (
                SELECT sd.moisture_value
                FROM sensor_data sd
                JOIN sensors s ON sd.sensor_id = s.sensor_id
                WHERE s.zone_id = p_zone_id
                AND s.sensor_type = 'SOIL_MOISTURE'
                ORDER BY sd.reading_time DESC
            ) WHERE ROWNUM = 1;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE insufficient_data_exception;
        END;
        
        v_water_needed := GREATEST(v_optimal_moisture - v_current_moisture, 0) * 10;
        
        IF v_water_needed > 5 THEN
            activate_irrigation(
                p_zone_id => p_zone_id,
                p_trigger_source => 'AUTOMATIC',
                p_water_volume => v_water_volume,
                p_status => v_status
            );
            
            DBMS_OUTPUT.PUT_LINE('Irrigation calculated: ' || v_water_needed || 'L needed');
            DBMS_OUTPUT.PUT_LINE('Status: ' || v_status);
        ELSE
            DBMS_OUTPUT.PUT_LINE('No irrigation needed. Moisture deficit: ' || 
                                ROUND(v_optimal_moisture - v_current_moisture, 2));
        END IF;
        
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('ERROR: Zone ' || p_zone_id || ' not found');
            RAISE invalid_zone_exception;
        WHEN insufficient_data_exception THEN
            DBMS_OUTPUT.PUT_LINE('ERROR: Insufficient sensor data for zone ' || p_zone_id);
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('ERROR: ' || SQLERRM);
    END calculate_and_irrigate;
    
    FUNCTION get_zone_health_score(p_zone_id IN NUMBER) RETURN NUMBER AS
        v_sensor_score NUMBER := 0;
        v_irrigation_score NUMBER := 0;
        v_moisture_score NUMBER := 0;
        v_total_score NUMBER;
    BEGIN
        SELECT AVG(
            CASE 
                WHEN battery_level > 80 THEN 100
                WHEN battery_level > 50 THEN 75
                WHEN battery_level > 20 THEN 50
                ELSE 25
            END
        ) INTO v_sensor_score
        FROM sensors
        WHERE zone_id = p_zone_id
        AND status = 'ACTIVE';
        
        SELECT 
            CASE 
                WHEN COUNT(*) >= 10 THEN 100
                WHEN COUNT(*) >= 5 THEN 75
                WHEN COUNT(*) >= 2 THEN 50
                ELSE 25
            END INTO v_irrigation_score
        FROM irrigation_logs
        WHERE zone_id = p_zone_id
        AND start_time > SYSDATE - 30
        AND status = 'COMPLETED';
        
        SELECT 
            100 - (STDDEV(moisture_value) * 2) INTO v_moisture_score
        FROM sensor_data sd
        JOIN sensors s ON sd.sensor_id = s.sensor_id
        WHERE s.zone_id = p_zone_id
        AND sd.reading_time > SYSDATE - 7;
        
        v_total_score := 
            (NVL(v_sensor_score, 0) * 0.3) +
            (NVL(v_irrigation_score, 0) * 0.4) +
            (NVL(v_moisture_score, 0) * 0.3);
            
        RETURN ROUND(GREATEST(LEAST(v_total_score, 100), 0), 1);
        
    EXCEPTION
        WHEN OTHERS THEN
            RETURN 0;
    END get_zone_health_score;
    
    PROCEDURE generate_system_report AS
        v_total_farmers NUMBER;
        v_total_zones NUMBER;
        v_total_sensors NUMBER;
        v_active_irrigations NUMBER;
        v_total_water_today NUMBER;
    BEGIN
        DBMS_OUTPUT.PUT_LINE('============================================');
        DBMS_OUTPUT.PUT_LINE('AQUASMART SYSTEM REPORT');
        DBMS_OUTPUT.PUT_LINE('Generated: ' || TO_CHAR(SYSDATE, 'DD-MON-YYYY HH24:MI:SS'));
        DBMS_OUTPUT.PUT_LINE('System Version: ' || c_system_version);
        DBMS_OUTPUT.PUT_LINE('============================================');
        
        SELECT COUNT(*) INTO v_total_farmers FROM farmers WHERE status = 'ACTIVE';
        SELECT COUNT(*) INTO v_total_zones FROM farm_zones WHERE status = 'ACTIVE';
        SELECT COUNT(*) INTO v_total_sensors FROM sensors WHERE status = 'ACTIVE';
        
        SELECT COUNT(*) INTO v_active_irrigations 
        FROM irrigation_logs WHERE status = 'STARTED';
        
        SELECT COALESCE(SUM(water_volume), 0) INTO v_total_water_today
        FROM irrigation_logs
        WHERE TRUNC(start_time) = TRUNC(SYSDATE)
        AND status = 'COMPLETED';
        
        DBMS_OUTPUT.PUT_LINE('SYSTEM STATISTICS:');
        DBMS_OUTPUT.PUT_LINE('  Active Farmers: ' || v_total_farmers);
        DBMS_OUTPUT.PUT_LINE('  Active Zones: ' || v_total_zones);
        DBMS_OUTPUT.PUT_LINE('  Active Sensors: ' || v_total_sensors);
        DBMS_OUTPUT.PUT_LINE('  Active Irrigations: ' || v_active_irrigations);
        DBMS_OUTPUT.PUT_LINE('  Water Used Today: ' || ROUND(v_total_water_today, 2) || 'L');
        DBMS_OUTPUT.PUT_LINE('');
        
        DBMS_OUTPUT.PUT_LINE('ZONE HEALTH SCORES:');
        DBMS_OUTPUT.PUT_LINE('Zone ID | Zone Name          | Health Score | Status');
        DBMS_OUTPUT.PUT_LINE('--------|--------------------|--------------|--------');
        
        FOR zone_rec IN (
            SELECT zone_id, zone_name, status
            FROM farm_zones
            WHERE status = 'ACTIVE'
            ORDER BY zone_id
        ) LOOP
            DBMS_OUTPUT.PUT_LINE(
                LPAD(zone_rec.zone_id, 7) || ' | ' ||
                RPAD(zone_rec.zone_name, 18) || ' | ' ||
                LPAD(get_zone_health_score(zone_rec.zone_id), 12) || ' | ' ||
                zone_rec.status
            );
        END LOOP;
        
        DBMS_OUTPUT.PUT_LINE('============================================');
        
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('ERROR generating report: ' || SQLERRM);
    END generate_system_report;
    
    FUNCTION validate_irrigation_params(p_zone_id IN NUMBER, p_water_volume IN NUMBER) RETURN VARCHAR2 AS
        v_zone_exists NUMBER;
        v_max_water NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_zone_exists
        FROM farm_zones
        WHERE zone_id = p_zone_id
        AND status = 'ACTIVE';
        
        IF v_zone_exists = 0 THEN
            RETURN 'ERROR: Zone not found or inactive';
        END IF;
        
        SELECT area_sqm * 20 INTO v_max_water
        FROM farm_zones
        WHERE zone_id = p_zone_id;
        
        IF p_water_volume <= 0 THEN
            RETURN 'ERROR: Water volume must be positive';
        ELSIF p_water_volume > v_max_water THEN
            RETURN 'ERROR: Water volume exceeds maximum (' || ROUND(v_max_water, 2) || 'L)';
        ELSE
            RETURN 'VALID';
        END IF;
        
    EXCEPTION
        WHEN OTHERS THEN
            RETURN 'ERROR: Validation failed - ' || SQLERRM;
    END validate_irrigation_params;
    
END aquasmart_utilities_pkg;
/

-- Package 2: AQUASMART_ANALYTICS_PKG (SIMPLIFIED - NO PIPELINED FUNCTIONS)
CREATE OR REPLACE PACKAGE aquasmart_analytics_pkg AS
    PROCEDURE show_water_conservation_metrics(p_days IN NUMBER DEFAULT 30);
    PROCEDURE generate_efficiency_report(p_farmer_id IN NUMBER DEFAULT NULL);
    PROCEDURE show_predicted_water_needs(p_days_ahead IN NUMBER DEFAULT 7);
END aquasmart_analytics_pkg;
/

CREATE OR REPLACE PACKAGE BODY aquasmart_analytics_pkg AS
    
    PROCEDURE show_water_conservation_metrics(p_days IN NUMBER DEFAULT 30) AS
        v_water_saved NUMBER;
        v_efficiency NUMBER;
        v_sensor_availability NUMBER;
    BEGIN
        SELECT COALESCE(SUM(water_volume), 0) * 0.3 INTO v_water_saved
        FROM irrigation_logs 
        WHERE start_time > SYSDATE - p_days AND status = 'COMPLETED';
        
        SELECT AVG(aquasmart_utilities_pkg.get_zone_health_score(zone_id)) INTO v_efficiency
        FROM farm_zones WHERE status = 'ACTIVE';
        
        SELECT ROUND((COUNT(CASE WHEN status = 'ACTIVE' THEN 1 END) * 100.0 / COUNT(*)), 1) 
        INTO v_sensor_availability FROM sensors;
        
        DBMS_OUTPUT.PUT_LINE('WATER CONSERVATION METRICS (Last ' || p_days || ' days)');
        DBMS_OUTPUT.PUT_LINE('=====================================================');
        DBMS_OUTPUT.PUT_LINE('Water Saved: ' || ROUND(v_water_saved, 2) || ' liters');
        DBMS_OUTPUT.PUT_LINE('System Efficiency: ' || ROUND(NVL(v_efficiency, 0), 1) || '% (Target: 85%)');
        DBMS_OUTPUT.PUT_LINE('Sensor Availability: ' || v_sensor_availability || '% (Target: 95%)');
        
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('ERROR showing metrics: ' || SQLERRM);
    END show_water_conservation_metrics;
    
    PROCEDURE generate_efficiency_report(p_farmer_id IN NUMBER DEFAULT NULL) AS
        CURSOR efficiency_cursor IS
            SELECT 
                f.username,
                fz.zone_name,
                fz.crop_type,
                COUNT(il.log_id) as irrigation_count,
                ROUND(SUM(il.water_volume), 2) as total_water,
                ROUND(AVG(il.water_volume), 2) as avg_water,
                aquasmart_utilities_pkg.get_zone_health_score(fz.zone_id) as health_score,
                RANK() OVER (ORDER BY SUM(il.water_volume) DESC) as water_rank
            FROM farmers f
            JOIN farm_zones fz ON f.farmer_id = fz.farmer_id
            LEFT JOIN irrigation_logs il ON fz.zone_id = il.zone_id
            AND il.start_time > SYSDATE - 30
            AND il.status = 'COMPLETED'
            WHERE (p_farmer_id IS NULL OR f.farmer_id = p_farmer_id)
            AND fz.status = 'ACTIVE'
            GROUP BY f.username, fz.zone_name, fz.crop_type, fz.zone_id
            ORDER BY f.username, health_score DESC;
    BEGIN
        DBMS_OUTPUT.PUT_LINE('IRRIGATION EFFICIENCY REPORT');
        DBMS_OUTPUT.PUT_LINE('==============================');
        DBMS_OUTPUT.PUT_LINE('Period: Last 30 days');
        DBMS_OUTPUT.PUT_LINE('Generated: ' || TO_CHAR(SYSDATE, 'DD-MON-YYYY HH24:MI'));
        DBMS_OUTPUT.PUT_LINE('');
        
        DBMS_OUTPUT.PUT_LINE('Farmer           | Zone              | Crop      | Events | Water (L) | Avg/Event | Health | Rank');
        DBMS_OUTPUT.PUT_LINE('-----------------|-------------------|-----------|--------|-----------|-----------|--------|------');
        
        FOR rec IN efficiency_cursor LOOP
            DBMS_OUTPUT.PUT_LINE(
                RPAD(rec.username, 16) || ' | ' ||
                RPAD(rec.zone_name, 17) || ' | ' ||
                RPAD(rec.crop_type, 9) || ' | ' ||
                LPAD(rec.irrigation_count, 6) || ' | ' ||
                LPAD(rec.total_water, 9) || ' | ' ||
                LPAD(rec.avg_water, 9) || ' | ' ||
                LPAD(rec.health_score, 6) || ' | ' ||
                LPAD(rec.water_rank, 4)
            );
        END LOOP;
        
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('ERROR generating efficiency report: ' || SQLERRM);
    END generate_efficiency_report;
    
    PROCEDURE show_predicted_water_needs(p_days_ahead IN NUMBER DEFAULT 7) AS
        v_avg_daily_water NUMBER;
        v_predicted_water NUMBER;
    BEGIN
        SELECT AVG(daily_water) INTO v_avg_daily_water
        FROM (
            SELECT TRUNC(start_time) as day, SUM(water_volume) as daily_water
            FROM irrigation_logs
            WHERE start_time > SYSDATE - 30
            AND status = 'COMPLETED'
            GROUP BY TRUNC(start_time)
        );
        
        DBMS_OUTPUT.PUT_LINE('PREDICTED WATER NEEDS (Next ' || p_days_ahead || ' days)');
        DBMS_OUTPUT.PUT_LINE('======================================================');
        DBMS_OUTPUT.PUT_LINE('Average daily water usage: ' || ROUND(NVL(v_avg_daily_water, 1000), 2) || 'L');
        DBMS_OUTPUT.PUT_LINE('');
        DBMS_OUTPUT.PUT_LINE('Day      | Predicted Water | Compared to Average');
        DBMS_OUTPUT.PUT_LINE('---------|-----------------|---------------------');
        
        FOR i IN 1..p_days_ahead LOOP
            v_predicted_water := NVL(v_avg_daily_water, 1000) * i;
            DBMS_OUTPUT.PUT_LINE(
                TO_CHAR(SYSDATE + i, 'DD-MON') || ' | ' ||
                LPAD(ROUND(v_predicted_water, 2), 15) || ' | ' ||
                LPAD(ROUND(v_avg_daily_water, 2), 19)
            );
        END LOOP;
        
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('ERROR predicting water needs: ' || SQLERRM);
    END show_predicted_water_needs;
    
END aquasmart_analytics_pkg;
/

PROMPT 2 packages created successfully!