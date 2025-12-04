-- ============================================
-- AquaSmart: CREATE TABLES Script
-- Student: Uwineza Delphine | ID: 27897
-- Date: 2025-12-04
-- ============================================

-- Connect as application user
CONNECT aqua_app_user/AquaSmart2025@localhost:1521/D_27897_Uwineza_AquaSmart_DB;

-- ============================================
-- 1. CREATE SEQUENCES FOR PRIMARY KEYS
-- ============================================

CREATE SEQUENCE seq_farmers START WITH 1001 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_farm_zones START WITH 2001 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_sensors START WITH 3001 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_sensor_data START WITH 4001 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_valves START WITH 5001 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_irrigation_logs START WITH 6001 INCREMENT BY 1 NOCACHE NOCYCLE;

-- ============================================
-- 2. CREATE TABLES (6 TABLES FROM ER DIAGRAM)
-- ============================================

-- Table 1: FARMERS
CREATE TABLE farmers (
    farmer_id         NUMBER(10)      DEFAULT seq_farmers.NEXTVAL PRIMARY KEY,
    username          VARCHAR2(30)    NOT NULL UNIQUE,
    first_name        VARCHAR2(50)    NOT NULL,
    last_name         VARCHAR2(50)    NOT NULL,
    email             VARCHAR2(100)   NOT NULL UNIQUE,
    phone             VARCHAR2(20),
    password_hash     VARCHAR2(100)   NOT NULL,
    registration_date DATE            DEFAULT SYSDATE NOT NULL,
    status            VARCHAR2(10)    DEFAULT 'ACTIVE' 
        CHECK (status IN ('ACTIVE', 'INACTIVE', 'SUSPENDED')),
    last_login        TIMESTAMP
) TABLESPACE aqua_data;

COMMENT ON TABLE farmers IS 'Stores information about farmers using the AquaSmart system';

-- Table 2: FARM_ZONES
CREATE TABLE farm_zones (
    zone_id            NUMBER(10)      DEFAULT seq_farm_zones.NEXTVAL PRIMARY KEY,
    farmer_id          NUMBER(10)      NOT NULL,
    zone_name          VARCHAR2(100)   NOT NULL,
    crop_type          VARCHAR2(50)    NOT NULL,
    optimal_moisture   NUMBER(5,2)     NOT NULL 
        CHECK (optimal_moisture BETWEEN 10 AND 90),
    area_sqm           NUMBER(10,2)    NOT NULL CHECK (area_sqm > 0),
    soil_type          VARCHAR2(20)    DEFAULT 'LOAM',
    irrigation_method  VARCHAR2(20)    DEFAULT 'DRIP',
    created_date       DATE            DEFAULT SYSDATE NOT NULL,
    status             VARCHAR2(10)    DEFAULT 'ACTIVE'
        CHECK (status IN ('ACTIVE', 'INACTIVE', 'MAINTENANCE')),
    
    CONSTRAINT fk_farm_zones_farmer 
        FOREIGN KEY (farmer_id) REFERENCES farmers(farmer_id) ON DELETE CASCADE,
    CONSTRAINT unique_zone_per_farmer UNIQUE (farmer_id, zone_name)
) TABLESPACE aqua_data;

COMMENT ON TABLE farm_zones IS 'Irrigation zones within farms with crop-specific settings';

-- Table 3: SENSORS
CREATE TABLE sensors (
    sensor_id          NUMBER(10)      DEFAULT seq_sensors.NEXTVAL PRIMARY KEY,
    zone_id            NUMBER(10)      NOT NULL,
    sensor_code        VARCHAR2(20)    NOT NULL UNIQUE,
    sensor_type        VARCHAR2(20)    DEFAULT 'SOIL_MOISTURE',
    manufacturer       VARCHAR2(50),
    installation_date  DATE            DEFAULT SYSDATE NOT NULL,
    battery_level      NUMBER(3)       DEFAULT 100 
        CHECK (battery_level BETWEEN 0 AND 100),
    last_calibration   DATE,
    status             VARCHAR2(15)    DEFAULT 'ACTIVE'
        CHECK (status IN ('ACTIVE', 'FAULTY', 'MAINTENANCE', 'OFFLINE')),
    
    CONSTRAINT fk_sensors_zone 
        FOREIGN KEY (zone_id) REFERENCES farm_zones(zone_id) ON DELETE CASCADE
) TABLESPACE aqua_data;

