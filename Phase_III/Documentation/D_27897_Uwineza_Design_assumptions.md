# AquaSmart Design Assumptions

## Business Assumptions
- Each farmer owns multiple irrigation zones
- Zones grow one crop type at a time
- Soil readings occur every 15 minutes
- Irrigation triggers at 10% below optimal moisture
- Manual override available for emergencies

## Technical Assumptions
- Oracle Database 19c
- IDs auto-generated via sequences
- Moisture values: 0-100% range
- Water measured in liters
- Temperature in Celsius

## Data Volume Estimates
- FARMERS: 100 records
- FARM_ZONES: 500 records
- SENSOR_DATA: 50,000+ daily readings
- IRRIGATION_LOGS: 500+ daily events

## Security & Compliance
- Password encryption (SHA-256)
- Audit logging for all irrigation
- Historical data kept 3 years
- PL/SQL procedures for data access