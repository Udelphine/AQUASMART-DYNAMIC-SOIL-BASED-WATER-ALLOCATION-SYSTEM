# Phase V: Table Implementation & Data Insertion - AquaSmart

## 📋 Project Information
- **Names:** Uwineza Delphine
- **ID:** 27897
- **Group:** D

## 🎯 Phase Objectives
Build the physical database structure with realistic test data (100-500+ rows per main table) and implement comprehensive validation and testing.

## 📊 Database Structure Implemented

### **Tables Created (7 Tables):**
1. **FARMERS** - System users and farm owners (100+ records)
2. **FARM_ZONES** - Irrigation zones within farms (300+ records)
3. **SENSORS** - Physical sensor devices (500+ records)
4. **SENSOR_DATA** - Soil moisture and temperature readings (10,000+ records)
5. **IRRIGATION_VALVES** - Water control valves (300+ records)
6. **IRRIGATION_LOGS** - Irrigation event history (5,000+ records)
7. **WEATHER_DATA** - External weather information (1,000+ records)

### **Relationships:**
- FARMERS (1) → FARM_ZONES (M)
- FARM_ZONES (1) → SENSORS (M)
- SENSORS (1) → SENSOR_DATA (M)
- FARM_ZONES (1) → IRRIGATION_VALVES (M)
- VALVES (1) → IRRIGATION_LOGS (M)
- FARM_ZONES (1) → WEATHER_DATA (M)

## 📁 Scripts Overview

### **A. `/scripts/` Folder:**

#### **1. `01_create_tables.sql`**
- Creates all 7 tables with proper data types
- Implements PRIMARY KEY and FOREIGN KEY constraints
- Sets up CHECK constraints for data validation
- Configures DEFAULT values and NOT NULL constraints

#### **2. `02_create_sequences.sql`**
- Creates sequences for auto-incrementing IDs
- Implements BEFORE INSERT triggers for automatic ID generation
- Configures sequence starting values and increments

#### **3. `03_insert_data.sql`**
- Inserts realistic test data meeting project requirements:
  - 100+ farmers with Rwandan names and contact info
  - 300+ farm zones with various crop types
  - 500+ sensors with realistic specifications
  - 10,000+ sensor readings (15-minute intervals)
  - 300+ irrigation valves
  - 5,000+ irrigation logs
  - 1,000+ weather records
- Uses PL/SQL loops for efficient bulk insertion
- Includes data verification summary

#### **4. `04_add_constraints.sql`**
- Adds advanced CHECK constraints (email format, phone validation)
- Creates 25+ performance indexes (B-tree, bitmap, function-based)
- Implements 4 analytical views for common queries
- Sets up synonyms for easier table access
- Includes partitioning concepts (commented out)

### **B. `/queries/` Folder:**

#### **1. `01_validation_queries.sql`**
- **Data Completeness:** Checks for NULL values and record counts
- **Data Integrity:** Validates foreign key relationships
- **Data Quality:** Verifies value ranges and business rules
- **Constraint Validation:** Checks unique constraints
- **Data Consistency:** Validates temporal relationships
- **Summary Report:** Provides pass/fail status for all checks

#### **2. `02_test_queries.sql`**
- **Basic Retrieval:** Simple SELECT * queries
- **Join Queries:** Multi-table relationships (5+ join examples)
- **Aggregation:** GROUP BY with COUNT, SUM, AVG, MIN, MAX
- **Subqueries:** Correlated and non-correlated subqueries
- **Advanced Queries:** Window functions preview
- **Performance Testing:** Execution time measurements
- **Test Summary:** Automated test result reporting

#### **3. `03_bi_queries.sql`**
- **Executive KPIs:** 5 key performance indicators
- **Water Analytics:** Usage trends, efficiency metrics
- **Crop Performance:** Moisture consistency, irrigation frequency
- **Sensor Health:** Battery status, maintenance alerts
- **Predictive Analytics:** Trend analysis, irrigation predictions
- **Dashboard Queries:** Ready-to-use dashboard components
- **BI Summary:** Automated insight generation

## 🔧 Technical Specifications

### **Data Types Used:**
- **NUMBER:** For IDs, counts, measurements
- **VARCHAR2:** For names, codes, descriptions
- **DATE/TIMESTAMP:** For temporal data
- **CHECK Constraints:** For data validation

### **Constraints Implemented:**
- PRIMARY KEY constraints on all tables
- FOREIGN KEY constraints for referential integrity
- UNIQUE constraints for business keys
- CHECK constraints for data validation
- NOT NULL constraints for mandatory fields
- DEFAULT values for common scenarios

### **Performance Optimizations:**
- B-tree indexes for equality/range searches
- Bitmap indexes for low-cardinality columns
- Function-based indexes for computed columns
- Composite indexes for common query patterns
- Views for complex queries

## ✅ Requirements Met

### **From Project PDF (Page 5):**
- [x] **Table Creation:** All entities converted to tables ✓
- [x] **Oracle Data Types:** Correctly used ✓
- [x] **PKs and FKs:** Properly enforced ✓
- [x] **Indexes:** Appropriately created ✓
- [x] **Constraints:** NOT NULL, UNIQUE, CHECK, DEFAULT ✓
- [x] **Data Insertion:** 100-500+ realistic rows per main table ✓
- [x] **Realistic Data:** Represents actual use cases ✓
- [x] **Edge Cases:** Includes nulls and boundary values ✓
- [x] **Data Integrity Verification:** SELECT queries verify data ✓
- [x] **Testing Queries:** Basic retrieval, joins, aggregations, subqueries ✓

## 🚀 Execution Instructions

### **Prerequisites:**
- Oracle Database 19c or higher
- Phase IV database created and configured
- Application user `aqua_app_user` with proper privileges

### **Execution Order:**
1. **Create Tables:** Run `scripts/01_create_tables.sql`
2. **Create Sequences:** Run `scripts/02_create_sequences.sql`
3. **Insert Data:** Run `scripts/03_insert_data.sql`
4. **Add Constraints:** Run `scripts/04_add_constraints.sql`
5. **Validate Data:** Run `queries/01_validation_queries.sql`
6. **Test Queries:** Run `queries/02_test_queries.sql`
7. **BI Analysis:** Run `queries/03_bi_queries.sql`

### **Verification:**
```sql
-- Quick verification
SELECT 'FARMERS' AS table, COUNT(*) AS records FROM farmers UNION ALL
SELECT 'FARM_ZONES', COUNT(*) FROM farm_zones UNION ALL
SELECT 'SENSORS', COUNT(*) FROM sensors UNION ALL
SELECT 'SENSOR_DATA', COUNT(*) FROM sensor_data UNION ALL
SELECT 'IRRIGATION_VALVES', COUNT(*) FROM irrigation_valves UNION ALL
SELECT 'IRRIGATION_LOGS', COUNT(*) FROM irrigation_logs UNION ALL
SELECT 'WEATHER_DATA', COUNT(*) FROM weather_data;