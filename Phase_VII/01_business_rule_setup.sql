-- ============================================
-- PHASE VII: BUSINESS RULE SETUP
-- Rule: Employees CANNOT INSERT/UPDATE/DELETE on:
--       1. WEEKDAYS (Monday-Friday)
--       2. PUBLIC HOLIDAYS (upcoming month only)
-- ============================================

-- Create HOLIDAYS table to store upcoming holidays
CREATE TABLE holidays (
    holiday_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    holiday_date DATE NOT NULL,
    holiday_name VARCHAR2(100) NOT NULL,
    description VARCHAR2(200),
    is_recurring CHAR(1) DEFAULT 'N' CHECK (is_recurring IN ('Y', 'N')),
    created_date DATE DEFAULT SYSDATE,
    created_by VARCHAR2(50) DEFAULT USER
);

COMMENT ON TABLE holidays IS 'Stores public holidays for business rule enforcement';
COMMENT ON COLUMN holidays.holiday_date IS 'Date of the holiday';
COMMENT ON COLUMN holidays.holiday_name IS 'Name of the holiday';
COMMENT ON COLUMN holidays.is_recurring IS 'Y if holiday recurs annually, N if one-time';

-- Create index for faster holiday lookups
CREATE INDEX idx_holidays_date ON holidays(holiday_date);

-- Insert sample holidays for testing (next month's holidays)
INSERT INTO holidays (holiday_date, holiday_name, description, is_recurring) 
VALUES (TO_DATE('2025-12-25', 'YYYY-MM-DD'), 'Christmas Day', 'Christmas celebration', 'Y');

INSERT INTO holidays (holiday_date, holiday_name, description, is_recurring) 
VALUES (TO_DATE('2025-12-26', 'YYYY-MM-DD'), 'Boxing Day', 'Day after Christmas', 'Y');

INSERT INTO holidays (holiday_date, holiday_name, description, is_recurring) 
VALUES (TO_DATE('2026-01-01', 'YYYY-MM-DD'), 'New Year''s Day', 'First day of the year', 'Y');

INSERT INTO holidays (holiday_date, holiday_name, description) 
VALUES (TO_DATE('2026-01-15', 'YYYY-MM-DD'), 'Special Event', 'One-time special holiday');

COMMIT;

-- Create EMPLOYEES table for testing business rules
CREATE TABLE employees (
    employee_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    username VARCHAR2(50) NOT NULL UNIQUE,
    full_name VARCHAR2(100) NOT NULL,
    email VARCHAR2(100) NOT NULL UNIQUE,
    department VARCHAR2(50),
    hire_date DATE DEFAULT SYSDATE,
    status VARCHAR2(20) DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'INACTIVE', 'SUSPENDED')),
    created_by VARCHAR2(50) DEFAULT USER,
    created_date DATE DEFAULT SYSDATE
);

COMMENT ON TABLE employees IS 'Employee records for business rule testing';
COMMENT ON COLUMN employees.username IS 'Login username (for rule: username like ''S%'')';

-- Insert test employees (with usernames starting with 'S' for rule enforcement)
INSERT INTO employees (username, full_name, email, department) 
VALUES ('SJOHNDOE', 'John Doe', 'john.doe@company.com', 'IT');

INSERT INTO employees (username, full_name, email, department) 
VALUES ('SSMITH', 'Sarah Smith', 'sarah.smith@company.com', 'HR');

INSERT INTO employees (username, full_name, email, department) 
VALUES ('MJONES', 'Michael Jones', 'michael.jones@company.com', 'Finance'); -- Not restricted (doesn't start with S)

INSERT INTO employees (username, full_name, email, department) 
VALUES ('SWILLIAMS', 'William Williams', 'william@company.com', 'Operations');

COMMIT;

-- Create function to check if today is a holiday
CREATE OR REPLACE FUNCTION is_holiday_today 
RETURN BOOLEAN AS
    v_holiday_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_holiday_count
    FROM holidays
    WHERE holiday_date = TRUNC(SYSDATE);
    
    RETURN (v_holiday_count > 0);
END is_holiday_today;
/

-- Create function to check if current day is weekday (Monday-Friday)
CREATE OR REPLACE FUNCTION is_weekday 
RETURN BOOLEAN AS
    v_day_of_week NUMBER;
BEGIN
    SELECT TO_CHAR(SYSDATE, 'D') INTO v_day_of_week FROM DUAL;
    
    -- Monday=2, Tuesday=3, Wednesday=4, Thursday=5, Friday=6
    RETURN (v_day_of_week BETWEEN 2 AND 6);
END is_weekday;
/

-- Create function to check if operation should be restricted
CREATE OR REPLACE FUNCTION is_operation_restricted(
    p_username IN VARCHAR2
) RETURN BOOLEAN AS
    v_is_employee_s CHAR(1);
    v_is_weekday BOOLEAN;
    v_is_holiday BOOLEAN;
BEGIN
    -- Check if username starts with 'S' (employee S)
    v_is_employee_s := CASE WHEN UPPER(p_username) LIKE 'S%' THEN 'Y' ELSE 'N' END;
    
    IF v_is_employee_s = 'N' THEN
        RETURN FALSE; -- Not an "S" employee, no restriction
    END IF;
    
    -- Check if today is weekday
    v_is_weekday := is_weekday();
    
    -- Check if today is holiday
    v_is_holiday := is_holiday_today();
    
    -- Restrict if weekday OR holiday
    RETURN (v_is_weekday OR v_is_holiday);
END is_operation_restricted;
/

-- Display setup confirmation
DECLARE
    v_holiday_count NUMBER;
    v_employee_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_holiday_count FROM holidays;
    SELECT COUNT(*) INTO v_employee_count FROM employees;
    
    DBMS_OUTPUT.PUT_LINE('============================================');
    DBMS_OUTPUT.PUT_LINE('PHASE VII: BUSINESS RULE SETUP COMPLETE');
    DBMS_OUTPUT.PUT_LINE('============================================');
    DBMS_OUTPUT.PUT_LINE('Tables created:');
    DBMS_OUTPUT.PUT_LINE('  - HOLIDAYS: ' || v_holiday_count || ' holidays inserted');
    DBMS_OUTPUT.PUT_LINE('  - EMPLOYEES: ' || v_employee_count || ' employees inserted');
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('Functions created:');
    DBMS_OUTPUT.PUT_LINE('  1. is_holiday_today');
    DBMS_OUTPUT.PUT_LINE('  2. is_weekday');
    DBMS_OUTPUT.PUT_LINE('  3. is_operation_restricted');
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('Rule: Employees with usernames starting with "S"');
    DBMS_OUTPUT.PUT_LINE('      cannot INSERT/UPDATE/DELETE on weekdays or holidays');
    DBMS_OUTPUT.PUT_LINE('============================================');
END;
/