const form = document.querySelector("#surveyForm");
const svg = document.querySelector("#planSvg");
const kpiGrid = document.querySelector("#kpiGrid");
const riskList = document.querySelector("#riskList");
const reportRows = document.querySelector("#reportRows");
const jsonOutput = document.querySelector("#jsonOutput");
const dimensionStrip = document.querySelector("#dimensionStrip");
const feasibilityBadge = document.querySelector("#feasibilityBadge");
const completionBadge = document.querySelector("#completionBadge");
const floorStrategy = document.querySelector("#floorStrategy");
const layerRows = document.querySelector("#layerRows");

const demoData = {
  projectName: "城南老别墅楼梯间改造",
  stops: 3,
  siteZone: "stair",
  stairWidth: 2180,
  stairDepth: 3820,
  keepPassage: 860,
  slabThickness: 180,
  hasLoadBearingWall: true,
  hasPipeRisk: true,
  shaftWidth: 1450,
  shaftDepth: 1520,
  margin: 120,
  overhead: 2780,
  pitDepth: 180,
  demoFloors: 2,
};

const mockLidarPayload = {
  source: "ARKit LiDAR mock",
  confidence: "中",
  measurements: {
    stairWidth: 2240,
    stairDepth: 3960,
    slabThickness: 170,
    shaftWidth: 1400,
    shaftDepth: 1500,
    overhead: 2920,
    pitDepth: 210,
  },
  detectedRisks: {
    hasLoadBearingWall: true,
    hasPipeRisk: true,
  },
  layers: [
    { slabAction: "局部开孔", stairAction: "局部拆除", beamAction: "需结构复核", pipeAction: "未知" },
    { slabAction: "局部开孔", stairAction: "拆除", beamAction: "避让保留", pipeAction: "需迁改" },
  ],
};

const rules = {
  minRetainedPassage: 800,
  minOverhead: 2800,
  minPitDepth: 250,
  structuralReviewDemoArea: 2.2,
  structuralReviewSlab: 150,
};

const floorDefaults = {
  slabAction: "局部开孔",
  stairAction: "拆除",
  beamAction: "需结构复核",
  pipeAction: "未知",
};

function createSelect(name, value, options) {
  return `
    <select name="${name}">
      ${options.map((option) => `<option value="${option}" ${option === value ? "selected" : ""}>${option}</option>`).join("")}
    </select>
  `;
}

function ensureFloorStrategy(stops) {
  const floorCount = Math.max(1, stops - 1);
  const existing = new Map(
    [...floorStrategy.querySelectorAll(".floor-card")].map((card) => [
      card.dataset.level,
      {
        slabAction: card.querySelector('[name$="_slabAction"]')?.value || floorDefaults.slabAction,
        stairAction: card.querySelector('[name$="_stairAction"]')?.value || floorDefaults.stairAction,
        beamAction: card.querySelector('[name$="_beamAction"]')?.value || floorDefaults.beamAction,
        pipeAction: card.querySelector('[name$="_pipeAction"]')?.value || floorDefaults.pipeAction,
      },
    ]),
  );

  const cards = [];
  for (let i = 1; i <= floorCount; i += 1) {
    const level = `${i}F-${i + 1}F`;
    const saved = existing.get(level) || floorDefaults;
    cards.push(`
      <div class="floor-card" data-level="${level}">
        <div class="floor-card-title">${level}<span>楼板 / 楼梯段</span></div>
        <div class="mini-grid">
          <label>楼板处理 ${createSelect(`floor_${i}_slabAction`, saved.slabAction, ["保留", "局部开孔", "拆除", "需复核"])}</label>
          <label>楼梯段处理 ${createSelect(`floor_${i}_stairAction`, saved.stairAction, ["保留", "局部拆除", "拆除", "需复核"])}</label>
          <label>梁 / 承重墙 ${createSelect(`floor_${i}_beamAction`, saved.beamAction, ["无影响", "避让保留", "需结构复核", "禁止拆除"])}</label>
          <label>管线 ${createSelect(`floor_${i}_pipeAction`, saved.pipeAction, ["无", "未知", "需迁改", "禁止破坏"])}</label>
        </div>
      </div>
    `);
  }
  floorStrategy.innerHTML = cards.join("");
}

