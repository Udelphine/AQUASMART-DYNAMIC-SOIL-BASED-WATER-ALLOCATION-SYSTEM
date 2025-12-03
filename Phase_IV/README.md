# Phase IV: Database Creation - AquaSmart

## 📋 Project Information

- **Database Name:** D_27897_Uwineza_AquaSmart_DB
- **Admin User:** aqua_admin / Delphine
- **Application User:** aqua_app_user / AquaSmart2025

## 🎯 Phase Objectives
Create and configure Oracle Pluggable Database (PDB) for AquaSmart irrigation system with proper tablespaces, users, security, and performance settings.

## 🗄️ Database Structure

### A. Tablespaces Created
| Tablespace | Type | Size | Purpose |
|------------|------|------|---------|
| **aqua_data** | Permanent | 100M (Autoextend) | Stores all application tables |
| **aqua_index** | Permanent | 50M (Autoextend) | Stores indexes for performance |
| **aqua_temp** | Temporary | 50M (Autoextend) | Temporary operations/sorting |
| **aqua_undo** | Undo | 100M (Autoextend) | Transaction rollback information |

### B. Users & Roles
| User | Password | Role | Purpose |
|------|----------|------|---------|
| **aqua_admin** | Delphine | DBA | Database administration |
| **aqua_app_user** | AquaSmart2025 | Application Owner | Main application schema |
| **aqua_dev** | DevPass2025 | Developer | Development and testing |
| **aqua_analyst_user** | Analyst2025 | Analyst | BI and reporting access |

### C. Security Configuration
- Password expiration: 90 days
- Archive logging enabled for recovery
- Auditing enabled for critical operations
- Role-based access control implemented
- Network ACL for web services

## 📜 Scripts Description

### 1. `D_27897_Uwineza_Create_Database.sql`
- Creates PDB with proper naming convention
- Sets up tablespaces with autoextend
- Configures memory parameters (SGA=512M, PGA=256M)
- Enables archive logging
- Creates initial users with privileges

### 2. `D_27897_Uwineza_User_Setup.sql`
- Creates additional users for different roles
- Sets up password policies
- Configures network security ACL
- Grants appropriate privileges

### 3. `D_27897_Uwineza_Configuration.sql`
- Configures performance parameters
- Sets up auditing and monitoring
- Creates maintenance jobs
- Configures backup settings (example)

## 🔧 Installation Steps

### Prerequisites
- Oracle Database 19c or higher
- SYSDBA privileges
- 1GB free disk space minimum

### Execution Order:
1. **Create Database:** Run `Create_Database.sql` as SYSDBA
2. **Setup Users:** Run `User_Setup.sql` as SYSDBA
3. **Configuration:** Run `Configuration.sql` as aqua_admin

### Verification:
```sql
-- Check database
SELECT name, open_mode FROM v$database;

-- Check tablespaces  
SELECT tablespace_name, status FROM dba_tablespaces;

-- Check users
SELECT username, account_status FROM dba_users;