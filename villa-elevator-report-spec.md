# Villa Elevator Retrofit Survey Report Spec

## 1. Report Goal

The first report version should help design and quotation teams quickly answer three questions:

1. Can a villa elevator be installed in this existing house?
2. Which shaft, pit, overhead, and landing-door dimensions are risky?
3. Which values are scanned estimates, manually adjusted values, or confirmed measurements?

The report should be simple enough for field staff to complete on site, but structured enough for later software automation.

## 2. PDF Report Structure

### Cover

- Project name
- Customer name
- Site address
- Building type
- Elevator type intention
- Number of floors/stops
- Survey person
- Survey date
- Survey status: draft, reviewed, confirmed

### Summary

- Overall feasibility: feasible, feasible with modification, not recommended, pending review
- Main risk count
- Key missing data count
- Recommended next action

### Key Measurements

- Shaft clear width
- Shaft clear depth
- Pit depth
- Overhead clearance
- Top floor height
- Door opening width by floor
- Door opening height by floor
- Main obstruction notes

### Risk Checklist

- Width insufficient
- Depth insufficient
- Pit insufficient
- Overhead insufficient
- Shaft not vertical
- Beam or pipe obstruction
- Door opening mismatch
- Structural modification likely required
- Water/drainage risk
- Power/control box space issue

Each risk item should include:

- Status: ok, risk, unknown
- Severity: low, medium, high
- Description
- Suggested action

### Photos and Scan Views

- Site overview photo
- Shaft photo
- Pit photo
- Overhead photo
- Each landing door photo
- Marked scan screenshots if available

### Measurement Confidence

Each measurement should show:

- Source: LiDAR scan, manual tap measurement, laser distance meter, manual input
- Confidence: high, medium, low
- Confirmation status: unconfirmed, checked, confirmed
- Confirmed by
- Confirmed time

### Notes

- Design notes
- Quotation notes
- Construction notes
- Follow-up measurement requirements

## 3. Excel Workbook Structure

### Sheet 1: Project_Info

Basic project and survey metadata.

### Sheet 2: Key_Measurements

One row per important dimension.

Columns:

- Category
- Measurement item
- Required for quotation
- Unit
- Scanned value
- Manual value
- Final value
- Source
- Confidence
- Confirmation status
- Risk level
- Notes

### Sheet 3: Door_Openings

One row per landing.

Columns:

- Floor
- Door opening width
- Door opening height
- Sill height
- Centerline offset
- Wall thickness
- Obstruction
- Final status
- Notes

### Sheet 4: Risk_Checklist

One row per risk item.

Columns:

- Risk category
- Risk item
- Status
- Severity
- Evidence
- Suggested action
- Responsible role
- Follow-up required

### Sheet 5: Photo_Index

One row per photo.

Columns:

- Photo ID
- Location
- View type
- Related measurement
- File/link
- Notes

### Sheet 6: Report_Summary

Auto-summary for project review.

Fields:

- Overall feasibility
- Total high risks
- Total medium risks
- Missing required measurements
- Measurements pending confirmation
- Recommended next step

## 4. App Export Rules

- PDF is for human reading and customer/internal review.
- Excel is for design, quotation, and data transfer.
- Every exported value should keep its source and confirmation status.
- The app should never silently overwrite a manually confirmed value with a LiDAR estimate.
- If scanned and manual values differ beyond a threshold, the report should flag the item.

## 5. First Prototype Assumption

Before real LiDAR export is ready, the first clickable or web prototype can use manually entered values but keep the same report structure. This lets the team validate workflow and report usefulness before investing deeply in geometry algorithms.