function readForm() {
  const data = Object.fromEntries(new FormData(form).entries());
  for (const key of [
    "stops",
    "stairWidth",
    "stairDepth",
    "keepPassage",
    "slabThickness",
    "shaftWidth",
    "shaftDepth",
    "margin",
    "overhead",
    "pitDepth",
    "demoFloors",
  ]) {
    data[key] = Number(data[key] || 0);
  }
  data.hasLoadBearingWall = form.elements.hasLoadBearingWall.checked;
  data.hasPipeRisk = form.elements.hasPipeRisk.checked;
  data.layers = [];
  for (let i = 1; i <= Math.max(1, data.stops - 1); i += 1) {
    data.layers.push({
      level: `${i}F-${i + 1}F`,
      slabAction: form.elements[`floor_${i}_slabAction`]?.value || floorDefaults.slabAction,
      stairAction: form.elements[`floor_${i}_stairAction`]?.value || floorDefaults.stairAction,
      beamAction: form.elements[`floor_${i}_beamAction`]?.value || floorDefaults.beamAction,
      pipeAction: form.elements[`floor_${i}_pipeAction`]?.value || floorDefaults.pipeAction,
    });
  }
  return data;
}

function applyDemo() {
  for (const [key, value] of Object.entries(demoData)) {
    const field = form.elements[key];
    if (!field) continue;
    if (field.type === "checkbox") {
      field.checked = Boolean(value);
    } else {
      field.value = value;
    }
  }
  render();
}

function applyScanPayload(payload) {
  for (const [key, value] of Object.entries(payload.measurements || {})) {
    const field = form.elements[key];
    if (field) field.value = value;
  }
  for (const [key, value] of Object.entries(payload.detectedRisks || {})) {
    const field = form.elements[key];
    if (field && field.type === "checkbox") field.checked = Boolean(value);
  }

  ensureFloorStrategy(Number(form.elements.stops.value || 2));
  payload.layers?.forEach((layer, index) => {
    const i = index + 1;
    for (const [key, value] of Object.entries(layer)) {
      const field = form.elements[`floor_${i}_${key}`];
      if (field) field.value = value;
    }
  });

  render();
}

