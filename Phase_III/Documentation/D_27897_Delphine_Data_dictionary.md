# AquaSmart Data Dictionary

## 1. FARMERS Table
| Table | Column | Data Type | Constraints | Description |
|-------|--------|-----------|-------------|-------------|
| FARMERS | farmer_id | NUMBER(10) | PK, NOT NULL | Unique farmer identifier |
| FARMERS | username | VARCHAR2(30) | UNIQUE, NOT NULL | Login username |
| FARMERS | email | VARCHAR2(100) | UNIQUE, NOT NULL | Email address |
| FARMERS | password_hash | VARCHAR2(100) | NOT NULL | Encrypted password |
| FARMERS | registration_date | DATE | DEFAULT SYSDATE | Account creation date |
| FARMERS | status | VARCHAR2(10) | DEFAULT 'ACTIVE' | Account status |

## 2. FARM_ZONES Table
| Table | Column | Data Type | Constraints | Description |
|-------|--------|-----------|-------------|-------------|
| FARM_ZONES | zone_id | NUMBER(10) | PK, NOT NULL | Unique zone identifier |
| FARM_ZONES | farmer_id | NUMBER(10) | FK → FARMERS, NOT NULL | Zone owner |
| FARM_ZONES | zone_name | VARCHAR2(100) | NOT NULL | Zone name |
| FARM_ZONES | crop_type | VARCHAR2(50) | | Current crop type |
| FARM_ZONES | optimal_moisture | NUMBER(5,2) | NOT NULL | Target moisture % |
| FARM_ZONES | area_sqm | NUMBER(10,2) | | Zone area in square meters |
| FARM_ZONES | created_date | DATE | DEFAULT SYSDATE | Creation timestamp |
| FARM_ZONES | status | VARCHAR2(10) | DEFAULT 'ACTIVE' | Zone status |

## 3. SENSORS Table
| Table | Column | Data Type | Constraints | Description |
|-------|--------|-----------|-------------|-------------|
| SENSORS | sensor_id | NUMBER(10) | PK, NOT NULL | Unique sensor identifier |
| SENSORS | zone_id | NUMBER(10) | FK → FARM_ZONES, NOT NULL | Associated zone |
| SENSORS | sensor_code | VARCHAR2(20) | UNIQUE, NOT NULL | Physical sensor code |
| SENSORS | installation_date | DATE | DEFAULT SYSDATE | Installation date |
| SENSORS | battery_level | NUMBER(3) | CHECK (0-100) | Battery percentage |
| SENSORS | status | VARCHAR2(10) | DEFAULT 'ACTIVE' | Sensor status |

## 4. SENSOR_DATA Table
| Table | Column | Data Type | Constraints | Description |
|-------|--------|-----------|-------------|-------------|
| SENSOR_DATA | data_id | NUMBER(10) | PK, NOT NULL | Unique reading identifier |
| SENSOR_DATA | sensor_id | NUMBER(10) | FK → SENSORS, NOT NULL | Source sensor |
| SENSOR_DATA | moisture_value | NUMBER(5,2) | NOT NULL, CHECK (0-100) | Soil moisture % |
| SENSOR_DATA | reading_time | TIMESTAMP | DEFAULT SYSTIMESTAMP | Measurement timestamp |
| SENSOR_DATA | temperature | NUMBER(4,1) | | Temperature in Celsius |
| SENSOR_DATA | status_flag | VARCHAR2(1) | DEFAULT 'N' | N=New, P=Processed |

## 5. IRRIGATION_VALVES Table
| Table | Column | Data Type | Constraints | Description |
|-------|--------|-----------|-------------|-------------|
| IRRIGATION_VALVES | valve_id | NUMBER(10) | PK, NOT NULL | Unique valve identifier |
| IRRIGATION_VALVES | zone_id | NUMBER(10) | FK → FARM_ZONES, NOT NULL | Controlled zone |
| IRRIGATION_VALVES | valve_code | VARCHAR2(20) | UNIQUE, NOT NULL | Physical valve code |
| IRRIGATION_VALVES | flow_rate | NUMBER(6,2) | | Water flow rate (L/min) |
| IRRIGATION_VALVES | installation_date | DATE | DEFAULT SYSDATE | Installation date |
| IRRIGATION_VALVES | status | VARCHAR2(10) | DEFAULT 'ACTIVE' | Valve status |

## 6. IRRIGATION_LOGS Table
| Table | Column | Data Type | Constraints | Description |
|-------|--------|-----------|-------------|-------------|
| IRRIGATION_LOGS | log_id | NUMBER(10) | PK, NOT NULL | Unique log identifier |
| IRRIGATION_LOGS | valve_id | NUMBER(10) | FK → VALVES, NOT NULL | Valve used |
| IRRIGATION_LOGS | zone_id | NUMBER(10) | FK → FARM_ZONES, NOT NULL | Zone irrigated |
| IRRIGATION_LOGS | start_time | TIMESTAMP | NOT NULL | Irrigation start time |
| IRRIGATION_LOGS | end_time | TIMESTAMP | | Irrigation end time |
| IRRIGATION_LOGS | water_volume | NUMBER(8,2) | | Water used in liters |
| IRRIGATION_LOGS | initial_moisture | NUMBER(5,2) | CHECK (0-100) | Moisture before irrigation |
| IRRIGATION_LOGS | final_moisture | NUMBER(5,2) | CHECK (0-100) | Moisture after irrigation |
| IRRIGATION_LOGS | trigger_source | VARCHAR2(20) | DEFAULT 'AUTO' | AUTO or MANUAL |
| IRRIGATION_LOGS | status | VARCHAR2(10) | DEFAULT 'COMPLETED' | Irrigation status |

## Relationships Summary
1. One FARMER owns many FARM_ZONES (1:N)
2. One FARM_ZONE has many SENSORS (1:N)  
3. One SENSOR produces many SENSOR_DATA readings (1:N)
4. One FARM_ZONE controls many IRRIGATION_VALVES (1:N)
5. One VALVE executes many IRRIGATION_LOGS (1:N)
6. IRRIGATION_LOGS also references FARM_ZONES directly (for reporting)

## Normalization Status
All tables satisfy 3rd Normal Form (3NF):
- No repeating groups (1NF ✓)
- All non-key attributes depend on the whole primary key (2NF ✓)
- No transitive dependencies (3NF ✓)