COMMENT ON TABLE sensors IS 'Physical sensor devices installed in farm zones';

-- Table 4: SENSOR_DATA
CREATE TABLE sensor_data (
    data_id            NUMBER(10)      DEFAULT seq_sensor_data.NEXTVAL PRIMARY KEY,
    sensor_id          NUMBER(10)      NOT NULL,
    moisture_value     NUMBER(5,2)     NOT NULL 
        CHECK (moisture_value BETWEEN 0 AND 100),
    temperature        NUMBER(4,1),
    reading_time       TIMESTAMP       DEFAULT SYSTIMESTAMP NOT NULL,
    battery_at_reading NUMBER(3),
    status_flag        VARCHAR2(1)     DEFAULT 'N'
        CHECK (status_flag IN ('N', 'P', 'E')),  -- N=New, P=Processed, E=Error
    
    CONSTRAINT fk_sensor_data_sensor 
        FOREIGN KEY (sensor_id) REFERENCES sensors(sensor_id) ON DELETE CASCADE
) TABLESPACE aqua_data;

COMMENT ON TABLE sensor_data IS 'Time-series measurements from soil sensors';

-- Table 5: IRRIGATION_VALVES
CREATE TABLE irrigation_valves (
    valve_id           NUMBER(10)      DEFAULT seq_valves.NEXTVAL PRIMARY KEY,
    zone_id            NUMBER(10)      NOT NULL,
    valve_code         VARCHAR2(20)    NOT NULL UNIQUE,
    valve_type         VARCHAR2(20)    DEFAULT 'SOLENOID',
    flow_rate          NUMBER(6,2)     NOT NULL CHECK (flow_rate > 0),
    installation_date  DATE            DEFAULT SYSDATE NOT NULL,
    last_maintenance   DATE,
    status             VARCHAR2(15)    DEFAULT 'CLOSED'
        CHECK (status IN ('OPEN', 'CLOSED', 'FAULTY', 'MAINTENANCE')),
    
    CONSTRAINT fk_valves_zone 
        FOREIGN KEY (zone_id) REFERENCES farm_zones(zone_id) ON DELETE CASCADE
) TABLESPACE aqua_data;

COMMENT ON TABLE valves IS 'Irrigation control valves for each zone';

-- Table 6: IRRIGATION_LOGS
CREATE TABLE irrigation_logs (
    log_id             NUMBER(10)      DEFAULT seq_irrigation_logs.NEXTVAL PRIMARY KEY,
    valve_id           NUMBER(10)      NOT NULL,
    zone_id            NUMBER(10)      NOT NULL,
    trigger_source     VARCHAR2(20)    DEFAULT 'AUTO'
        CHECK (trigger_source IN ('AUTO', 'MANUAL', 'SCHEDULED')),
    start_time         TIMESTAMP       NOT NULL,
    end_time           TIMESTAMP,
    water_volume       NUMBER(8,2)     CHECK (water_volume >= 0),
    initial_moisture   NUMBER(5,2)     CHECK (initial_moisture BETWEEN 0 AND 100),
    final_moisture     NUMBER(5,2)     CHECK (final_moisture BETWEEN 0 AND 100),
    status             VARCHAR2(20)    DEFAULT 'COMPLETED'
        CHECK (status IN ('COMPLETED', 'FAILED', 'INTERRUPTED', 'CANCELLED')),
    
    CONSTRAINT fk_logs_valve 
        FOREIGN KEY (valve_id) REFERENCES irrigation_valves(valve_id),
    CONSTRAINT fk_logs_zone 
        FOREIGN KEY (zone_id) REFERENCES farm_zones(zone_id),
    CONSTRAINT chk_end_after_start CHECK (end_time IS NULL OR end_time > start_time)
) TABLESPACE aqua_data;

COMMENT ON TABLE irrigation_logs IS 'Historical record of all irrigation events';

-- ============================================
-- 3. BASIC DATA INTEGRITY CHECK
-- ============================================

-- Verify tables were created
SELECT table_name, tablespace_name, num_rows 
FROM user_tables 
WHERE table_name IN ('FARMERS', 'FARM_ZONES', 'SENSORS', 'SENSOR_DATA', 'IRRIGATION_VALVES', 'IRRIGATION_LOGS')
ORDER BY table_name;

PROMPT === Tables created successfully! ===