function calculate(data) {
  const requiredWidth = data.shaftWidth + data.margin * 2;
  const requiredDepth = data.shaftDepth + data.margin * 2;
  const demolitionWidth = Math.min(requiredWidth, data.stairWidth);
  const demolitionDepth = Math.min(requiredDepth, data.stairDepth);
  const demolitionArea = (demolitionWidth * demolitionDepth * data.demoFloors) / 1_000_000;
  const retainedWidth = data.stairWidth - requiredWidth;
  const retainedDepth = data.stairDepth - requiredDepth;
  const fitsWidth = retainedWidth >= data.keepPassage;
  const fitsDepth = retainedDepth >= 0;
  const fitsShaft = fitsWidth && fitsDepth;

  const risks = [];

  if (!fitsWidth) {
    risks.push({
      level: "high",
      item: "保留通行宽度不足",
      detail: `扣除井道和预留边后，剩余宽度为 ${retainedWidth} mm，低于目标 ${data.keepPassage} mm。需要调整井道位置、缩小规格或改造楼梯。`,
    });
  }

  if (!fitsDepth) {
    risks.push({
      level: "high",
      item: "楼梯洞口进深不足",
      detail: `井道进深加预留边需要 ${requiredDepth} mm，现有进深为 ${data.stairDepth} mm。需要复核是否可向相邻空间扩展。`,
    });
  }

  if (data.overhead < rules.minOverhead) {
    risks.push({
      level: "medium",
      item: "顶层净空偏低",
      detail: `当前顶层净空 ${data.overhead} mm，建议按目标电梯方案复核顶层布置和门机空间。`,
    });
  }

  if (data.pitDepth < rules.minPitDepth) {
    risks.push({
      level: "medium",
      item: "底坑深度偏低",
      detail: `当前底坑深度 ${data.pitDepth} mm，可能需要无底坑/浅底坑方案或局部降板。`,
    });
  }

  if (data.hasLoadBearingWall || data.slabThickness >= rules.structuralReviewSlab) {
    risks.push({
      level: "high",
      item: "结构复核必需",
      detail: "现场涉及承重墙、主梁或较厚楼板，拆除范围必须由结构人员复核，不能仅凭扫描结果判断可拆。",
    });
  }

  if (demolitionArea >= rules.structuralReviewDemoArea) {
    risks.push({
      level: "medium",
      item: "拆除面积较大",
      detail: `估算总拆除面积约 ${demolitionArea.toFixed(2)} m²，应拆分到各层记录，并标注临时支护和施工顺序。`,
    });
  }

  if (data.hasPipeRisk) {
    risks.push({
      level: "medium",
      item: "疑似管线穿越",
      detail: "建议增加水电定位照片，并在报告中标注需二次开孔探查或物业图纸复核。",
    });
  }

  const layerHigh = data.layers.filter(
    (layer) => layer.beamAction === "禁止拆除" || layer.pipeAction === "禁止破坏",
  );
  if (layerHigh.length) {
    risks.push({
      level: "high",
      item: "存在禁止破坏构件",
      detail: `${layerHigh.map((layer) => layer.level).join("、")} 标记了禁止拆除或禁止破坏，当前方案不能直接进入报价。`,
    });
  }

  const layerReview = data.layers.filter(
    (layer) =>
      layer.slabAction === "需复核" ||
      layer.stairAction === "需复核" ||
      layer.beamAction === "需结构复核" ||
      layer.pipeAction === "未知" ||
      layer.pipeAction === "需迁改",
  );
  if (layerReview.length) {
    risks.push({
      level: "medium",
      item: "分层处理项需复核",
      detail: `${layerReview.length} 个层间区间存在结构或管线待确认项，应在报告中分层列出并安排复尺。`,
    });
  }

  if (!risks.length) {
    risks.push({
      level: "low",
      item: "暂无明显高风险",
      detail: "当前数据满足初步布置条件，仍需现场复尺和结构复核后进入报价。",
    });
  }

  const highCount = risks.filter((risk) => risk.level === "high").length;
  const mediumCount = risks.filter((risk) => risk.level === "medium").length;
  const feasibility = highCount
    ? "需结构复核"
    : mediumCount
      ? "可行但需处理"
      : "初步可行";

  return {
    requiredWidth,
    requiredDepth,
    demolitionWidth,
    demolitionDepth,
    demolitionArea,
    retainedWidth,
    retainedDepth,
    fitsShaft,
    highCount,
    mediumCount,
    feasibility,
    risks,
  };
}

function layerConclusion(layer) {
  if (layer.beamAction === "禁止拆除" || layer.pipeAction === "禁止破坏") return "不可直接施工";
  if (layer.beamAction === "需结构复核" || layer.pipeAction === "未知" || layer.pipeAction === "需迁改") return "需复核";
  if (layer.slabAction === "保留" && layer.stairAction === "保留") return "保留为主";
  return "可作为初步拆改范围";
}

