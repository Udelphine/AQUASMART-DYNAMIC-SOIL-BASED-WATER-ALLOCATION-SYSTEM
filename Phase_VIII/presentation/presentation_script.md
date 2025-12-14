# AQUASMART Presentation Script
**Duration:** 15-20 minutes  
**Slides:** 10 slides  
**Presenter:** Uwineza Delphine (ID: 27897)

## Slide 1: Title Slide (30 seconds)
"Good morning/afternoon. My name is Uwineza Delphine, and today I present my capstone project: AQUASMART - a Dynamic Soil-Based Water Allocation System developed for the Database Development with PL/SQL course."

## Slide 2: Problem Statement (1 minute)
"Traditional irrigation systems operate on fixed schedules, wasting 30-50% of water by irrigating regardless of actual soil conditions. This leads to water scarcity, reduced crop yields, and increased operational costs. Farmers need an intelligent system that waters based on actual need, not arbitrary schedules."

## Slide 3: Solution Overview (1 minute)
"AquaSmart solves this through real-time soil monitoring and automated control. Sensors measure moisture, PL/SQL logic analyzes the data, and valves activate precisely when needed. The system achieves 40-60% water savings while improving crop health through optimal irrigation."

## Slide 4: Database Design (1 minute)
"The heart of AquaSmart is an 8-table Oracle database. Four core tables manage irrigation operations, while four Phase VII tables handle security and auditing. This ER diagram shows the relationships, with FARM_ZONES as the central entity linking sensors, valves, and logs."

## Slide 5: Business Process (1 minute)
"Here's how it works: sensors send data to the database, PL/SQL calculates water deficits, decisions are made, valves are controlled, and everything is logged. This swimlane diagram shows the automated workflow from sensing to action, with clear separation of system components."

## Slide 6: Technical Implementation (1 minute)
"I developed comprehensive PL/SQL components: 5 procedures for operations, 4 functions for calculations, and 3 packages organizing the logic. The AQUASMART_CONTROL_PKG handles irrigation, SECURITY_PKG manages restrictions, and AUDIT_PKG tracks all operations."

## Slide 7: Phase VII - Advanced Features (2 minutes)
"A critical requirement was restricting employees with 'S' usernames from modifying data on weekdays and holidays. I implemented this through a HOLIDAYS table, compound triggers, and comprehensive audit logging. Here's the trigger code that enforces this business rule, with 10 test cases validating all scenarios."

## Slide 8: Business Intelligence & Analytics (2 minutes)
"For decision support, I defined 5 key performance indicators and created dashboard mockups. The system tracks water efficiency, irrigation accuracy, system uptime, and savings. These dashboards provide real-time monitoring, historical analysis, and predictive insights for farm managers."

## Slide 9: Results & Testing (2 minutes)
"The implementation includes 8 tables with realistic test data, all PL/SQL components tested, Phase VII restrictions validated, and performance optimized. Screenshots show successful test executions, audit logs capturing all operations, and the database structure in SQL Developer."

## Slide 10: Conclusion & Q&A (1 minute)
"In conclusion, AquaSmart demonstrates complete PL/SQL database development with advanced features. Key achievements include the Phase VII business rule implementation, comprehensive auditing, and business intelligence readiness. The project taught me requirements-driven design and the power of Oracle PL/SQL. Future enhancements could include mobile apps and machine learning. Thank you. I'm now ready for your questions."