import fs from "node:fs/promises";
import { SpreadsheetFile, Workbook } from "@oai/artifact-tool";

const outputDir = "/Users/chenbaiyu/Documents/Codex/2026-05-27/lidar/outputs";
const outputPath = `${outputDir}/villa_elevator_retrofit_survey_template.xlsx`;

const workbook = Workbook.create();

function addSheet(name) {
  const sheet = workbook.worksheets.add(name);
  return sheet;
}

function setValues(sheet, range, values) {
  sheet.getRange(range).values = values;
}

function applyHeader(sheet, range) {
  const r = sheet.getRange(range);
  r.format.fill.color = "#17324D";
  r.format.font.color = "#FFFFFF";
  r.format.font.bold = true;
  r.format.horizontalAlignment = "Center";
}

function applyTitle(sheet, range) {
  const r = sheet.getRange(range);
  r.format.fill.color = "#EAF1F7";
  r.format.font.color = "#17324D";
  r.format.font.bold = true;
  r.format.font.size = 14;
}

function applySection(sheet, range) {
  const r = sheet.getRange(range);
  r.format.fill.color = "#F2F6FA";
  r.format.font.bold = true;
}

function applyBorders(sheet, range) {
  const r = sheet.getRange(range);
  r.format.borders.getItem("InsideHorizontal").style = "Continuous";
  r.format.borders.getItem("InsideVertical").style = "Continuous";
  r.format.borders.getItem("EdgeTop").style = "Continuous";
  r.format.borders.getItem("EdgeBottom").style = "Continuous";
  r.format.borders.getItem("EdgeLeft").style = "Continuous";
  r.format.borders.getItem("EdgeRight").style = "Continuous";
}

function autofit(sheet, range) {
  const r = sheet.getRange(range);
  r.format.autofitColumns();
  r.format.autofitRows();
}

const project = addSheet("Project_Info");
setValues(project, "A1:F1", [["Villa Elevator Retrofit Survey", "", "", "", "", ""]]);
applyTitle(project, "A1:F1");
project.getRange("A1:F1").merge();
setValues(project, "A3:B18", [
  ["Project name", ""],
  ["Customer name", ""],
  ["Site address", ""],
  ["Building type", "Existing villa / old house"],
  ["Elevator intention", "Villa elevator retrofit"],
  ["Floors / stops", ""],
  ["Survey date", ""],
  ["Survey person", ""],
  ["Phone", ""],
  ["Report status", "Draft"],
  ["Overall feasibility", "Pending review"],
  ["Recommended next step", ""],
  ["Design reviewer", ""],
  ["Quotation reviewer", ""],
  ["Notes", ""],
  ["Version", "MVP template v0.1"],
]);
applySection(project, "A3:A18");
applyBorders(project, "A3:B18");
autofit(project, "A1:F20");

const key = addSheet("Key_Measurements");
setValues(key, "A1:L1", [[
  "Category",
  "Measurement item",
  "Required for quotation",
  "Unit",
  "Scanned value",
  "Manual value",
  "Final value",
  "Source",
  "Confidence",
  "Confirmation status",
  "Risk level",
  "Notes",
]]);
applyHeader(key, "A1:L1");
setValues(key, "A2:L21", [
  ["Shaft", "Shaft clear width", "Yes", "mm", "", "", "", "LiDAR / manual", "Medium", "Unconfirmed", "Unknown", ""],
  ["Shaft", "Shaft clear depth", "Yes", "mm", "", "", "", "LiDAR / manual", "Medium", "Unconfirmed", "Unknown", ""],
  ["Shaft", "Shaft verticality deviation", "Yes", "mm", "", "", "", "LiDAR estimate", "Low", "Unconfirmed", "Unknown", ""],
  ["Shaft", "Left wall obstruction", "No", "text", "", "", "", "Photo / manual", "Medium", "Unconfirmed", "Unknown", ""],
  ["Shaft", "Right wall obstruction", "No", "text", "", "", "", "Photo / manual", "Medium", "Unconfirmed", "Unknown", ""],
  ["Shaft", "Rear wall obstruction", "No", "text", "", "", "", "Photo / manual", "Medium", "Unconfirmed", "Unknown", ""],
  ["Pit", "Pit depth", "Yes", "mm", "", "", "", "LiDAR / manual", "Medium", "Unconfirmed", "Unknown", ""],
  ["Pit", "Pit clear width", "Yes", "mm", "", "", "", "LiDAR / manual", "Medium", "Unconfirmed", "Unknown", ""],
  ["Pit", "Pit clear depth", "Yes", "mm", "", "", "", "LiDAR / manual", "Medium", "Unconfirmed", "Unknown", ""],
  ["Pit", "Drainage / water risk", "No", "text", "", "", "", "Photo / manual", "Medium", "Unconfirmed", "Unknown", ""],
  ["Overhead", "Top floor height", "Yes", "mm", "", "", "", "LiDAR / manual", "Medium", "Unconfirmed", "Unknown", ""],
  ["Overhead", "Overhead clearance", "Yes", "mm", "", "", "", "LiDAR / manual", "Medium", "Unconfirmed", "Unknown", ""],
  ["Overhead", "Beam / ceiling obstruction", "No", "text", "", "", "", "Photo / manual", "Medium", "Unconfirmed", "Unknown", ""],
  ["Door", "Typical door opening width", "Yes", "mm", "", "", "", "LiDAR / manual", "Medium", "Unconfirmed", "Unknown", ""],
  ["Door", "Typical door opening height", "Yes", "mm", "", "", "", "LiDAR / manual", "Medium", "Unconfirmed", "Unknown", ""],
  ["Door", "Door centerline offset", "Yes", "mm", "", "", "", "LiDAR / manual", "Low", "Unconfirmed", "Unknown", ""],
  ["Electrical", "Power/control box space", "No", "text", "", "", "", "Manual note", "Low", "Unconfirmed", "Unknown", ""],
  ["Access", "Material handling access", "No", "text", "", "", "", "Manual note", "Low", "Unconfirmed", "Unknown", ""],
  ["Structure", "Structural modification likely", "Yes", "Yes/No", "", "", "", "Manual judgment", "Low", "Unconfirmed", "Unknown", ""],
  ["General", "Additional follow-up required", "No", "text", "", "", "", "Manual note", "Low", "Unconfirmed", "Unknown", ""],
]);
applyBorders(key, "A1:L21");
autofit(key, "A1:L21");

