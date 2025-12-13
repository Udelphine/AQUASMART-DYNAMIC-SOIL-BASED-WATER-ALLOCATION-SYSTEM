# PHASE V: TABLE IMPLEMENTATION & DATA INSERTION

## Project: AquaSmart - Dynamic Soil-Based Water Allocation System
**Student:** Uwineza Delphine  
**ID:** 27897  
**Group:** D  
**Date Completed:** December 12, 2025  
**Database:** d_27897_delphine_aquasmart_db

## OBJECTIVES ACCOMPLISHED
✅ Created all 6 tables from ER diagram  
✅ Implemented comprehensive constraints (PK, FK, CHECK, UNIQUE, NOT NULL)  
✅ Inserted realistic test data (100+ records in main tables)  
✅ Created sequences for auto-incrementing primary keys  
✅ Validated data integrity and business rules  
✅ Created required test queries (Basic, Joins, Aggregations, Subqueries)

## DATABASE SCHEMA IMPLEMENTED

### 1. FARMERS Table
- **Records:** 5 farmers
- **Purpose:** Stores farmer registration information
- **Key Fields:** farmer_id (PK), username, email, status
- **Constraints:** Unique email, status validation

### 2. FARM_ZONES Table  
- **Records:** 7 irrigation zones
- **Purpose:** Defines different crop areas on each farm
- **Key Fields:** zone_id (PK), farmer_id (FK), optimal_moisture, area_sqm
- **Constraints:** Unique zone names per farmer, moisture range validation

### 3. SENSORS Table
- **Records:** 12+ sensors
- **Purpose:** Soil moisture and temperature sensors
- **Key Fields:** sensor_id (PK), sensor_code (Unique), battery_level
- **Constraints:** Battery level 0-100%, status validation

### 4. IRRIGATION_VALVES Table
- **Records:** 10+ valves
- **Purpose:** Water control valves for each zone
- **Key Fields:** valve_id (PK), valve_code (Unique), flow_rate
- **Constraints:** Positive flow rate, status validation

### 5. SENSOR_DATA Table
- **Records:** 1000+ readings
- **Purpose:** Historical sensor measurements
- **Key Fields:** data_id (PK), moisture_value, reading_time
- **Constraints:** Moisture 0-100%, timestamp ordering

### 6. IRRIGATION_LOGS Table
- **Records:** 50+ events
- **Purpose:** Complete irrigation history
- **Key Fields:** log_id (PK), water_volume, start_time, end_time
- **Constraints:** Volume calculation, status validation

## DATA VOLUME SUMMARY
| Table | Records | Description |
|-------|---------|-------------|
| FARMERS | 5 | Registered farmers (4 active, 1 inactive) |
| FARM_ZONES | 7 | Irrigation zones across all farms |
| SENSORS | 12+ | Soil moisture and temperature sensors |
| IRRIGATION_VALVES | 10+ | Water control valves |
| SENSOR_DATA | 1000+ | Historical sensor readings (30 days) |
| IRRIGATION_LOGS | 50+ | Irrigation events with details |

## CONSTRAINTS IMPLEMENTED
- **Primary Keys:** All tables have surrogate PKs
- **Foreign Keys:** All relationships with ON DELETE CASCADE
- **CHECK Constraints:** 
  - Moisture values: 0-100%
  - Battery levels: 0-100%
  - Area values: > 0
  - Status fields: Valid values only
- **UNIQUE Constraints:** Email, sensor codes, valve codes
- **NOT NULL:** All required business fields

## SEQUENCES CREATED
- `seq_farmers_id` - Starts at 1001
- `seq_farm_zones_id` - Starts at 2001  
- `seq_sensors_id` - Starts at 3001
- `seq_valves_id` - Starts at 4001
- `seq_sensor_data_id` - Starts at 5001
- `seq_irrigation_logs_id` - Starts at 6001

## TESTING PERFORMED
### 1. Basic Retrieval
- SELECT * from all tables
- Verified data types and formats

### 2. Join Operations  
- Farmers ↔ Farm Zones
- Zones ↔ Sensors ↔ Sensor Data
- Valves ↔ Irrigation Logs

### 3. Aggregations
- Water usage summaries
- Average moisture calculations
- Event counting by status

### 4. Subqueries
- Latest sensor readings
- Zones needing irrigation
- Comparative analysis

### 5. Data Validation
- Referential integrity checks
- Constraint validation
- Business rule verification

## SCREENSHOTS INCLUDED
1. Table creation success messages
2. Data insertion confirmation
3. Validation query results
4. Test query outputs
5. Sample data displays
6. Final counts verification

## FILES IN THIS PHASE
- `01_table_creation.sql` - Complete DDL for all tables
- `02_data_insertion.sql` - Test data population scripts
- `03_validation_queries.sql` - Data integrity validation
- `04_test_queries.sql` - Required test queries
- `screenshots/` - All proof images

## BUSINESS RULES ENFORCED
1. Each farmer has unique zone names
2. Soil moisture always between 0-100%
3. Battery levels monitored and validated
4. Irrigation events track water volume accurately
5. Sensor readings time-ordered and quality-checked

## NEXT PHASE (PHASE VI)
Develop PL/SQL programming elements:
- Stored procedures for automated irrigation
- Functions for calculations and validations
- Packages for system modules
- Cursors for data processing
- Exception handling

---
**Verified by:** Uwineza Delphine  
**Date:** December 12, 2025  
**Status:** PHASE V COMPLETED ✅