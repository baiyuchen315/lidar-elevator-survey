import fs from "node:fs/promises";
import { SpreadsheetFile, Workbook } from "@oai/artifact-tool";

const outputDir = "/Users/chenbaiyu/Documents/Codex/2026-05-27/lidar/outputs";
const outputPath = `${outputDir}/villa_elevator_retrofit_survey_template_zh.xlsx`;

const workbook = Workbook.create();

function addSheet(name) {
  return workbook.worksheets.add(name);
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
  for (const name of ["InsideHorizontal", "InsideVertical", "EdgeTop", "EdgeBottom", "EdgeLeft", "EdgeRight"]) {
    r.format.borders.getItem(name).style = "Continuous";
  }
}

function autofit(sheet, range) {
  const r = sheet.getRange(range);
  r.format.autofitColumns();
  r.format.autofitRows();
}

const project = addSheet("项目基本信息");
setValues(project, "A1:F1", [["别墅梯旧房改造现场勘测报告", "", "", "", "", ""]]);
applyTitle(project, "A1:F1");
project.getRange("A1:F1").merge();
setValues(project, "A3:B18", [
  ["项目名称", ""],
  ["客户姓名", ""],
  ["现场地址", ""],
  ["建筑类型", "既有别墅 / 旧房"],
  ["电梯类型意向", "别墅梯旧房改造"],
  ["楼层 / 站数", ""],
  ["勘测日期", ""],
  ["勘测人员", ""],
  ["联系电话", ""],
  ["报告状态", "草稿"],
  ["总体可行性", "待复核"],
  ["建议下一步", ""],
  ["设计复核人", ""],
  ["报价复核人", ""],
  ["备注", ""],
  ["模板版本", "MVP 模板 v0.1"],
]);
applySection(project, "A3:A18");
applyBorders(project, "A3:B18");
autofit(project, "A1:F20");

const key = addSheet("关键尺寸");
setValues(key, "A1:L1", [[
  "类别",
  "测量项目",
  "报价必需",
  "单位",
  "扫描值",
  "人工值",
  "最终值",
  "数据来源",
  "置信度",
  "复核状态",
  "风险等级",
  "备注",
]]);
applyHeader(key, "A1:L1");
setValues(key, "A2:L21", [
  ["井道", "井道净宽", "是", "mm", "", "", "", "LiDAR / 人工", "中", "未复核", "未知", ""],
  ["井道", "井道净深", "是", "mm", "", "", "", "LiDAR / 人工", "中", "未复核", "未知", ""],
  ["井道", "井道垂直偏差", "是", "mm", "", "", "", "LiDAR 估算", "低", "未复核", "未知", ""],
  ["井道", "左侧墙体障碍物", "否", "文本", "", "", "", "照片 / 人工", "中", "未复核", "未知", ""],
  ["井道", "右侧墙体障碍物", "否", "文本", "", "", "", "照片 / 人工", "中", "未复核", "未知", ""],
  ["井道", "后墙障碍物", "否", "文本", "", "", "", "照片 / 人工", "中", "未复核", "未知", ""],
  ["底坑", "底坑深度", "是", "mm", "", "", "", "LiDAR / 人工", "中", "未复核", "未知", ""],
  ["底坑", "底坑净宽", "是", "mm", "", "", "", "LiDAR / 人工", "中", "未复核", "未知", ""],
  ["底坑", "底坑净深", "是", "mm", "", "", "", "LiDAR / 人工", "中", "未复核", "未知", ""],
  ["底坑", "积水 / 排水风险", "否", "文本", "", "", "", "照片 / 人工", "中", "未复核", "未知", ""],
  ["顶层", "顶层高度", "是", "mm", "", "", "", "LiDAR / 人工", "中", "未复核", "未知", ""],
  ["顶层", "顶层净空", "是", "mm", "", "", "", "LiDAR / 人工", "中", "未复核", "未知", ""],
  ["顶层", "梁 / 吊顶障碍", "否", "文本", "", "", "", "照片 / 人工", "中", "未复核", "未知", ""],
  ["门洞", "常规门洞宽度", "是", "mm", "", "", "", "LiDAR / 人工", "中", "未复核", "未知", ""],
  ["门洞", "常规门洞高度", "是", "mm", "", "", "", "LiDAR / 人工", "中", "未复核", "未知", ""],
  ["门洞", "门洞中心线偏移", "是", "mm", "", "", "", "LiDAR / 人工", "低", "未复核", "未知", ""],
  ["电气", "电源 / 控制箱空间", "否", "文本", "", "", "", "人工备注", "低", "未复核", "未知", ""],
  ["通道", "设备搬运通道", "否", "文本", "", "", "", "人工备注", "低", "未复核", "未知", ""],
  ["结构", "是否可能需要结构改造", "是", "是/否", "", "", "", "人工判断", "低", "未复核", "未知", ""],
  ["综合", "是否需要二次复尺", "否", "文本", "", "", "", "人工备注", "低", "未复核", "未知", ""],
]);
applyBorders(key, "A1:L21");
autofit(key, "A1:L21");

