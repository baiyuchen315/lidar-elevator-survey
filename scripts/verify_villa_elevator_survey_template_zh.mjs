import fs from "node:fs/promises";
import { FileBlob, SpreadsheetFile } from "@oai/artifact-tool";

const workbookPath = "/Users/chenbaiyu/Documents/Codex/2026-05-27/lidar/outputs/villa_elevator_retrofit_survey_template_zh.xlsx";
const previewDir = "/Users/chenbaiyu/Documents/Codex/2026-05-27/lidar/outputs/previews_zh";

const input = await FileBlob.load(workbookPath);
const workbook = await SpreadsheetFile.importXlsx(input);

const summary = await workbook.inspect({
  kind: "table",
  range: "报告汇总!A1:D12",
  include: "values,formulas",
  tableMaxRows: 20,
  tableMaxCols: 6,
});
console.log(summary.ndjson);

const errors = await workbook.inspect({
  kind: "match",
  searchTerm: "#REF!|#DIV/0!|#VALUE!|#NAME\\?|#N/A",
  options: { useRegex: true, maxResults: 300 },
  summary: "formula error scan",
});
console.log(errors.ndjson);

await fs.mkdir(previewDir, { recursive: true });
for (const sheetName of ["项目基本信息", "关键尺寸", "报告汇总"]) {
  const rendered = await workbook.render({ sheetName, scale: 1.5 });
  const bytes = Buffer.from(await rendered.arrayBuffer());
  await fs.writeFile(`${previewDir}/${sheetName}.png`, bytes);
}

console.log("verified");
