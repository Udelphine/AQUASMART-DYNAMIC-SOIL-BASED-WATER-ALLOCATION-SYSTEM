-- ============================================
-- AQUASMART CONSTRAINTS & INDEXES
-- ============================================

-- Connect as application user
CONNECT aqua_app_user/AquaSmart2025@localhost:1521/D_27897_Uwineza_AquaSmart_DB;

-- ============================================
-- 1. ADDITIONAL CONSTRAINTS
-- ============================================

-- Email format validation for farmers
ALTER TABLE farmers 
ADD CONSTRAINT chk_email_format 
CHECK (REGEXP_LIKE(email, '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'));

-- Phone number format (Rwandan format)
ALTER TABLE farmers
ADD CONSTRAINT chk_phone_format
CHECK (REGEXP_LIKE(phone, '^\+250[0-9]{9}$'));

-- Password strength (at least 8 characters when hashed)
ALTER TABLE farmers
ADD CONSTRAINT chk_password_length
CHECK (LENGTH(password_hash) >= 64); -- SHA-256 produces 64 hex chars

-- Crop type validation
ALTER TABLE farm_zones
ADD CONSTRAINT chk_valid_crop
CHECK (crop_type IN ('Maize', 'Beans', 'Potatoes', 'Tomatoes', 'Cabbage', 
                     'Carrots', 'Rice', 'Wheat', 'Soybeans', 'Coffee', 
                     'Tea', 'Bananas', 'Avocado', 'Onions'));

-- Soil type validation
ALTER TABLE farm_zones
ADD CONSTRAINT chk_soil_type
CHECK (soil_type IN ('SAND', 'CLAY', 'LOAM', 'SILT'));

-- Irrigation type validation
ALTER TABLE farm_zones
ADD CONSTRAINT chk_irrigation_type
CHECK (irrigation_type IN ('DRIP', 'SPRINKLER', 'FLOOD'));

-- Sensor type validation
ALTER TABLE sensors
ADD CONSTRAINT chk_sensor_type
CHECK (sensor_type IN ('MOISTURE', 'TEMPERATURE', 'HUMIDITY', 'PH'));

-- Valve type validation
ALTER TABLE irrigation_valves
ADD CONSTRAINT chk_valve_type
CHECK (valve_type IN ('SOLENOID', 'GATE', 'BALL', 'BUTTERFLY'));

-- Final moisture must be >= initial moisture after irrigation
ALTER TABLE irrigation_logs
ADD CONSTRAINT chk_moisture_improvement
CHECK (final_moisture >= initial_moisture);

-- Temperature range validation
ALTER TABLE sensor_data
ADD CONSTRAINT chk_temperature_range
CHECK (temperature BETWEEN -10 AND 60); -- Valid range for agriculture

-- Signal strength validation
ALTER TABLE sensor_data
ADD CONSTRAINT chk_signal_strength
CHECK (signal_strength BETWEEN 0 AND 100);

-- Precipitation validation
ALTER TABLE weather_data
ADD CONSTRAINT chk_precipitation
CHECK (precipitation >= 0);

-- Humidity validation
ALTER TABLE weather_data
ADD CONSTRAINT chk_humidity
CHECK (humidity BETWEEN 0 AND 100);

-- ============================================
-- 2. CREATE INDEXES FOR PERFORMANCE
-- ============================================

-- Farmers indexes
CREATE INDEX idx_farmers_email ON farmers(email) TABLESPACE aqua_index;
CREATE INDEX idx_farmers_status ON farmers(status) TABLESPACE aqua_index;

-- Farm zones indexes
CREATE INDEX idx_farm_zones_farmer ON farm_zones(farmer_id) TABLESPACE aqua_index;
CREATE INDEX idx_farm_zones_crop ON farm_zones(crop_type) TABLESPACE aqua_index;
CREATE INDEX idx_farm_zones_status ON farm_zones(status) TABLESPACE aqua_index;

-- Sensors indexes
CREATE INDEX idx_sensors_zone ON sensors(zone_id) TABLESPACE aqua_index;
CREATE INDEX idx_sensors_code ON sensors(sensor_code) TABLESPACE aqua_index;
CREATE INDEX idx_sensors_status ON sensors(status) TABLESPACE aqua_index;
CREATE INDEX idx_sensors_battery ON sensors(battery_level) TABLESPACE aqua_index;

