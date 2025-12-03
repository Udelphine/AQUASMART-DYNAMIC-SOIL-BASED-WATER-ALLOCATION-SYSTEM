-- ============================================
-- AQUASMART TABLE CREATION SCRIPT
-- ============================================

-- Connect as application user
CONNECT aqua_app_user/AquaSmart2025@localhost:1521/D_27897_Uwineza_AquaSmart_DB;

-- 1. FARMERS TABLE
CREATE TABLE farmers (
    farmer_id      NUMBER(10)      PRIMARY KEY,
    username       VARCHAR2(30)    NOT NULL UNIQUE,
    email          VARCHAR2(100)   NOT NULL UNIQUE,
    password_hash  VARCHAR2(100)   NOT NULL,
    first_name     VARCHAR2(50),
    last_name      VARCHAR2(50),
    phone          VARCHAR2(20),
    registration_date DATE         DEFAULT SYSDATE,
    status         VARCHAR2(10)    DEFAULT 'ACTIVE' 
        CHECK (status IN ('ACTIVE', 'INACTIVE', 'SUSPENDED')),
    last_login     TIMESTAMP
) TABLESPACE aqua_data;

-- 2. FARM_ZONES TABLE
CREATE TABLE farm_zones (
    zone_id        NUMBER(10)      PRIMARY KEY,
    farmer_id      NUMBER(10)      NOT NULL,
    zone_name      VARCHAR2(100)   NOT NULL,
    crop_type      VARCHAR2(50)    NOT NULL,
    optimal_moisture NUMBER(5,2)   NOT NULL CHECK (optimal_moisture BETWEEN 0 AND 100),
    area_sqm       NUMBER(10,2)    NOT NULL CHECK (area_sqm > 0),
    soil_type      VARCHAR2(20)    DEFAULT 'LOAM',
    irrigation_type VARCHAR2(20)   DEFAULT 'DRIP',
    created_date   DATE            DEFAULT SYSDATE,
    status         VARCHAR2(10)    DEFAULT 'ACTIVE',
    
    CONSTRAINT fk_zone_farmer FOREIGN KEY (farmer_id) 
        REFERENCES farmers(farmer_id) ON DELETE CASCADE,
    CONSTRAINT unique_zone_name UNIQUE (farmer_id, zone_name)
) TABLESPACE aqua_data;

-- 3. SENSORS TABLE
CREATE TABLE sensors (
    sensor_id      NUMBER(10)      PRIMARY KEY,
    zone_id        NUMBER(10)      NOT NULL,
    sensor_code    VARCHAR2(20)    NOT NULL UNIQUE,
    sensor_type    VARCHAR2(20)    DEFAULT 'MOISTURE',
    manufacturer   VARCHAR2(50),
    model          VARCHAR2(30),
    installation_date DATE         DEFAULT SYSDATE,
    last_calibration DATE,
    battery_level  NUMBER(3)       CHECK (battery_level BETWEEN 0 AND 100),
    status         VARCHAR2(15)    DEFAULT 'ACTIVE',
    
    CONSTRAINT fk_sensor_zone FOREIGN KEY (zone_id) 
        REFERENCES farm_zones(zone_id) ON DELETE CASCADE
) TABLESPACE aqua_data;

-- 4. SENSOR_DATA TABLE
CREATE TABLE sensor_data (
    data_id        NUMBER(10)      PRIMARY KEY,
    sensor_id      NUMBER(10)      NOT NULL,
    moisture_value NUMBER(5,2)     NOT NULL CHECK (moisture_value BETWEEN 0 AND 100),
    temperature    NUMBER(4,1),
    reading_time   TIMESTAMP       DEFAULT SYSTIMESTAMP NOT NULL,
    battery_at_reading NUMBER(3),
    signal_strength NUMBER(3),
    status_flag    VARCHAR2(1)     DEFAULT 'N' CHECK (status_flag IN ('N', 'P', 'E')),
    
    CONSTRAINT fk_data_sensor FOREIGN KEY (sensor_id) 
        REFERENCES sensors(sensor_id) ON DELETE CASCADE
) TABLESPACE aqua_data;

-- 5. IRRIGATION_VALVES TABLE
CREATE TABLE irrigation_valves (
    valve_id       NUMBER(10)      PRIMARY KEY,
    zone_id        NUMBER(10)      NOT NULL,
    valve_code     VARCHAR2(20)    NOT NULL UNIQUE,
    valve_type     VARCHAR2(20)    DEFAULT 'SOLENOID',
    flow_rate      NUMBER(6,2)     CHECK (flow_rate > 0),
    installation_date DATE         DEFAULT SYSDATE,
    last_maintenance DATE,
    status         VARCHAR2(15)    DEFAULT 'ACTIVE',
    
    CONSTRAINT fk_valve_zone FOREIGN KEY (zone_id) 
        REFERENCES farm_zones(zone_id) ON DELETE CASCADE
) TABLESPACE aqua_data;

-- 6. IRRIGATION_LOGS TABLE
CREATE TABLE irrigation_logs (
    log_id         NUMBER(10)      PRIMARY KEY,
    valve_id       NUMBER(10)      NOT NULL,
    zone_id        NUMBER(10)      NOT NULL,
    start_time     TIMESTAMP       NOT NULL,
    end_time       TIMESTAMP,
    water_volume   NUMBER(8,2)     CHECK (water_volume >= 0),
    initial_moisture NUMBER(5,2)   CHECK (initial_moisture BETWEEN 0 AND 100),
    final_moisture NUMBER(5,2)     CHECK (final_moisture BETWEEN 0 AND 100),
    trigger_source VARCHAR2(20)    DEFAULT 'AUTO' 
        CHECK (trigger_source IN ('AUTO', 'MANUAL', 'SCHEDULE')),
    status         VARCHAR2(10)    DEFAULT 'COMPLETED',
    
    CONSTRAINT fk_log_valve FOREIGN KEY (valve_id) 
        REFERENCES irrigation_valves(valve_id),
    CONSTRAINT fk_log_zone FOREIGN KEY (zone_id) 
        REFERENCES farm_zones(zone_id),
    CONSTRAINT chk_end_after_start CHECK (end_time IS NULL OR end_time > start_time)
) TABLESPACE aqua_data;

-- 7. WEATHER_DATA TABLE (Optional but good for BI)
CREATE TABLE weather_data (
    weather_id     NUMBER(10)      PRIMARY KEY,
    zone_id        NUMBER(10)      NOT NULL,
    forecast_date  DATE            NOT NULL,
    temperature_high NUMBER(4,1),
    temperature_low NUMBER(4,1),
    precipitation  NUMBER(5,2),
    humidity       NUMBER(3),
    wind_speed     NUMBER(4,1),
    
    CONSTRAINT fk_weather_zone FOREIGN KEY (zone_id) 
        REFERENCES farm_zones(zone_id),
    CONSTRAINT unique_zone_forecast UNIQUE (zone_id, forecast_date)
) TABLESPACE aqua_data;

-- ============================================
-- TABLE CREATION COMPLETE
-- ============================================