-- ============================================
-- PHASE VI: FUNCTIONS (5 functions)
-- ============================================

-- Function 1: CALCULATE_WATER_DEFICIT
CREATE OR REPLACE FUNCTION calculate_water_deficit(
    p_zone_id IN NUMBER
) RETURN NUMBER AS
    v_optimal_moisture NUMBER;
    v_current_moisture NUMBER;
    v_area_sqm NUMBER;
    v_deficit NUMBER;
BEGIN
    SELECT optimal_moisture, area_sqm INTO v_optimal_moisture, v_area_sqm
    FROM farm_zones WHERE zone_id = p_zone_id;
    
    SELECT moisture_value INTO v_current_moisture FROM (
        SELECT sd.moisture_value FROM sensor_data sd
        JOIN sensors s ON sd.sensor_id = s.sensor_id
        WHERE s.zone_id = p_zone_id
        ORDER BY sd.reading_time DESC
    ) WHERE ROWNUM = 1;
    
    v_deficit := GREATEST(v_optimal_moisture - v_current_moisture, 0);
    RETURN ROUND(v_deficit * v_area_sqm * 0.1, 2); -- Simplified calculation
END;
/

-- Function 2: GET_ZONE_EFFICIENCY
CREATE OR REPLACE FUNCTION get_zone_efficiency(
    p_zone_id IN NUMBER,
    p_days IN NUMBER DEFAULT 7
) RETURN NUMBER AS
    v_water_used NUMBER;
    v_optimal_water NUMBER;
    v_efficiency NUMBER;
BEGIN
    SELECT COALESCE(SUM(water_volume), 0) INTO v_water_used
    FROM irrigation_logs
    WHERE zone_id = p_zone_id
    AND start_time > SYSDATE - p_days
    AND status = 'COMPLETED';
    
    -- Calculate optimal water (simplified)
    SELECT area_sqm * 10 INTO v_optimal_water -- 10L per sqm per week
    FROM farm_zones WHERE zone_id = p_zone_id;
    
    IF v_optimal_water = 0 THEN RETURN 0; END IF;
    
    v_efficiency := 100 - ((ABS(v_water_used - v_optimal_water) / v_optimal_water) * 100);
    RETURN ROUND(GREATEST(LEAST(v_efficiency, 100), 0), 2);
END;
/

-- Function 3: VALIDATE_SENSOR_READING
CREATE OR REPLACE FUNCTION validate_sensor_reading(
    p_moisture_value IN NUMBER,
    p_temperature IN NUMBER DEFAULT NULL
) RETURN VARCHAR2 AS
BEGIN
    IF p_moisture_value < 0 OR p_moisture_value > 100 THEN
        RETURN 'INVALID: Moisture out of range (0-100)';
    ELSIF p_temperature IS NOT NULL AND (p_temperature < -10 OR p_temperature > 60) THEN
        RETURN 'INVALID: Temperature out of range (-10 to 60)';
    ELSIF p_moisture_value > 95 THEN
        RETURN 'ALERT: Soil oversaturated';
    ELSIF p_moisture_value < 15 THEN
        RETURN 'ALERT: Critical dryness';
    ELSE
        RETURN 'VALID';
    END IF;
END;
/

-- Function 4: GET_FARMER_STATISTICS
CREATE OR REPLACE FUNCTION get_farmer_statistics(
    p_farmer_id IN NUMBER
) RETURN VARCHAR2 AS
    v_zone_count NUMBER;
    v_total_water NUMBER;
    v_avg_efficiency NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_zone_count FROM farm_zones WHERE farmer_id = p_farmer_id;
    
    SELECT COALESCE(SUM(il.water_volume), 0) INTO v_total_water
    FROM irrigation_logs il
    JOIN farm_zones fz ON il.zone_id = fz.zone_id
    WHERE fz.farmer_id = p_farmer_id
    AND il.start_time > SYSDATE - 30;
    
    -- Calculate average efficiency
    SELECT AVG(get_zone_efficiency(zone_id, 30)) INTO v_avg_efficiency
    FROM farm_zones WHERE farmer_id = p_farmer_id;
    
    RETURN 'Zones: ' || v_zone_count || 
           ' | Water (30d): ' || ROUND(v_total_water, 2) || 'L' ||
           ' | Efficiency: ' || ROUND(NVL(v_avg_efficiency, 0), 1) || '%';
END;
/

-- Function 5: PREDICT_WATER_NEED
CREATE OR REPLACE FUNCTION predict_water_need(
    p_zone_id IN NUMBER,
    p_days_ahead IN NUMBER DEFAULT 1
) RETURN NUMBER AS
    v_avg_daily_water NUMBER;
    v_weather_factor NUMBER := 1.0; -- Simplified: 1.0 = normal
BEGIN
    SELECT AVG(water_volume) INTO v_avg_daily_water
    FROM irrigation_logs
    WHERE zone_id = p_zone_id
    AND start_time > SYSDATE - 30
    AND status = 'COMPLETED';
    
    -- Adjust for predicted days
    IF p_days_ahead > 3 THEN v_weather_factor := 1.2; -- Assume hotter days
    ELSIF p_days_ahead = 1 THEN v_weather_factor := 0.9; -- Tomorrow
    END IF;
    
    RETURN ROUND(NVL(v_avg_daily_water, 50) * p_days_ahead * v_weather_factor, 2);
END;
/

PROMPT 5 functions created successfully!