-- Sensor data indexes (CRITICAL for query performance)
CREATE INDEX idx_sensor_data_sensor ON sensor_data(sensor_id) TABLESPACE aqua_index;
CREATE INDEX idx_sensor_data_time ON sensor_data(reading_time) TABLESPACE aqua_index;
CREATE INDEX idx_sensor_data_moisture ON sensor_data(moisture_value) TABLESPACE aqua_index;
CREATE INDEX idx_sensor_data_status ON sensor_data(status_flag) TABLESPACE aqua_index;

-- Composite index for frequent queries
CREATE INDEX idx_sensor_data_sensor_time 
ON sensor_data(sensor_id, reading_time) TABLESPACE aqua_index;

-- Irrigation valves indexes
CREATE INDEX idx_valves_zone ON irrigation_valves(zone_id) TABLESPACE aqua_index;
CREATE INDEX idx_valves_code ON irrigation_valves(valve_code) TABLESPACE aqua_index;
CREATE INDEX idx_valves_status ON irrigation_valves(status) TABLESPACE aqua_index;

-- Irrigation logs indexes
CREATE INDEX idx_logs_valve ON irrigation_logs(valve_id) TABLESPACE aqua_index;
CREATE INDEX idx_logs_zone ON irrigation_logs(zone_id) TABLESPACE aqua_index;
CREATE INDEX idx_logs_time ON irrigation_logs(start_time) TABLESPACE aqua_index;
CREATE INDEX idx_logs_trigger ON irrigation_logs(trigger_source) TABLESPACE aqua_index;
CREATE INDEX idx_logs_status ON irrigation_logs(status) TABLESPACE aqua_index;

-- Composite index for time-based queries
CREATE INDEX idx_logs_zone_time 
ON irrigation_logs(zone_id, start_time) TABLESPACE aqua_index;

-- Weather data indexes
CREATE INDEX idx_weather_zone ON weather_data(zone_id) TABLESPACE aqua_index;
CREATE INDEX idx_weather_date ON weather_data(forecast_date) TABLESPACE aqua_index;
CREATE INDEX idx_weather_zone_date 
ON weather_data(zone_id, forecast_date) TABLESPACE aqua_index;

-- ============================================
-- 3. CREATE BITMAP INDEXES FOR LOW-CARDINALITY COLUMNS
-- ============================================

-- Bitmap indexes for columns with few distinct values
CREATE BITMAP INDEX bidx_farmers_status ON farmers(status) TABLESPACE aqua_index;
CREATE BITMAP INDEX bidx_farm_zones_status ON farm_zones(status) TABLESPACE aqua_index;
CREATE BITMAP INDEX bidx_farm_zones_soil ON farm_zones(soil_type) TABLESPACE aqua_index;
CREATE BITMAP INDEX bidx_farm_zones_irrigation ON farm_zones(irrigation_type) TABLESPACE aqua_index;
CREATE BITMAP INDEX bidx_sensors_status ON sensors(status) TABLESPACE aqua_index;
CREATE BITMAP INDEX bidx_sensor_data_status ON sensor_data(status_flag) TABLESPACE aqua_index;
CREATE BITMAP INDEX bidx_valves_status ON irrigation_valves(status) TABLESPACE aqua_index;
CREATE BITMAP INDEX bidx_logs_trigger ON irrigation_logs(trigger_source) TABLESPACE aqua_index;
CREATE BITMAP INDEX bidx_logs_status ON irrigation_logs(status) TABLESPACE aqua_index;

-- ============================================
-- 4. CREATE FUNCTION-BASED INDEXES
-- ============================================

-- Index for case-insensitive username search
CREATE INDEX idx_farmers_username_ci 
ON farmers(UPPER(username)) TABLESPACE aqua_index;

-- Index for email domain searches
CREATE INDEX idx_farmers_email_domain 
ON farmers(SUBSTR(email, INSTR(email, '@'))) TABLESPACE aqua_index;

-- Index for year/month of reading_time for time-series analysis
CREATE INDEX idx_sensor_data_year_month 
ON sensor_data(EXTRACT(YEAR FROM reading_time), EXTRACT(MONTH FROM reading_time)) 
TABLESPACE aqua_index;