function renderPlan(data, result) {
  const pad = 70;
  const boxW = 520;
  const boxH = 340;
  const scale = Math.min(boxW / data.stairWidth, boxH / data.stairDepth);
  const stairW = data.stairWidth * scale;
  const stairH = data.stairDepth * scale;
  const x = (720 - stairW) / 2;
  const y = 68;
  const requiredW = result.requiredWidth * scale;
  const requiredH = result.requiredDepth * scale;
  const shaftW = data.shaftWidth * scale;
  const shaftH = data.shaftDepth * scale;
  const removeX = x;
  const removeY = y;
  const shaftX = removeX + data.margin * scale;
  const shaftY = removeY + data.margin * scale;
  const passageX = removeX + requiredW;
  const passageW = Math.max(0, stairW - requiredW);

  svg.innerHTML = `
    <defs>
      <pattern id="hatch" width="12" height="12" patternUnits="userSpaceOnUse" patternTransform="rotate(45)">
        <line x1="0" y1="0" x2="0" y2="12" stroke="#c84b3c" stroke-width="3"></line>
      </pattern>
    </defs>
    <rect x="${x}" y="${y}" width="${stairW}" height="${stairH}" rx="8" fill="#dce3ea" stroke="#8090a0" stroke-width="2"></rect>
    <rect x="${removeX}" y="${removeY}" width="${Math.min(requiredW, stairW)}" height="${Math.min(requiredH, stairH)}" rx="6" fill="#f8dfda" stroke="#c84b3c" stroke-width="2"></rect>
    <rect x="${removeX}" y="${removeY}" width="${Math.min(requiredW, stairW)}" height="${Math.min(requiredH, stairH)}" rx="6" fill="url(#hatch)" opacity="0.28"></rect>
    <rect x="${shaftX}" y="${shaftY}" width="${Math.min(shaftW, stairW)}" height="${Math.min(shaftH, stairH)}" rx="4" fill="#dff3e9" stroke="#16815f" stroke-width="3"></rect>
    <rect x="${passageX}" y="${y}" width="${passageW}" height="${stairH}" rx="4" fill="#e5f0f8" stroke="#1d5d8f" stroke-dasharray="8 7" stroke-width="2"></rect>
    <text x="${x}" y="${y - 22}" class="svg-label">现有楼梯洞口 ${data.stairWidth} x ${data.stairDepth} mm</text>
    <text x="${shaftX + 16}" y="${shaftY + 34}" class="svg-label">拟建井道</text>
    <text x="${shaftX + 16}" y="${shaftY + 58}" class="svg-small">${data.shaftWidth} x ${data.shaftDepth} mm</text>
    <text x="${removeX + 16}" y="${removeY + Math.min(requiredH, stairH) - 18}" class="svg-small">拆除楼板 / 楼梯段</text>
    <text x="${passageX + 14}" y="${y + 32}" class="svg-small">保留通行</text>
    <text x="${passageX + 14}" y="${y + 55}" class="svg-label">${Math.max(0, result.retainedWidth)} mm</text>
    <line x1="${x}" y1="${y + stairH + 34}" x2="${x + stairW}" y2="${y + stairH + 34}" stroke="#607080" stroke-width="2"></line>
    <text x="${x + stairW / 2 - 54}" y="${y + stairH + 62}" class="svg-small">宽度方向</text>
    <line x1="${x - 34}" y1="${y}" x2="${x - 34}" y2="${y + stairH}" stroke="#607080" stroke-width="2"></line>
    <text x="${pad - 28}" y="${y + stairH / 2}" class="svg-small" transform="rotate(-90 ${pad - 28},${y + stairH / 2})">进深方向</text>
  `;
}

function renderKpis(data, result) {
  const items = [
    ["拆除总面积", `${result.demolitionArea.toFixed(2)} m²`],
    ["保留通行宽度", `${Math.max(0, result.retainedWidth)} mm`],
    ["顶层净空", `${data.overhead} mm`],
    ["底坑深度", `${data.pitDepth} mm`],
  ];

  kpiGrid.innerHTML = items
    .map(([label, value]) => `<div class="kpi"><strong>${label}</strong><span>${value}</span></div>`)
    .join("");

  dimensionStrip.innerHTML = [
    ["井道需求", `${result.requiredWidth} x ${result.requiredDepth} mm`],
    ["拆除范围", `${result.demolitionWidth} x ${result.demolitionDepth} mm`],
    ["保留进深余量", `${Math.max(0, result.retainedDepth)} mm`],
  ]
    .map(([label, value]) => `<div><strong>${label}</strong><span>${value}</span></div>`)
    .join("");
}

function renderRisks(result) {
  riskList.innerHTML = result.risks
    .map(
      (risk) => `
        <li class="${risk.level}">
          <div class="risk-title">
            <span>${risk.item}</span>
            <span>${risk.level === "high" ? "高" : risk.level === "medium" ? "中" : "低"}</span>
          </div>
          <p>${risk.detail}</p>
        </li>
      `,
    )
    .join("");
}

function renderLayers(data) {
  layerRows.innerHTML = data.layers
    .map(
      (layer) => `
        <tr>
          <td>${layer.level}</td>
          <td>${layer.slabAction}</td>
          <td>${layer.stairAction}</td>
          <td>${layer.beamAction}</td>
          <td>${layer.pipeAction}</td>
          <td>${layerConclusion(layer)}</td>
        </tr>
      `,
    )
    .join("");
}

