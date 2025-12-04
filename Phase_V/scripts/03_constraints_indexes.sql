-- ============================================
-- AquaSmart: CONSTRAINTS & INDEXES Script
-- Student: Uwineza Delphine | ID: 27897
-- Date: 2025-12-04
-- ============================================

-- Connect as application user
CONNECT aqua_app_user/AquaSmart2025@localhost:1521/D_27897_Uwineza_AquaSmart_DB;

-- ============================================
-- 1. ADDITIONAL CHECK CONSTRAINTS
-- ============================================

-- Temperature range constraint
ALTER TABLE sensor_data ADD CONSTRAINT chk_temp_range 
    CHECK (temperature BETWEEN -10 AND 50);

-- Email format constraint
ALTER TABLE farmers ADD CONSTRAINT chk_email_format 
    CHECK (email LIKE '%@%.%');

-- Phone number format (optional)
ALTER TABLE farmers ADD CONSTRAINT chk_phone_format 
    CHECK (phone IS NULL OR phone LIKE '+%');

-- Crop type validation
ALTER TABLE farm_zones ADD CONSTRAINT chk_valid_crop 
    CHECK (crop_type IN ('Corn', 'Tomatoes', 'Lettuce', 'Wheat', 'Apples', 'Potatoes', 
                         'Carrots', 'Beans', 'Rice', 'Soybeans', 'Coffee', 'Tea', 
                         'Bananas', 'Avocado', 'Seedlings'));

-- ============================================
-- 2. CREATE INDEXES FOR PERFORMANCE
-- ============================================

-- Foreign key indexes (improve JOIN performance)
CREATE INDEX idx_farm_zones_farmer ON farm_zones(farmer_id) 
    TABLESPACE aqua_index;

CREATE INDEX idx_sensors_zone ON sensors(zone_id) 
    TABLESPACE aqua_index;

CREATE INDEX idx_sensor_data_sensor ON sensor_data(sensor_id) 
    TABLESPACE aqua_index;

CREATE INDEX idx_valves_zone ON irrigation_valves(zone_id) 
    TABLESPACE aqua_index;

CREATE INDEX idx_logs_valve ON irrigation_logs(valve_id) 
    TABLESPACE aqua_index;

CREATE INDEX idx_logs_zone ON irrigation_logs(zone_id) 
    TABLESPACE aqua_index;

-- Query performance indexes (frequently searched columns)
CREATE INDEX idx_sensor_data_time ON sensor_data(reading_time) 
    TABLESPACE aqua_index;

CREATE INDEX idx_logs_time ON irrigation_logs(start_time) 
    TABLESPACE aqua_index;

CREATE INDEX idx_farmers_status ON farmers(status) 
    TABLESPACE aqua_index;

CREATE INDEX idx_farm_zones_status ON farm_zones(status) 
    TABLESPACE aqua_index;

CREATE INDEX idx_sensors_status ON sensors(status) 
    TABLESPACE aqua_index;

CREATE INDEX idx_valves_status ON irrigation_valves(status) 
    TABLESPACE aqua_index;

-- Composite indexes for common query patterns
CREATE INDEX idx_zone_crop ON farm_zones(zone_name, crop_type) 
    TABLESPACE aqua_index;

CREATE INDEX idx_sensor_readings ON sensor_data(sensor_id, reading_time DESC) 
    TABLESPACE aqua_index;

-- ============================================
-- 3. CREATE FUNCTIONAL INDEXES
-- ============================================

-- Index on uppercase username for case-insensitive searches
CREATE INDEX idx_farmers_username_upper ON farmers(UPPER(username)) 
    TABLESPACE aqua_index;

-- Index on email domain for email-based queries
CREATE INDEX idx_farmers_email_domain ON farmers(SUBSTR(email, INSTR(email, '@'))) 
    TABLESPACE aqua_index;

-- ============================================
-- 4. VERIFY INDEX CREATION
-- ============================================

PROMPT === INDEX CREATION VERIFICATION ===

SELECT 
    table_name,
    index_name,
    uniqueness,
    status
FROM user_indexes 
WHERE table_name IN ('FARMERS', 'FARM_ZONES', 'SENSORS', 'SENSOR_DATA', 'IRRIGATION_VALVES', 'IRRIGATION_LOGS')
ORDER BY table_name, index_name;

PROMPT === CONSTRAINT VERIFICATION ===

SELECT 
    table_name,
    constraint_name,
    constraint_type,
    status
FROM user_constraints 
WHERE table_name IN ('FARMERS', 'FARM_ZONES', 'SENSORS', 'SENSOR_DATA', 'IRRIGATION_VALVES', 'IRRIGATION_LOGS')
ORDER BY table_name, constraint_type;

PROMPT === Total indexes created: ===
SELECT COUNT(*) as total_indexes FROM user_indexes 
WHERE table_name IN ('FARMERS', 'FARM_ZONES', 'SENSORS', 'SENSOR_DATA', 'IRRIGATION_VALVES', 'IRRIGATION_LOGS');

PROMPT === Constraints and indexes created successfully! ===