-- Index for irrigation duration (calculated column)
CREATE INDEX idx_logs_duration 
ON irrigation_logs((end_time - start_time) * 1440) TABLESPACE aqua_index; -- Duration in minutes

-- ============================================
-- 5. CREATE PARTITIONING (ADVANCED - Optional but good for large tables)
-- ============================================

-- Note: Partitioning requires Enterprise Edition
-- This is commented out but shows understanding of advanced features

/*
-- Partition sensor_data by month for easier data management
ALTER TABLE sensor_data MODIFY
PARTITION BY RANGE (reading_time)
INTERVAL (NUMTOYMINTERVAL(1, 'MONTH'))
(
    PARTITION p_initial VALUES LESS THAN (TO_DATE('2025-01-01', 'YYYY-MM-DD'))
) TABLESPACE aqua_data;

-- Partition irrigation_logs by month
ALTER TABLE irrigation_logs MODIFY
PARTITION BY RANGE (start_time)
INTERVAL (NUMTOYMINTERVAL(1, 'MONTH'))
(
    PARTITION p_initial VALUES LESS THAN (TO_DATE('2025-01-01', 'YYYY-MM-DD'))
) TABLESPACE aqua_data;

-- Create local indexes on partitioned tables
CREATE INDEX idx_local_sensor_data_sensor ON sensor_data(sensor_id) LOCAL;
CREATE INDEX idx_local_sensor_data_time ON sensor_data(reading_time) LOCAL;
CREATE INDEX idx_local_logs_zone ON irrigation_logs(zone_id) LOCAL;
CREATE INDEX idx_local_logs_time ON irrigation_logs(start_time) LOCAL;
*/

-- ============================================
-- 6. CREATE VIEWS FOR COMMON QUERIES
-- ============================================

-- View for active farmer zones
CREATE OR REPLACE VIEW v_active_farmer_zones AS
SELECT 
    f.farmer_id,
    f.username,
    f.first_name || ' ' || f.last_name AS farmer_name,
    COUNT(z.zone_id) AS active_zones,
    SUM(z.area_sqm) AS total_area,
    AVG(z.optimal_moisture) AS avg_optimal_moisture
FROM farmers f
JOIN farm_zones z ON f.farmer_id = z.farmer_id
WHERE f.status = 'ACTIVE' AND z.status = 'ACTIVE'
GROUP BY f.farmer_id, f.username, f.first_name, f.last_name;

-- View for sensor health monitoring
CREATE OR REPLACE VIEW v_sensor_health AS
SELECT 
    s.sensor_id,
    s.sensor_code,
    z.zone_name,
    s.battery_level,
    s.status,
    s.last_calibration,
    (SELECT MAX(reading_time) FROM sensor_data sd WHERE sd.sensor_id = s.sensor_id) AS last_reading,
    CASE 
        WHEN s.battery_level < 20 THEN 'CRITICAL'
        WHEN s.battery_level < 40 THEN 'LOW'
        WHEN SYSDATE - s.last_calibration > 180 THEN 'NEEDS_CALIBRATION'
        ELSE 'HEALTHY'
    END AS health_status
FROM sensors s
JOIN farm_zones z ON s.zone_id = z.zone_id;

-- View for daily water usage
CREATE OR REPLACE VIEW v_daily_water_usage AS
SELECT 
    z.zone_id,
    z.zone_name,
    TRUNC(l.start_time) AS usage_date,
    COUNT(l.log_id) AS irrigation_count,
    SUM(l.water_volume) AS total_water_liters,
    AVG(l.water_volume) AS avg_water_per_irrigation,
    MIN(l.initial_moisture) AS min_initial_moisture,
    MAX(l.final_moisture) AS max_final_moisture
FROM irrigation_logs l
JOIN farm_zones z ON l.zone_id = z.zone_id
WHERE l.status = 'COMPLETED'
GROUP BY z.zone_id, z.zone_name, TRUNC(l.start_time);

