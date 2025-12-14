# AQUASMART-DYNAMIC-SOIL-BASED-WATER-ALLOCATION-SYSTEM
Dynamic Soil-Based Water Allocation System - PL/SQL Capstone Project


## 👤 Student Information
- **Name:** Uwineza Delphine
- **ID:** 27897
- **Group:** D
- **Course:** Database Development with PL/SQL (INSY 8311)
- **University:** Adventist University of Central Africa (AUCA)
- **Lecturer:** Eric Maniraquha
- **Academic Year:** 2025-2026 | Semester I

## 📋 Project Overview
AquaSmart is an intelligent irrigation system that uses real-time soil measurements to optimize water allocation. Unlike traditional timer-based systems, AquaSmart waters each farm zone based on actual soil needs, achieving 40-60% water savings.

## 🎯 Project Phases Completed

### Phase I: Problem Identification ✅
- Problem statement presentation
- Context and target users defined
- Business intelligence potential identified

### Phase II: Business Process Modeling ✅
- UML/BPMN diagrams
- Swimlane workflow diagrams
- Process documentation

### Phase III: Logical Database Design ✅
- ER diagram (3NF normalization)
- Data dictionary
- Business intelligence considerations

### Phase IV: Database Creation ✅
- Oracle PDB setup
- Tablespace configuration
- User administration

### Phase V: Table Implementation ✅
- CREATE TABLE scripts
- INSERT statements with realistic data
- Constraints and indexes
- Data validation queries

### Phase VI: PL/SQL Development ✅
- Stored procedures (3-5)
- Functions (3-5)
- Cursors and window functions
- Packages and exception handling

### Phase VII: Advanced Programming & Auditing ✅
- **Business Rule:** Employees with 'S' usernames restricted on weekdays/holidays
- Holiday management system
- Comprehensive audit logging
- Simple and compound triggers
- 10 comprehensive test cases

### Phase VIII: Final Documentation & BI ✅
- GitHub repository organization
- Business intelligence implementation
- Complete documentation
- 10-slide presentation


## 🛠️ Technical Implementation

### Database Objects Created:
- **Tables:** 8 (HOLIDAYS, EMPLOYEES, AUDIT_LOG, EMPLOYEE_SALARY, FARM_ZONES, SENSOR_DATA, IRRIGATION_VALVES, IRRIGATION_LOGS)
- **Functions:** 4 (is_holiday_today, is_weekday, is_operation_restricted, log_audit_entry)
- **Triggers:** 5 (INSERT/UPDATE/DELETE restrictions, related table, compound)
- **Business Rule:** Username 'S%' restriction on weekdays/holidays

### Key Features:
1. **Real-time Monitoring:** Continuous soil moisture tracking
2. **Automated Control:** Intelligent irrigation decisions
3. **Audit Trail:** All operations logged with user context
4. **Business Intelligence:** Analytical queries and KPIs
5. **Scalability:** Designed for expansion

## 📸 Project Screenshots


### **1. ER Diagram**

<img width="3675" height="3319" alt="Aquasmart_ER" src="https://github.com/user-attachments/assets/4ae4680e-67c3-4bd2-936c-746871159299" />

### **2. Database Structure** 

<img width="1364" height="612" alt="all_tables_created" src="https://github.com/user-attachments/assets/9ac1d7aa-22e3-495f-882e-2eba2a20ceca" />

### **3. Phase VII Test** 

<img width="1365" height="551" alt="weekday_test" src="https://github.com/user-attachments/assets/0cf7e98b-ca1c-4ac9-a9bc-1470f36f8505" />

### **4. Dashboard Results** 

<img width="1365" height="590" alt="all_queries_executed" src="https://github.com/user-attachments/assets/4754b47f-8de5-47d3-8152-bec058d85af2" />


### **5. Test Execution** 

<img width="1365" height="617" alt="cursors_execution" src="https://github.com/user-attachments/assets/0f781dc9-b4e2-4ff8-9c31-6d3064d0bcd5" />

### **6. Sample Data** 

<img width="1363" height="476" alt="sample_farmers" src="https://github.com/user-attachments/assets/f2dc9c5e-3aea-407d-902e-ee09eb74b2cb" />
<img width="1365" height="536" alt="sensordata_results" src="https://github.com/user-attachments/assets/b6115e52-bcff-43a1-9fde-d15072817c85" />

### **7. OEM Monitoring** 

<img width="835" height="564" alt="oem1" src="https://github.com/user-attachments/assets/487f848d-a172-4ce7-b46e-280c08ec5361" />
<img width="832" height="559" alt="oem2" src="https://github.com/user-attachments/assets/e7bbb050-9ecb-4e17-9027-7526aaa4dbda" />
<img width="832" height="565" alt="oem3" src="https://github.com/user-attachments/assets/5e7bd0c3-bc32-4c57-aa64-482dac95c71d" />
<img width="822" height="578" alt="oem4" src="https://github.com/user-attachments/assets/184c5cf6-c181-461c-9ca2-b49f11dc6824" />
<img width="816" height="575" alt="oem5" src="https://github.com/user-attachments/assets/3d1a3a6c-c653-4bf7-b85d-091841827a28" />
<img width="821" height="575" alt="oem6" src="https://github.com/user-attachments/assets/d9a955c7-2842-42b5-b548-f7c478b9e003" />

### **8. Table Structure** 

<img width="1365" height="487" alt="farmzones_results" src="https://github.com/user-attachments/assets/08e286d1-2957-4f21-895a-09528ea49ec3" />

### **9. PL/SQL Code** 

<img width="1365" height="611" alt="packages_created" src="https://github.com/user-attachments/assets/e2d3bb6b-1547-4b69-884c-be34ea7e7093" />

### **10. Audit Log** 

<img width="1365" height="611" alt="packages_created" src="https://github.com/user-attachments/assets/36785ba9-dc83-4e6f-a9a9-e151d4e186b1" />

### **11. Analytics Results** 

<img width="835" height="564" alt="oem1" src="https://github.com/user-attachments/assets/bc0d0e16-0687-48f4-9e47-6f612764826c" />

### **12. Constraint Testing** 

<img width="1364" height="542" alt="all_constraints" src="https://github.com/user-attachments/assets/700ed86b-7ce5-4870-b29e-b1fb79038621" />

