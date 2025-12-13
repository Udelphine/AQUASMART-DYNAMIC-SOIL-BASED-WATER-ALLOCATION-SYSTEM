# PHASE IV: DATABASE CREATION

## Project Information
- **Project**: AquaSmart Dynamic Soil-Based Water Allocation System
- **Student**: Uwineza Delphine
- **ID**: 27897
- **Group**: D

## Database Details
- **Database Name**: d_27897_delphine_aquasmart_db
- **Admin User**: aquasmart_admin
- **Admin Password**: Delphine
- **Application User**: aquasmart_app
- **Application Password**: AppPass123

## Components Created
### 1. Tablespaces
| Tablespace | Type | Size | Purpose |
|------------|------|------|---------|
| aquasmart_data | Permanent | 100MB | Store table data |
| aquasmart_index | Permanent | 50MB | Store indexes |
| aquasmart_temp | Temporary | 50MB | Sort operations |

### 2. Users & Privileges
- **aquasmart_admin**: Full DBA privileges (for development)
- **aquasmart_app**: Basic connect privileges (for application)

### 3. Configuration
- Auto-extend enabled for all tablespaces
- Archive logging: Will be configured in production
- Created in Oracle XE 21c

## Files in This Phase
- `01_database_setup.sql` - Complete creation script
- `02_verification_queries.sql` - Verification commands
- `screenshots/` - Proof of successful creation

## Screenshots Included
1. PDB creation success
2. PDB opened successfully  
3. Connection to aquasmart_admin
4. Tablespaces created
5. Users verified
6. Complete verification results