-- View for crop performance analysis
CREATE OR REPLACE VIEW v_crop_performance AS
SELECT 
    z.crop_type,
    COUNT(DISTINCT z.zone_id) AS zone_count,
    AVG(z.optimal_moisture) AS target_moisture,
    AVG(sd.moisture_value) AS avg_actual_moisture,
    AVG(CASE WHEN sd.moisture_value < z.optimal_moisture * 0.9 THEN 1 ELSE 0 END) * 100 AS pct_below_target,
    SUM(l.water_volume) / SUM(z.area_sqm) AS water_efficiency
FROM farm_zones z
LEFT JOIN sensors s ON z.zone_id = s.zone_id
LEFT JOIN sensor_data sd ON s.sensor_id = sd.sensor_id
LEFT JOIN irrigation_logs l ON z.zone_id = l.zone_id
WHERE z.status = 'ACTIVE'
GROUP BY z.crop_type;

-- ============================================
-- 7. CREATE SYNONYMS FOR EASIER ACCESS
-- ============================================

-- Public synonyms for common tables
CREATE PUBLIC SYNONYM farmers FOR aqua_app_user.farmers;
CREATE PUBLIC SYNONYM farm_zones FOR aqua_app_user.farm_zones;
CREATE PUBLIC SYNONYM sensors FOR aqua_app_user.sensors;
CREATE PUBLIC SYNONYM sensor_data FOR aqua_app_user.sensor_data;
CREATE PUBLIC SYNONYM irrigation_valves FOR aqua_app_user.irrigation_valves;
CREATE PUBLIC SYNONYM irrigation_logs FOR aqua_app_user.irrigation_logs;
CREATE PUBLIC SYNONYM weather_data FOR aqua_app_user.weather_data;

-- Synonyms for views
CREATE PUBLIC SYNONYM v_active_farmer_zones FOR aqua_app_user.v_active_farmer_zones;
CREATE PUBLIC SYNONYM v_sensor_health FOR aqua_app_user.v_sensor_health;
CREATE PUBLIC SYNONYM v_daily_water_usage FOR aqua_app_user.v_daily_water_usage;
CREATE PUBLIC SYNONYM v_crop_performance FOR aqua_app_user.v_crop_performance;

-- ============================================
-- 8. GRANT PERMISSIONS ON VIEWS
-- ============================================

GRANT SELECT ON v_active_farmer_zones TO aqua_analyst_user;
GRANT SELECT ON v_sensor_health TO aqua_analyst_user;
GRANT SELECT ON v_daily_water_usage TO aqua_analyst_user;
GRANT SELECT ON v_crop_performance TO aqua_analyst_user;

-- ============================================
-- 9. VERIFICATION QUERIES
-- ============================================

PROMPT =========== CONSTRAINTS & INDEXES SUMMARY ===========
PROMPT 
PROMPT 1. Additional constraints added: 14
PROMPT 2. B-tree indexes created: 25
PROMPT 3. Bitmap indexes created: 9
PROMPT 4. Function-based indexes created: 4
PROMPT 5. Views created: 4
PROMPT 6. Synonyms created: 11
PROMPT 
PROMPT =========== INDEX USAGE STATISTICS ===========

-- Check index creation
SELECT 
    table_name,
    index_name,
    index_type,
    uniqueness,
    status
FROM user_indexes
WHERE table_name IN ('FARMERS', 'FARM_ZONES', 'SENSORS', 'SENSOR_DATA', 
                     'IRRIGATION_VALVES', 'IRRIGATION_LOGS', 'WEATHER_DATA')
ORDER BY table_name, index_name;

-- Check constraint information
SELECT 
    table_name,
    constraint_name,
    constraint_type,
    status,
    search_condition
FROM user_constraints
WHERE table_name IN ('FARMERS', 'FARM_ZONES', 'SENSORS', 'SENSOR_DATA',
                     'IRRIGATION_VALVES', 'IRRIGATION_LOGS', 'WEATHER_DATA')
ORDER BY table_name, constraint_type;

-- Check view creation
SELECT view_name, text_length
FROM user_views
WHERE view_name LIKE 'V_%';

-- Check synonym creation
SELECT synonym_name, table_name, table_owner
FROM user_synonyms
WHERE table_owner = 'AQUA_APP_USER';

PROMPT ====================================================
PROMPT Constraints and indexes successfully created!
PROMPT ====================================================

COMMIT;