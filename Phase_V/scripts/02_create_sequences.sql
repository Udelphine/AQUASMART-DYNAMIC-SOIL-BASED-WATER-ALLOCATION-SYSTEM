-- ============================================
-- SEQUENCES FOR AUTO-GENERATED IDs
-- ============================================

-- Sequence for farmers
CREATE SEQUENCE seq_farmers
    START WITH 1000
    INCREMENT BY 1
    NOCACHE
    NOCYCLE;

-- Sequence for farm_zones
CREATE SEQUENCE seq_farm_zones
    START WITH 1000
    INCREMENT BY 1
    NOCACHE
    NOCYCLE;

-- Sequence for sensors
CREATE SEQUENCE seq_sensors
    START WITH 1000
    INCREMENT BY 1
    NOCACHE
    NOCYCLE;

-- Sequence for sensor_data
CREATE SEQUENCE seq_sensor_data
    START WITH 1
    INCREMENT BY 1
    NOCACHE
    NOCYCLE;

-- Sequence for irrigation_valves
CREATE SEQUENCE seq_valves
    START WITH 1000
    INCREMENT BY 1
    NOCACHE
    NOCYCLE;

-- Sequence for irrigation_logs
CREATE SEQUENCE seq_irrigation_logs
    START WITH 1
    INCREMENT BY 1
    NOCACHE
    NOCYCLE;

-- Sequence for weather_data
CREATE SEQUENCE seq_weather
    START WITH 1
    INCREMENT BY 1
    NOCACHE
    NOCYCLE;

-- ============================================
-- TRIGGERS TO AUTO-POPULATE IDs
-- ============================================

-- Trigger for farmers
CREATE OR REPLACE TRIGGER trg_farmers_bir
    BEFORE INSERT ON farmers
    FOR EACH ROW
BEGIN
    IF :NEW.farmer_id IS NULL THEN
        :NEW.farmer_id := seq_farmers.NEXTVAL;
    END IF;
END;
/

-- Trigger for farm_zones
CREATE OR REPLACE TRIGGER trg_farm_zones_bir
    BEFORE INSERT ON farm_zones
    FOR EACH ROW
BEGIN
    IF :NEW.zone_id IS NULL THEN
        :NEW.zone_id := seq_farm_zones.NEXTVAL;
    END IF;
END;
/

-- Trigger for sensors
CREATE OR REPLACE TRIGGER trg_sensors_bir
    BEFORE INSERT ON sensors
    FOR EACH ROW
BEGIN
    IF :NEW.sensor_id IS NULL THEN
        :NEW.sensor_id := seq_sensors.NEXTVAL;
    END IF;
END;
/

-- Trigger for sensor_data
CREATE OR REPLACE TRIGGER trg_sensor_data_bir
    BEFORE INSERT ON sensor_data
    FOR EACH ROW
BEGIN
    IF :NEW.data_id IS NULL THEN
        :NEW.data_id := seq_sensor_data.NEXTVAL;
    END IF;
END;
/

-- Trigger for irrigation_valves
CREATE OR REPLACE TRIGGER trg_valves_bir
    BEFORE INSERT ON irrigation_valves
    FOR EACH ROW
BEGIN
    IF :NEW.valve_id IS NULL THEN
        :NEW.valve_id := seq_valves.NEXTVAL;
    END IF;
END;
/

-- Trigger for irrigation_logs
CREATE OR REPLACE TRIGGER trg_irrigation_logs_bir
    BEFORE INSERT ON irrigation_logs
    FOR EACH ROW
BEGIN
    IF :NEW.log_id IS NULL THEN
        :NEW.log_id := seq_irrigation_logs.NEXTVAL;
    END IF;
END;
/

-- Trigger for weather_data
CREATE OR REPLACE TRIGGER trg_weather_bir
    BEFORE INSERT ON weather_data
    FOR EACH ROW
BEGIN
    IF :NEW.weather_id IS NULL THEN
        :NEW.weather_id := seq_weather.NEXTVAL;
    END IF;
END;
/