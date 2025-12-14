# DASHBOARD MOCKUPS
## AquaSmart Business Intelligence

## 1. EXECUTIVE SUMMARY DASHBOARD

### Layout:

┌─────────────────────────────────────────────────────────┐
│ AQUASMART - EXECUTIVE DASHBOARD │ Date: 12-Dec-2025 │
├─────────────────┬─────────────────┬─────────────────────┤
│ [KPI 1] │ [KPI 2] │ [KPI 3] │
│ Water Saved │ System Uptime │ Cost Savings │
│ 45,200 L ▲15% │ 99.7% ✅ │ $2,150 ▲12% │
├─────────────────┴─────────────────┴─────────────────────┤
│ [WATER USAGE TREND] │
│ Line chart: Last 30 days usage vs target │
├─────────────────┬─────────────────┬─────────────────────┤
│ [TOP ZONES] │ [ALERTS] │ [EFFICIENCY] │
│ 1. North Corn │ ⚠ 2 Valves │ Score: 94% ✅ │
│ 2. South Veg │ ✓ All sensors │ Target: 90% │
│ 3. East Wheat │ │ │
└─────────────────┴─────────────────┴─────────────────────┘

### Components:
1. **Header:**
   - Project title "AquaSmart Irrigation System"
   - Current date/time
   - Refresh button
   - Export options (PDF, Excel)

2. **KPI Cards (Top Row):**
   - **Card 1:** Total Water Saved (liters, % change)
   - **Card 2:** System Uptime (percentage, status indicator)
   - **Card 3:** Cost Savings (currency, % change)
   - **Visual:** Green/red arrows for trends, status icons

3. **Central Chart:**
   - **Title:** "Water Usage vs Target - Last 30 Days"
   - **Type:** Dual-line chart
   - **Line 1:** Actual water usage (blue)
   - **Line 2:** Target/optimal usage (green dashed)
   - **X-axis:** Dates
   - **Y-axis:** Liters (thousands)
   - **Interaction:** Hover for daily values, click to drill down

4. **Bottom Panels:**
   - **Panel 1:** "Top Performing Zones" (table with rank, name, efficiency)
   - **Panel 2:** "Active Alerts" (count with severity indicators)
   - **Panel 3:** "Overall Efficiency Score" (gauge chart 0-100%)

## 2. REAL-TIME MONITORING DASHBOARD

### Layout:

┌─────────────────────────────────────────────────────────┐
│ REAL-TIME MONITORING │ Last Updated: 14:30:05 │
├───────────┬───────────┬───────────┬───────────┬─────────┤
│ [ZONE 1] │ [ZONE 2] │ [ZONE 3] │ [ZONE 4] │ [ZONE 5]│
│ Corn │ Tomatoes │ Wheat │ Lettuce │ Carrots │
│ 68% ✅ │ 45% ⚠ │ 72% ✅ │ 65% ✅ │ 41% ⚠ │
│ 22°C │ 24°C │ 20°C │ 23°C │ 25°C │
│ IRRIG: ON │ IRRIG: OFF│ IRRIG: OFF│ IRRIG: ON │ IRRIG ON│
├───────────┴───────────┴───────────┴───────────┴─────────┤
│ [SYSTEM MAP] │
│ Farm layout with zone status overlay │
├───────────┬───────────┬─────────────────────────────────┤
│ [WEATHER] │ [VALVES] │ [RECENT ACTIVITIES] │
│ ☀ 24°C │ 45/48 OK │ 14:25: Zone 2 dry detected │
│ 💧 10% │ 2 FAULT │ 14:28: Zone 5 irrigation start │
│ 💨 5 km/h │ 1 MAINT │ 14:30: Zone 1 irrigation stop │
└───────────┴───────────┴─────────────────────────────────┘

### Components:
1. **Zone Status Cards:**
   - Zone name and crop type
   - Current moisture (percentage with color coding)
   - Temperature
   - Irrigation status (ON/OFF with icon)
   - **Color Scheme:**
     - Green: 60-75% (optimal)
     - Yellow: 40-59% or 76-85% (warning)
     - Red: <40% or >85% (critical)

2. **Interactive Farm Map:**
   - Visual representation of farm layout
   - Zones color-coded by moisture status
   - Click zones for detailed view
   - Real-time valve status indicators

3. **Side Panels:**
   - **Weather Panel:** Current conditions with icons
   - **Valve Status:** Summary of valve health
   - **Activity Log:** Timestamped system events

## 3. HISTORICAL ANALYTICS DASHBOARD