function buildReportRows(data, result) {
  return [
    ["项目名称", data.projectName, "草稿"],
    ["楼层 / 站数", `${data.stops} 站`, "待复核"],
    ["施工位置", zoneLabel(data.siteZone), "待复核"],
    ["井道净尺寸", `${data.shaftWidth} x ${data.shaftDepth} mm`, result.fitsShaft ? "可布置" : "需调整"],
    ["建议拆除范围", `${result.demolitionWidth} x ${result.demolitionDepth} mm`, "需结构确认"],
    ["估算拆除面积", `${result.demolitionArea.toFixed(2)} m²`, result.demolitionArea > 0 ? "待复核" : "无"],
    ["保留通行宽度", `${Math.max(0, result.retainedWidth)} mm`, result.retainedWidth >= data.keepPassage ? "满足" : "不足"],
    ["顶层净空", `${data.overhead} mm`, data.overhead >= rules.minOverhead ? "满足初判" : "偏低"],
    ["底坑深度", `${data.pitDepth} mm`, data.pitDepth >= rules.minPitDepth ? "满足初判" : "偏低"],
    ["风险汇总", `高 ${result.highCount} / 中 ${result.mediumCount}`, result.feasibility],
  ];
}

function renderReport(data, result) {
  const rows = buildReportRows(data, result);
  reportRows.innerHTML = rows
    .map(([name, value, status]) => `<tr><td>${name}</td><td>${value}</td><td>${status}</td></tr>`)
    .join("");

  const report = {
    项目名称: data.projectName,
    场景: "别墅梯旧房改造",
    施工位置: zoneLabel(data.siteZone),
    输入数据: data,
    计算结果: {
      所需宽度mm: result.requiredWidth,
      所需进深mm: result.requiredDepth,
      估算拆除面积m2: Number(result.demolitionArea.toFixed(2)),
      保留通行宽度mm: result.retainedWidth,
      保留进深余量mm: result.retainedDepth,
      总体判断: result.feasibility,
    },
    风险清单: result.risks.map((risk) => ({
      风险等级: risk.level === "high" ? "高" : risk.level === "medium" ? "中" : "低",
      风险项: risk.item,
      建议: risk.detail,
    })),
    分层拆除保留记录: data.layers.map((layer) => ({
      区间: layer.level,
      楼板处理: layer.slabAction,
      楼梯段处理: layer.stairAction,
      梁或承重墙: layer.beamAction,
      管线: layer.pipeAction,
      结论: layerConclusion(layer),
    })),
  };

  jsonOutput.textContent = JSON.stringify(report, null, 2);
}

function zoneLabel(zone) {
  return {
    stair: "现有楼梯区域",
    atrium: "中空区域",
    external: "外接井道",
  }[zone];
}

function renderBadges(result) {
  feasibilityBadge.textContent = result.feasibility;
  feasibilityBadge.style.background = result.highCount ? "var(--soft-red)" : result.mediumCount ? "var(--soft-amber)" : "var(--soft-green)";
  feasibilityBadge.style.color = result.highCount ? "var(--red)" : result.mediumCount ? "var(--amber)" : "var(--green)";
  completionBadge.textContent = "字段完整";
  completionBadge.style.background = "var(--soft-green)";
  completionBadge.style.color = "var(--green)";
}

function render() {
  ensureFloorStrategy(Number(form.elements.stops.value || 2));
  const data = readForm();
  const result = calculate(data);
  renderPlan(data, result);
  renderKpis(data, result);
  renderRisks(result);
  renderLayers(data);
  renderReport(data, result);
  renderBadges(result);
}

form.addEventListener("input", render);
floorStrategy.addEventListener("change", render);
document.querySelector("#loadDemo").addEventListener("click", applyDemo);
document.querySelector("#mockScan").addEventListener("click", () => applyScanPayload(mockLidarPayload));
document.querySelector("#printReport").addEventListener("click", () => window.print());

window.applyScanPayload = applyScanPayload;

render();
