# Elevator LiDAR Survey App MVP

## 1. Product Positioning

This app is a field survey and renovation-assessment tool for elevator companies, focused first on villa elevator retrofits in existing houses.

The first version should not claim to replace all manual measurement. It should reduce repeated measuring work, lower missed-item risk, create standardized survey records, and help design/quotation teams make faster decisions.

Core positioning:

- Use iPhone Pro LiDAR to scan elevator shafts, door openings, pits, and overhead spaces.
- Convert scans into elevator-specific measurement records.
- Let field staff manually confirm key dimensions.
- Generate PDF and Excel survey reports for design, quotation, and installation planning.

## 2. Target Users

Primary users:

- Sales survey staff
- Site survey engineers
- Installation supervisors
- Villa elevator renovation teams

Secondary users:

- Design engineers
- Quotation staff
- Project managers
- Factory/order review staff

## 3. First MVP Scenario

Start with villa elevator retrofit surveys in existing houses.

MVP scenario:

1. A field worker arrives at the customer's site.
2. They create a project in the app.
3. They scan the shaft, pit, overhead, and door openings with an iPhone Pro.
4. The app extracts preliminary dimensions and flags risks.
5. The worker manually checks and confirms critical dimensions.
6. The app generates a standardized PDF report and Excel measurement table.
7. The report is sent to design/quotation teams.

## 4. MVP Scope

### In Scope

- Project creation
- Guided scanning workflow
- Shaft width and depth measurement
- Pit depth measurement
- Overhead height measurement
- Door opening width and height
- Floor count and landing records
- Wall verticality and obvious deviation prompts
- Obstruction marking
- Manual calibration and confirmation
- Photo attachment
- PDF survey report export
- Excel measurement report export
- Basic cloud/project sharing in later MVP iteration

### Out of Scope for First Version

- Fully automatic construction drawing generation
- Legal compliance judgment
- Replacement of professional final measurement
- Automatic full CAD/BIM model generation
- Support for all elevator types or public/commercial elevator projects
- Direct factory order generation

## 5. Key Measurement Fields

### Project Info

- Project name
- Customer name
- Site address
- Building type
- Elevator type
- Number of floors
- Survey date
- Survey person

### Shaft

- Shaft clear width
- Shaft clear depth
- Shaft wall thickness if visible or manually entered
- Shaft verticality/deviation estimate
- Wall surface irregularities
- Beam, pipe, cable, and other obstructions

### Pit

- Pit depth
- Pit width and depth
- Pit floor flatness note
- Drainage/water risk photo
- Buffer installation space note

### Overhead

- Top floor height
- Overhead clearance
- Beam/ceiling obstruction
- Machine-room-less equipment space note

### Landing Door Openings

- Floor number
- Door opening width
- Door opening height
- Sill height
- Door opening centerline offset
- Wall thickness around door opening
- Obstruction near door opening

### Renovation Risk Notes

- Insufficient width
- Insufficient depth
- Insufficient pit depth
- Insufficient overhead
- Non-vertical shaft
- Protruding beams or pipes
- Door opening mismatch
- Structure modification required

## 6. App Workflow

### Step 1: Create Project

User enters basic project information using the villa elevator retrofit survey template.

### Step 2: Guided Scan

The app guides the user through scan zones:

1. Shaft front and door opening
2. Shaft left/right/rear walls
3. Pit
4. Overhead
5. Each landing door opening

The app should show scan coverage feedback and warn if the scan is incomplete.

### Step 3: Dimension Extraction

The app estimates:

- Main planes
- Distances between planes
- Opening dimensions
- Height clearances
- Obvious protrusions

Each dimension has a confidence level:

- High: can be used as preliminary design reference
- Medium: requires manual confirmation
- Low: must be manually measured

### Step 4: Manual Confirmation

The user can:

- Tap two points to measure
- Adjust detected planes
- Enter laser-distance-meter values
- Mark a value as confirmed
- Attach photos and voice notes

### Step 5: Report Export

The generated PDF report should include:

- Project information
- Key dimension table
- Risk checklist
- Site photos
- Scan screenshots
- Manual confirmation status
- Notes for design/quotation

