# DATA DICTIONARY
## AquaSmart Irrigation System - YOUR ACTUAL TABLES

## TABLE 1: HOLIDAYS (Phase VII)
**Purpose:** Stores public holidays for business rule enforcement.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| holiday_id | NUMBER | PK, IDENTITY | Unique holiday ID |
| holiday_name | VARCHAR2(100) | NOT NULL | Name of holiday |
| holiday_date | DATE | NOT NULL | Date of holiday |
| description | VARCHAR2(500) | | Holiday description |
| is_recurring | CHAR(1) | DEFAULT 'N' | Recurring flag |
| created_date | DATE | DEFAULT SYSDATE | Creation date |

**Sample Data:**
- Christmas Day - 2025-12-25
- New Year's Day - 2026-01-01

## TABLE 2: EMPLOYEES (Phase VII)
**Purpose:** Employee records for business rule testing.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| employee_id | NUMBER | PK, IDENTITY | Employee ID |
| username | VARCHAR2(50) | UNIQUE, NOT NULL | Username (for 'S%' rule) |
| full_name | VARCHAR2(100) | NOT NULL | Full name |
| email | VARCHAR2(100) | UNIQUE, NOT NULL | Email address |
| department | VARCHAR2(50) | | Department |
| hire_date | DATE | DEFAULT SYSDATE | Hire date |
| status | VARCHAR2(20) | DEFAULT 'ACTIVE' | Status |

**Sample Data:**
- SJOHNDOE - John Doe - IT department
- SSMITH - Sarah Smith - HR department

## TABLE 3: AUDIT_LOG (Phase VII)
**Purpose:** Comprehensive audit trail for all operations.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| audit_id | NUMBER | PK, IDENTITY | Audit ID |
| table_name | VARCHAR2(50) | NOT NULL | Table name |
| operation_type | VARCHAR2(10) | NOT NULL | INSERT/UPDATE/DELETE |
| username | VARCHAR2(50) | NOT NULL | Username |
| operation_date | TIMESTAMP | DEFAULT SYSTIMESTAMP | Operation time |
| restricted_attempt | CHAR(1) | NOT NULL | Y=restricted, N=allowed |
| restriction_reason | VARCHAR2(200) | | Reason for restriction |
| ip_address | VARCHAR2(45) | | IP address |
| machine_name | VARCHAR2(100) | | Machine name |

## TABLE 4: EMPLOYEE_SALARY (Phase VII)
**Purpose:** Related table for extended business rule testing.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| salary_id | NUMBER | PK, IDENTITY | Salary ID |
| employee_id | NUMBER | FK → employees | Employee reference |
| salary_amount | NUMBER(10,2) | NOT NULL | Salary amount |
| effective_date | DATE | | Effective date |
| created_date | DATE | DEFAULT SYSDATE | Creation date |

## TABLE 5: FARM_ZONES (Your AquaSmart Table)
**Purpose:** Stores irrigation zones with crop requirements.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| zone_id | NUMBER | PK, NOT NULL | Unique zone identifier |
| zone_name | VARCHAR2(100) | NOT NULL | Zone name |
| crop_type | VARCHAR2(50) | NOT NULL | Type of crop |
| optimal_moisture_level | NUMBER | NOT NULL | Perfect soil moisture level |

## TABLE 6: SENSOR_DATA (Your AquaSmart Table)
**Purpose:** Logs sensor readings from the field.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| data_id | NUMBER | PK, NOT NULL | Unique reading ID |
| zone_id | NUMBER | FK → farm_zones | Which zone |
| sensor_moisture_reading | NUMBER | NOT NULL | Soil moisture reading |
| reading_timestamp | DATE | NOT NULL | When measured |
| status | VARCHAR2(20) | | Flags if processed |

## TABLE 7: IRRIGATION_VALVES (Your AquaSmart Table)
**Purpose:** Controls water valves.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| valve_id | NUMBER | PK, NOT NULL | Unique valve ID |
| zone_id | NUMBER | FK → farm_zones | Which zone it waters |
| valve_status | VARCHAR2(10) | | ON or OFF |

## TABLE 8: IRRIGATION_LOGS (Your AquaSmart Table)
**Purpose:** History of watering events.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| log_id | NUMBER | PK, NOT NULL | Unique log ID |
| zone_id | NUMBER | FK → farm_zones | Where water was applied |
| water_volume | NUMBER | NOT NULL | How much was used |
| start_time | DATE | NOT NULL | When started |
| end_time | DATE | | When stopped |

## TOTAL: 8 TABLES (YOUR ACTUAL DATABASE)

## BUSINESS RULE IMPLEMENTED (Phase VII):
**"Employees with usernames starting with 'S' CANNOT INSERT/UPDATE/DELETE on:**
1. **WEEKDAYS** (Monday-Friday)
2. **PUBLIC HOLIDAYS** (upcoming month only)"

## FUNCTIONS CREATED:
1. `is_holiday_today()` - Checks if current date is a holiday
2. `is_weekday()` - Checks if current day is Monday-Friday
3. `is_operation_restricted()` - Main business rule logic
4. `log_audit_entry()` - Autonomous transaction logging

## TRIGGERS CREATED:
1. `trg_employees_insert` - INSERT restriction
2. `trg_employees_update` - UPDATE restriction  
3. `trg_employees_delete` - DELETE restriction
4. `trg_employee_salary_restrict` - Related table restriction
5. `trg_employees_compound` - Compound trigger (demonstration)
