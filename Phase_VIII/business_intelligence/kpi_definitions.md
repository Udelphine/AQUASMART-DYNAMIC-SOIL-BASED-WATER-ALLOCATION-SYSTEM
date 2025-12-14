# AQUASMART Key Performance Indicators (KPIs)

## Overview
This document defines the KPIs used to measure the performance and effectiveness of the AquaSmart irrigation system.

## 1. Operational Efficiency KPIs

### 1.1. Water Efficiency Ratio
- **Code:** KPI-001
- **Formula:** (Actual Water Used / Optimal Water Required) × 100%
- **Target:** 90-110%
- **Below Target:** < 90% (Under-irrigation risk)
- **Above Target:** > 110% (Over-irrigation/waste)
- **Calculation Frequency:** Daily
- **Data Source:** `irrigation_logs`, `sensor_data`

### 1.2. Irrigation Accuracy
- **Code:** KPI-002
- **Formula:** 100% - ABS((Actual Moisture - Target Moisture) / Target Moisture × 100%)
- **Target:** > 95%
- **Measurement:** Percentage
- **Importance:** Measures precision of irrigation control
- **Data Source:** `sensor_data`, `farm_zones`

### 1.3. System Uptime
- **Code:** KPI-003
- **Formula:** (Total Time - Downtime) / Total Time × 100%
- **Target:** > 99.5%
- **Measurement:** Percentage
- **Calculation Frequency:** Weekly
- **Data Source:** `system_logs`, `audit_log`

## 2. Resource Management KPIs

### 2.1. Water Savings
- **Code:** KPI-004
- **Formula:** Traditional System Usage - AquaSmart Usage
- **Target:** 40% reduction minimum
- **Unit:** Liters per month
- **Baseline:** Historical pre-implementation data
- **Data Source:** `irrigation_logs` (comparative analysis)

### 2.2. Energy Consumption per Irrigation
- **Code:** KPI-005
- **Formula:** Total Energy Used / Number of Irrigation Events
- **Target:** < 2.5 kWh per event
- **Unit:** Kilowatt-hours
- **Optimization Goal:** Reduce by 15% quarterly
- **Data Source:** `energy_monitor`, `irrigation_logs`

### 2.3. Maintenance Cost Ratio
- **Code:** KPI-006
- **Formula:** Maintenance Costs / Total Operational Costs × 100%
- **Target:** < 8%
- **Measurement:** Percentage
- **Calculation Frequency:** Monthly
- **Data Source:** `maintenance_logs`, `financial_records`

## 3. Agricultural Performance KPIs

### 3.1. Crop Health Index
- **Code:** KPI-007
- **Formula:** Composite score based on:
  - Moisture consistency (40%)
  - Growth rate (30%)
  - Yield prediction (30%)
- **Target:** > 85/100
- **Scale:** 0-100
- **Calculation Frequency:** Weekly
- **Data Source:** `sensor_data`, `crop_monitoring`

### 3.2. Yield Correlation Coefficient
- **Code:** KPI-008
- **Formula:** Statistical correlation between irrigation accuracy and crop yield
- **Target:** > 0.7
- **Range:** -1 to +1
- **Importance:** Measures impact on productivity
- **Data Source:** Historical yield data, `irrigation_logs`

## 4. Business & Compliance KPIs

### 4.1. Return on Investment (ROI)
- **Code:** KPI-009
- **Formula:** (Total Savings - Total Costs) / Total Costs × 100%
- **Target:** > 25% annual
- **Timeframe:** Annual calculation
- **Components:** Water savings, labor reduction, yield improvement
- **Data Source:** Financial records, operational data

### 4.2. Regulatory Compliance Score
- **Code:** KPI-010
- **Formula:** Number of compliant days / Total days × 100%
- **Target:** 100%
- **Regulations:** Local water usage limits
- **Penalties:** Financial fines for non-compliance
- **Data Source:** `compliance_logs`, regulatory databases

### 4.3. User Adoption Rate
- **Code:** KPI-011
- **Formula:** Active Users / Total Potential Users × 100%
- **Target:** > 80%
- **Measurement:** Percentage of farm staff using system
- **Training Impact:** Correlates with training effectiveness
- **Data Source:** `user_activity_logs`

## 5. Technical Performance KPIs

### 5.1. Data Accuracy
- **Code:** KPI-012
- **Formula:** (Correct Readings / Total Readings) × 100%
- **Target:** > 99%
- **Validation:** Manual sensor calibration checks
- **Impact:** Critical for irrigation decisions
- **Data Source:** `sensor_calibration_logs`

### 5.2. System Response Time
- **Code:** KPI-013
- **Formula:** Average time from sensor reading to valve activation
- **Target:** < 10 seconds
- **Maximum:** 30 seconds (critical threshold)
- **Importance:** Affects irrigation effectiveness
- **Data Source:** `system_performance_logs`

### 5.3. Data Completeness
- **Code:** KPI-014
- **Formula:** (Records with all fields / Total records) × 100%
- **Target:** > 98%
- **Gaps:** Missing sensor data, incomplete logs
- **Impact:** Affects analytics accuracy
- **Data Source:** Database audit queries

## 6. Sustainability KPIs

### 6.1. Carbon Footprint Reduction
- **Code:** KPI-015
- **Formula:** Traditional system emissions - AquaSmart emissions
- **Target:** 20% reduction annually
- **Components:** Energy savings, water treatment reduction
- **Measurement:** CO2 equivalents
- **Data Source:** Energy consumption logs, water treatment data

### 6.2. Water Conservation Contribution
- **Code:** KPI-016
- **Formula:** Total water saved / Regional water scarcity index
- **Target:** Contribute to 10% regional conservation goal
- **Context:** Local water scarcity conditions
- **Reporting:** Annual sustainability report
- **Data Source:** Water authority data, system logs

## KPI Dashboard Configuration

### Color Coding Scheme
- **Green:** Within target range (≥ target)
- **Yellow:** Within acceptable range (80-99% of target)
- **Red:** Below acceptable range (< 80% of target)

### Alert Thresholds
- **Warning:** 10% below target for 3 consecutive days
- **Critical:** 20% below target or 1 day of system failure
- **Emergency:** Complete system failure or regulatory violation

### Reporting Schedule
- **Daily:** Operational KPIs (KPI-001 to KPI-003)
- **Weekly:** Resource and agricultural KPIs (KPI-004 to KPI-008)
- **Monthly:** Business and technical KPIs (KPI-009 to KPI-014)
- **Quarterly:** Sustainability KPIs (KPI-015 to KPI-016)
- **Annual:** All KPIs for strategic review

## Data Validation Rules
1. All KPI calculations must be auditable
2. Source data must be timestamped and user-identified
3. Calculations must handle null values appropriately
4. Historical comparisons require consistent methodology
5. Seasonal adjustments must be documented

## Revision History
| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | Dec 2025 | Uwineza Delphine | Initial KPI definitions |
| 1.1 | Dec 2025 | Uwineza Delphine | Added sustainability KPIs |
| 1.2 | Dec 2025 | Uwineza Delphine | Enhanced validation rules |