### Layout:

┌─────────────────────────────────────────────────────────┐
│ HISTORICAL ANALYTICS │ Period: Last Quarter │
├─────────────────────────────────────────────────────────┤
│ [WATER USAGE BY CROP TYPE] │
│ Bar chart: Corn vs Vegetables vs Fruits │
├───────────┬───────────┬─────────────────────────────────┤
│ [TRENDS] │ [PEAKS] │ [COMPARISON] │
│ │ │ This Month vs Last Month │
│ │ │ This Year vs Last Year │
├───────────┴───────────┴─────────────────────────────────┤
│ [EFFICIENCY OVER TIME] │
│ Line chart: Weekly efficiency scores │
└─────────────────────────────────────────────────────────┘

### Components:
1. **Time Period Selector:**
   - Quick select: Today, Week, Month, Quarter, Year, Custom
   - Date range picker
   - Comparison toggle (vs. previous period)

2. **Water Usage Analysis:**
   - **Chart:** Stacked bar chart by crop type
   - **Filters:** By zone, by week/month, by irrigation type
   - **Metrics:** Total liters, average per day, % of total

3. **Trend Analysis Panel:**
   - **Sub-chart 1:** Efficiency trend line
   - **Sub-chart 2:** Usage peaks identification
   - **Sub-chart 3:** Period-over-period comparison

## 4. AUDIT & COMPLIANCE DASHBOARD (Phase VII)

### Layout:

┌─────────────────────────────────────────────────────────┐
│ AUDIT & COMPLIANCE DASHBOARD │ Today: 12-Dec-2025 │
├─────────────────┬─────────────────┬─────────────────────┤
│ [OPERATIONS] │ [RESTRICTIONS] │ [USERS] │
│ Total: 1,245 │ Blocked: 12 │ Active: 8 │
│ Ins: 450 │ Reason: Weekday │ Top: SJOHNSON (45) │
│ Upd: 600 │ Reason: Holiday │ │
│ Del: 195 │ │ │
├─────────────────┴───────────────────────────────────────┤
│ [AUDIT TIMELINE - LAST 7 DAYS] │
│ Gantt chart: Operations by user and time │
├─────────────────┬───────────────────────────────────────┤
│ [VIOLATIONS] │ [COMPLIANCE SCORE] │
│ By User │ Daily: 99.2% ✅ │
│ By Time │ Weekly: 98.7% ✅ │
│ By Reason │ Monthly: 99.0% ✅ │
└─────────────────┴───────────────────────────────────────┘

### Components:
1. **Summary Metrics:**
   - Total operations count
   - Restricted/blocked operations
   - Active users and top performers

2. **Audit Timeline:**
   - Visual timeline of all operations
   - Color-coded by operation type (INSERT/UPDATE/DELETE)
   - Filter by user, table, or time period

3. **Compliance Analysis:**
   - Violation patterns by user, time, reason
   - Compliance scores at different frequencies
   - Trend analysis of compliance over time

## 5. MOBILE DASHBOARD (Responsive Design)

### Key Features:
1. **Simplified View:** Essential KPIs only
2. **Push Notifications:** Critical alerts
3. **Touch-Optimized:** Large buttons, swipe navigation
4. **Offline Capability:** Cache recent data
5. **Quick Actions:** Start/stop irrigation, acknowledge alerts

## Dashboard Implementation Notes

### Color Scheme:
- **Green (#4CAF50):** Optimal, successful, within target
- **Yellow (#FFC107):** Warning, attention needed
- **Red (#F44336):** Critical, immediate action required
- **Blue (#2196F3):** Informational, neutral status
- **Gray (#9E9E9E):** Inactive, disabled

### Interactive Features:
1. **Drill-down:** Click any chart element for detailed view
2. **Filtering:** Select time periods, zones, crop types
3. **Export:** PDF reports, Excel data, image snapshots
4. **Refresh:** Manual and auto-refresh options
5. **Alerts:** Visual and audible notifications

### Accessibility Features:
1. **Screen Reader Support:** ARIA labels for all elements
2. **Keyboard Navigation:** Tab through all components
3. **Color Blind Mode:** Alternative color schemes
4. **High Contrast Mode:** For low vision users
5. **Font Scaling:** Adjustable text sizes

### Technical Implementation:
- **Frontend:** React.js with Chart.js/D3.js
- **Backend:** REST API from Oracle database
- **Real-time:** WebSocket connections for live data
- **Authentication:** JWT tokens with role-based access
- **Hosting:** Cloud platform with auto-scaling