const doors = addSheet("Door_Openings");
setValues(doors, "A1:I1", [[
  "Floor",
  "Door opening width (mm)",
  "Door opening height (mm)",
  "Sill height (mm)",
  "Centerline offset (mm)",
  "Wall thickness (mm)",
  "Obstruction",
  "Final status",
  "Notes",
]]);
applyHeader(doors, "A1:I1");
setValues(doors, "A2:I7", [
  ["F1", "", "", "", "", "", "", "Unconfirmed", ""],
  ["F2", "", "", "", "", "", "", "Unconfirmed", ""],
  ["F3", "", "", "", "", "", "", "Unconfirmed", ""],
  ["F4", "", "", "", "", "", "", "Unconfirmed", ""],
  ["F5", "", "", "", "", "", "", "Unconfirmed", ""],
  ["Other", "", "", "", "", "", "", "Unconfirmed", ""],
]);
applyBorders(doors, "A1:I7");
autofit(doors, "A1:I7");

const risks = addSheet("Risk_Checklist");
setValues(risks, "A1:H1", [[
  "Risk category",
  "Risk item",
  "Status",
  "Severity",
  "Evidence",
  "Suggested action",
  "Responsible role",
  "Follow-up required",
]]);
applyHeader(risks, "A1:H1");
setValues(risks, "A2:H11", [
  ["Shaft", "Width insufficient", "Unknown", "Medium", "", "", "Design", "Yes"],
  ["Shaft", "Depth insufficient", "Unknown", "Medium", "", "", "Design", "Yes"],
  ["Pit", "Pit depth insufficient", "Unknown", "High", "", "", "Design / installation", "Yes"],
  ["Overhead", "Overhead insufficient", "Unknown", "High", "", "", "Design / installation", "Yes"],
  ["Shaft", "Shaft not vertical", "Unknown", "Medium", "", "", "Survey / design", "Yes"],
  ["Structure", "Beam or pipe obstruction", "Unknown", "Medium", "", "", "Installation", "Yes"],
  ["Door", "Door opening mismatch", "Unknown", "Medium", "", "", "Design", "Yes"],
  ["Structure", "Structural modification required", "Unknown", "High", "", "", "Owner / contractor", "Yes"],
  ["Pit", "Water or drainage risk", "Unknown", "Medium", "", "", "Installation", "Yes"],
  ["Electrical", "Power/control box space issue", "Unknown", "Low", "", "", "Electrical", "No"],
]);
applyBorders(risks, "A1:H11");
autofit(risks, "A1:H11");

const photos = addSheet("Photo_Index");
setValues(photos, "A1:F1", [["Photo ID", "Location", "View type", "Related measurement", "File/link", "Notes"]]);
applyHeader(photos, "A1:F1");
setValues(photos, "A2:F9", [
  ["P001", "Site", "Overview", "", "", ""],
  ["P002", "Shaft", "Front", "Shaft clear width/depth", "", ""],
  ["P003", "Pit", "Top-down", "Pit depth", "", ""],
  ["P004", "Overhead", "Upward", "Overhead clearance", "", ""],
  ["P005", "F1", "Door opening", "Door opening width/height", "", ""],
  ["P006", "F2", "Door opening", "Door opening width/height", "", ""],
  ["P007", "F3", "Door opening", "Door opening width/height", "", ""],
  ["P008", "Other", "Risk detail", "", "", ""],
]);
applyBorders(photos, "A1:F9");
autofit(photos, "A1:F9");

const summary = addSheet("Report_Summary");
setValues(summary, "A1:D1", [["Villa Elevator Retrofit Survey Summary", "", "", ""]]);
applyTitle(summary, "A1:D1");
summary.getRange("A1:D1").merge();
setValues(summary, "A3:B9", [
  ["Overall feasibility", "Pending review"],
  ["High risks", '=COUNTIFS(Risk_Checklist!C2:C11,"Risk",Risk_Checklist!D2:D11,"High")'],
  ["Medium risks", '=COUNTIFS(Risk_Checklist!C2:C11,"Risk",Risk_Checklist!D2:D11,"Medium")'],
  ["Missing required measurements", '=SUMPRODUCT((Key_Measurements!C2:C21="Yes")*(Key_Measurements!G2:G21=""))'],
  ["Measurements pending confirmation", '=COUNTIF(Key_Measurements!J2:J21,"Unconfirmed")'],
  ["Door openings pending confirmation", '=COUNTIF(Door_Openings!H2:H7,"Unconfirmed")'],
  ["Recommended next step", ""],
]);
applySection(summary, "A3:A9");
applyBorders(summary, "A3:B9");
autofit(summary, "A1:D12");

await fs.mkdir(outputDir, { recursive: true });
const blob = await SpreadsheetFile.exportXlsx(workbook);
await blob.save(outputPath);
console.log(outputPath);
