-- ============================================
-- AQUASMART TABLE CREATION SCRIPT
-- Student: Uwineza Delphine (ID: 27897)
-- Phase V: Table Implementation
-- ============================================

-- Disable foreign key checks temporarily
SET CONSTRAINTS ALL DEFERRED;

-- Table 1: FARMERS
CREATE TABLE farmers (
    farmer_id NUMBER(10) PRIMARY KEY,
    username VARCHAR2(50) NOT NULL,
    email VARCHAR2(100) NOT NULL UNIQUE,
    password_hash VARCHAR2(128) NOT NULL,
    registration_date DATE DEFAULT SYSDATE NOT NULL,
    status VARCHAR2(10) DEFAULT 'ACTIVE' NOT NULL 
        CHECK (status IN ('ACTIVE', 'INACTIVE', 'SUSPENDED')),
    last_login_date DATE,
    phone_number VARCHAR2(20),
    address VARCHAR2(200)
);

-- Table 2: FARM_ZONES
CREATE TABLE farm_zones (
    zone_id NUMBER(10) PRIMARY KEY,
    farmer_id NUMBER(10) NOT NULL 
        REFERENCES farmers(farmer_id) ON DELETE CASCADE,
    zone_name VARCHAR2(100) NOT NULL,
    crop_type VARCHAR2(50) NOT NULL,
    optimal_moisture NUMBER(5,2) NOT NULL 
        CHECK (optimal_moisture BETWEEN 0 AND 100),
    area_sqm NUMBER(8,2) NOT NULL CHECK (area_sqm > 0),
    created_date DATE DEFAULT SYSDATE NOT NULL,
    status VARCHAR2(10) DEFAULT 'ACTIVE' NOT NULL 
        CHECK (status IN ('ACTIVE', 'INACTIVE', 'MAINTENANCE')),
    soil_type VARCHAR2(50),
    irrigation_method VARCHAR2(30) DEFAULT 'DRIP' 
        CHECK (irrigation_method IN ('DRIP', 'SPRINKLER', 'FLOOD'))
);

ALTER TABLE farm_zones ADD CONSTRAINT uq_farm_zone_name UNIQUE (farmer_id, zone_name);

-- Table 3: SENSORS
CREATE TABLE sensors (
    sensor_id NUMBER(10) PRIMARY KEY,
    zone_id NUMBER(10) NOT NULL 
        REFERENCES farm_zones(zone_id) ON DELETE CASCADE,
    sensor_code VARCHAR2(20) NOT NULL UNIQUE,
    installation_date DATE DEFAULT SYSDATE NOT NULL,
    battery_level NUMBER(3,0) DEFAULT 100 NOT NULL 
        CHECK (battery_level BETWEEN 0 AND 100),
    status VARCHAR2(15) DEFAULT 'ACTIVE' NOT NULL 
        CHECK (status IN ('ACTIVE', 'INACTIVE', 'CALIBRATING', 'FAULTY')),
    sensor_type VARCHAR2(20) DEFAULT 'SOIL_MOISTURE' 
        CHECK (sensor_type IN ('SOIL_MOISTURE', 'TEMPERATURE', 'HUMIDITY')),
    last_maintenance_date DATE,
    calibration_due_date DATE
);

-- Table 4: IRRIGATION_VALVES
CREATE TABLE irrigation_valves (
    valve_id NUMBER(10) PRIMARY KEY,
    zone_id NUMBER(10) NOT NULL 
        REFERENCES farm_zones(zone_id) ON DELETE CASCADE,
    valve_code VARCHAR2(20) NOT NULL UNIQUE,
    flow_rate NUMBER(6,2) NOT NULL CHECK (flow_rate > 0),
    installation_date DATE DEFAULT SYSDATE NOT NULL,
    status VARCHAR2(15) DEFAULT 'CLOSED' NOT NULL 
        CHECK (status IN ('OPEN', 'CLOSED', 'FAULTY', 'MAINTENANCE')),
    valve_type VARCHAR2(20) DEFAULT 'SOLENOID' 
        CHECK (valve_type IN ('SOLENOID', 'MOTORIZED', 'MANUAL')),
    last_activation_date DATE,
    total_water_volume NUMBER(12,2) DEFAULT 0
);

-- Table 5: SENSOR_DATA
CREATE TABLE sensor_data (
    data_id NUMBER(10) PRIMARY KEY,
    sensor_id NUMBER(10) NOT NULL 
        REFERENCES sensors(sensor_id) ON DELETE CASCADE,
    moisture_value NUMBER(5,2) NOT NULL 
        CHECK (moisture_value BETWEEN 0 AND 100),
    reading_time TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
    temperature NUMBER(4,1),
    status_flag VARCHAR2(1) DEFAULT 'P' 
        CHECK (status_flag IN ('P', 'A', 'E')),
    reading_quality NUMBER(3,0) DEFAULT 100 
        CHECK (reading_quality BETWEEN 0 AND 100)
);

CREATE INDEX idx_sensor_data_sensor ON sensor_data(sensor_id);
CREATE INDEX idx_sensor_data_time ON sensor_data(reading_time);

-- Table 6: IRRIGATION_LOGS
CREATE TABLE irrigation_logs (
    log_id NUMBER(10) PRIMARY KEY,
    valve_id NUMBER(10) NOT NULL 
        REFERENCES irrigation_valves(valve_id) ON DELETE CASCADE,
    zone_id NUMBER(10) NOT NULL 
        REFERENCES farm_zones(zone_id) ON DELETE CASCADE,
    trigger_source VARCHAR2(20) NOT NULL 
        CHECK (trigger_source IN ('AUTOMATIC', 'MANUAL', 'SCHEDULED', 'EMERGENCY')),
    start_time TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
    end_time TIMESTAMP,
    water_volume NUMBER(10,2) 
        CHECK (water_volume >= 0),
    initial_moisture NUMBER(5,2),
    final_moisture NUMBER(5,2),
    status VARCHAR2(20) DEFAULT 'COMPLETED' 
        CHECK (status IN ('STARTED', 'COMPLETED', 'FAILED', 'CANCELLED')),
    energy_consumption NUMBER(8,2),
    notes VARCHAR2(500)
);

CREATE INDEX idx_irrig_logs_valve ON irrigation_logs(valve_id);
CREATE INDEX idx_irrig_logs_zone ON irrigation_logs(zone_id);
CREATE INDEX idx_irrig_logs_time ON irrigation_logs(start_time);

-- Create sequences
CREATE SEQUENCE seq_farmers_id START WITH 1001 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_farm_zones_id START WITH 2001 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_sensors_id START WITH 3001 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_valves_id START WITH 4001 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_sensor_data_id START WITH 5001 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_irrigation_logs_id START WITH 6001 INCREMENT BY 1 NOCACHE NOCYCLE;

-- Enable constraints
SET CONSTRAINTS ALL IMMEDIATE;

PROMPT === ALL 6 TABLES CREATED SUCCESSFULLY ===