The generated Excel report should include structured sheets for:

- Project information
- Key measurements
- Landing door openings
- Risk checklist
- Photo index
- Design/quotation notes

## 7. Differentiation

Compared with general LiDAR scanning apps, this product is elevator-specific:

- Uses elevator survey language and fields
- Guides users by installation workflow
- Converts scan results into practical shaft and renovation decisions
- Supports manual confirmation for engineering reliability
- Outputs a report that design and quotation teams can use directly

Compared with high-end 3D scanning systems:

- Lower hardware cost
- Easier for normal field staff
- Faster for early survey and quotation
- More suitable for small villa elevator projects

## 8. Technical Direction

### iOS Capture

- ARKit scene reconstruction for mesh/point data
- Plane detection for walls, floors, and ceilings
- Depth data from LiDAR-capable iPhones/iPads
- Optional RoomPlan exploration for room-like structures

### Geometry Processing

- Plane fitting
- Distance between parallel planes
- Opening detection
- Verticality/deviation estimation
- Obstruction detection from outlier geometry

### Data Model

- Project
- Scan session
- Measurement item
- Manual confirmation
- Risk item
- Photo/note attachment
- Report

### Export

- PDF report first
- Excel measurement workbook first
- USDZ/OBJ/PLY later
- DXF later if design team requires it

## 9. Accuracy Strategy

The app should communicate measurement reliability clearly.

Important principles:

- LiDAR values are preliminary unless manually confirmed.
- Critical dimensions require confirmation.
- The app should support entering values from a laser distance meter.
- The report should record whether each value is scanned, manually adjusted, or manually confirmed.

## 10. First Validation Plan

### Phase A: Field Process Research

Collect 5 to 10 real survey forms or reports from current elevator projects.

Goal:

- Confirm measurement fields
- Identify repeated work
- Identify common missed items
- Understand report format used by design/quotation teams

### Phase B: Manual Prototype

Use a clickable prototype before building full scanning logic.

Goal:

- Validate the guided workflow
- Validate report fields
- Confirm whether field staff can understand the process

### Phase C: LiDAR Measurement Prototype

Build a small iOS prototype that can:

- Scan a shaft-like space
- Fit wall planes
- Measure width/depth/height
- Let user tap two points to measure
- Export a simple report

### Phase D: Real Site Test

Compare app measurements with manual measurements on real projects.

Track:

- Average error
- Maximum error
- Time saved
- Missed-item reduction
- Field worker usability feedback

## 11. MVP Build Roadmap

### Version 0: Report-First Prototype

Goal:

- Validate whether the PDF and Excel report structure matches the real villa elevator retrofit workflow.

Build:

- Manual project creation
- Manual measurement entry
- Risk checklist
- Photo attachment mock
- PDF/Excel export mock

No real LiDAR is required in this version.

### Version 1: LiDAR-Assisted Measurement Prototype

Goal:

- Test whether iPhone LiDAR can reliably capture the shaft, pit, overhead, and door openings enough for preliminary survey use.

Build:

- ARKit scan session
- Point-to-point measurement
- Basic plane detection
- Width/depth/height estimation
- Manual correction
- Excel report export

### Version 2: Guided Field App

Goal:

- Make the app usable by normal field survey staff.

Build:

- Step-by-step scan workflow
- Required-item completion checks
- Confidence labels
- Risk prompts
- PDF report export
- Project sharing

### Version 3: Design and Quotation Integration

Goal:

- Connect the field report to internal design and quotation decisions.

Build:

- Standard villa elevator size matching
- Feasibility recommendation
- Quote-preparation data package
- DXF or simplified CAD export if required

## 12. Immediate Next Questions

To continue, answer these before UI and technical design:

1. What are the must-have measurement fields in the current villa elevator retrofit survey workflow?
2. What report format does the design/quotation team currently trust most: PDF, Excel, photos, CAD sketch, or a combination?
3. What is the acceptable error range for preliminary survey dimensions?
4. Which dimensions must be manually confirmed before quotation?
5. Who will use the app first: internal survey staff, dealers, installation teams, or partner engineers?