const doors = addSheet("层门洞口");
setValues(doors, "A1:I1", [[
  "楼层",
  "门洞宽度 (mm)",
  "门洞高度 (mm)",
  "地坎高度 (mm)",
  "中心线偏移 (mm)",
  "墙体厚度 (mm)",
  "障碍物",
  "最终状态",
  "备注",
]]);
applyHeader(doors, "A1:I1");
setValues(doors, "A2:I7", [
  ["1F", "", "", "", "", "", "", "未复核", ""],
  ["2F", "", "", "", "", "", "", "未复核", ""],
  ["3F", "", "", "", "", "", "", "未复核", ""],
  ["4F", "", "", "", "", "", "", "未复核", ""],
  ["5F", "", "", "", "", "", "", "未复核", ""],
  ["其他", "", "", "", "", "", "", "未复核", ""],
]);
applyBorders(doors, "A1:I7");
autofit(doors, "A1:I7");

const risks = addSheet("风险清单");
setValues(risks, "A1:H1", [[
  "风险类别",
  "风险项",
  "状态",
  "严重程度",
  "依据",
  "建议处理",
  "责任角色",
  "是否需跟进",
]]);
applyHeader(risks, "A1:H1");
setValues(risks, "A2:H11", [
  ["井道", "宽度不足", "未知", "中", "", "", "设计", "是"],
  ["井道", "深度不足", "未知", "中", "", "", "设计", "是"],
  ["底坑", "底坑深度不足", "未知", "高", "", "", "设计 / 安装", "是"],
  ["顶层", "顶层净空不足", "未知", "高", "", "", "设计 / 安装", "是"],
  ["井道", "井道垂直度异常", "未知", "中", "", "", "勘测 / 设计", "是"],
  ["结构", "梁或管线障碍", "未知", "中", "", "", "安装", "是"],
  ["门洞", "门洞位置或尺寸不一致", "未知", "中", "", "", "设计", "是"],
  ["结构", "可能需要结构改造", "未知", "高", "", "", "业主 / 土建", "是"],
  ["底坑", "积水或排水风险", "未知", "中", "", "", "安装", "是"],
  ["电气", "电源或控制箱空间问题", "未知", "低", "", "", "电气", "否"],
]);
applyBorders(risks, "A1:H11");
autofit(risks, "A1:H11");

const photos = addSheet("照片索引");
setValues(photos, "A1:F1", [["照片编号", "位置", "视角类型", "关联尺寸", "文件 / 链接", "备注"]]);
applyHeader(photos, "A1:F1");
setValues(photos, "A2:F9", [
  ["P001", "现场", "整体", "", "", ""],
  ["P002", "井道", "正面", "井道净宽 / 净深", "", ""],
  ["P003", "底坑", "俯视", "底坑深度", "", ""],
  ["P004", "顶层", "仰视", "顶层净空", "", ""],
  ["P005", "1F", "门洞", "门洞宽度 / 高度", "", ""],
  ["P006", "2F", "门洞", "门洞宽度 / 高度", "", ""],
  ["P007", "3F", "门洞", "门洞宽度 / 高度", "", ""],
  ["P008", "其他", "风险细节", "", "", ""],
]);
applyBorders(photos, "A1:F9");
autofit(photos, "A1:F9");

const summary = addSheet("报告汇总");
setValues(summary, "A1:D1", [["别墅梯旧房改造勘测汇总", "", "", ""]]);
applyTitle(summary, "A1:D1");
summary.getRange("A1:D1").merge();
setValues(summary, "A3:B9", [
  ["总体可行性", "待复核"],
  ["高风险数量", '=COUNTIFS(\'风险清单\'!C2:C11,"有风险",\'风险清单\'!D2:D11,"高")'],
  ["中风险数量", '=COUNTIFS(\'风险清单\'!C2:C11,"有风险",\'风险清单\'!D2:D11,"中")'],
  ["缺失的必填尺寸", '=SUMPRODUCT((\'关键尺寸\'!C2:C21="是")*(\'关键尺寸\'!G2:G21=""))'],
  ["待复核尺寸数量", '=COUNTIF(\'关键尺寸\'!J2:J21,"未复核")'],
  ["待复核门洞数量", '=COUNTIF(\'层门洞口\'!H2:H7,"未复核")'],
  ["建议下一步", ""],
]);
applySection(summary, "A3:A9");
applyBorders(summary, "A3:B9");
autofit(summary, "A1:D12");

await fs.mkdir(outputDir, { recursive: true });
const blob = await SpreadsheetFile.exportXlsx(workbook);
await blob.save(outputPath);
console.log(outputPath);
