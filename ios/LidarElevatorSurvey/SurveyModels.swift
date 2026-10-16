import Foundation
import simd

enum MeasurementConfidence: String, Codable, CaseIterable {
    case high = "高"
    case medium = "中"
    case low = "低"
}

enum ReviewStatus: String, Codable, CaseIterable {
    case unreviewed = "未复核"
    case checked = "已检查"
    case confirmed = "已确认"
}

struct SurveyMeasurement: Identifiable, Codable {
    let id: UUID
    var category: String
    var name: String
    var unit: String
    var scannedValue: Double?
    var modelValue: Double?
    var manualValue: Double?
    var finalValue: Double?
    var source: String
    var confidence: MeasurementConfidence
    var reviewStatus: ReviewStatus
    var notes: String
    var evidencePhotoNames: [String]?

    init(
        id: UUID = UUID(),
        category: String,
        name: String,
        unit: String = "mm",
        scannedValue: Double? = nil,
        modelValue: Double? = nil,
        manualValue: Double? = nil,
        finalValue: Double? = nil,
        source: String = "LiDAR 扫描",
        confidence: MeasurementConfidence = .medium,
        reviewStatus: ReviewStatus = .unreviewed,
        notes: String = "",
        evidencePhotoNames: [String]? = nil
    ) {
        self.id = id
        self.category = category
        self.name = name
        self.unit = unit
        self.scannedValue = scannedValue
        self.modelValue = modelValue
        self.manualValue = manualValue
        self.finalValue = finalValue
        self.source = source
        self.confidence = confidence
        self.reviewStatus = reviewStatus
        self.notes = notes
        self.evidencePhotoNames = evidencePhotoNames
    }
}

struct LayerDemolitionRecord: Identifiable, Codable {
    let id: UUID
    var level: String
    var slabAction: String
    var stairAction: String
    var beamAction: String
    var pipeAction: String

    init(
        id: UUID = UUID(),
        level: String,
        slabAction: String = "局部开孔",
        stairAction: String = "拆除",
        beamAction: String = "需结构复核",
        pipeAction: String = "未知"
    ) {
        self.id = id
        self.level = level
        self.slabAction = slabAction
        self.stairAction = stairAction
        self.beamAction = beamAction
        self.pipeAction = pipeAction
    }

    var conclusion: String {
        if beamAction == "禁止拆除" || pipeAction == "禁止破坏" {
            return "不可直接施工"
        }
        if beamAction == "需结构复核" || pipeAction == "未知" || pipeAction == "需迁改" {
            return "需复核"
        }
        if slabAction == "保留" && stairAction == "保留" {
            return "保留为主"
        }
        return "可作为初步拆改范围"
    }
}

struct RiskItem: Identifiable {
    let id = UUID()
    var level: String
    var title: String
    var detail: String
}

struct ModelScanLayer: Identifiable, Codable {
    let id: UUID
    var name: String
    var scanStatus: ReviewStatus
    var wallCount: Int
    var openingCount: Int
    var objectCount: Int
    var estimatedWidth: Double?
    var estimatedDepth: Double?
    var estimatedHeight: Double?
    var modelFileName: String?
    var metadataFileName: String?
    var features: [ModelScanFeature]
    var scannedAt: Date?
    var notes: String

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case scanStatus
        case wallCount
        case openingCount
        case objectCount
        case estimatedWidth
        case estimatedDepth
        case estimatedHeight
        case modelFileName
        case metadataFileName
        case features
        case scannedAt
        case notes
    }

    init(
        id: UUID = UUID(),
        name: String,
        scanStatus: ReviewStatus = .unreviewed,
        wallCount: Int = 0,
        openingCount: Int = 0,
        objectCount: Int = 0,
        estimatedWidth: Double? = nil,
        estimatedDepth: Double? = nil,
        estimatedHeight: Double? = nil,
        modelFileName: String? = nil,
        metadataFileName: String? = nil,
        features: [ModelScanFeature] = [],
        scannedAt: Date? = nil,
        notes: String = ""
    ) {
        self.id = id
        self.name = name
        self.scanStatus = scanStatus
        self.wallCount = wallCount
        self.openingCount = openingCount
        self.objectCount = objectCount
        self.estimatedWidth = estimatedWidth
        self.estimatedDepth = estimatedDepth
        self.estimatedHeight = estimatedHeight
        self.modelFileName = modelFileName
        self.metadataFileName = metadataFileName
        self.features = features
        self.scannedAt = scannedAt
        self.notes = notes
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? "空间扫描"
        scanStatus = try container.decodeIfPresent(ReviewStatus.self, forKey: .scanStatus) ?? .unreviewed
        wallCount = try container.decodeIfPresent(Int.self, forKey: .wallCount) ?? 0
        openingCount = try container.decodeIfPresent(Int.self, forKey: .openingCount) ?? 0
        objectCount = try container.decodeIfPresent(Int.self, forKey: .objectCount) ?? 0
        estimatedWidth = try container.decodeIfPresent(Double.self, forKey: .estimatedWidth)
        estimatedDepth = try container.decodeIfPresent(Double.self, forKey: .estimatedDepth)
        estimatedHeight = try container.decodeIfPresent(Double.self, forKey: .estimatedHeight)
        modelFileName = try container.decodeIfPresent(String.self, forKey: .modelFileName)
        metadataFileName = try container.decodeIfPresent(String.self, forKey: .metadataFileName)
        features = try container.decodeIfPresent([ModelScanFeature].self, forKey: .features) ?? []
        scannedAt = try container.decodeIfPresent(Date.self, forKey: .scannedAt)
        notes = try container.decodeIfPresent(String.self, forKey: .notes) ?? ""
    }
}

struct ModelScanFeature: Identifiable, Codable, Hashable {
    let id: UUID
    var sourceId: UUID
    var category: String
    var label: String
    var width: Double?
    var depth: Double?
    var height: Double?
    var confidence: String

    init(
        id: UUID = UUID(),
        sourceId: UUID,
        category: String,
        label: String,
        width: Double? = nil,
        depth: Double? = nil,
        height: Double? = nil,
        confidence: String
    ) {
        self.id = id
        self.sourceId = sourceId
        self.category = category
        self.label = label
        self.width = width
        self.depth = depth
        self.height = height
        self.confidence = confidence
    }
}

struct SurveyProject: Identifiable, Codable {
    var id = UUID()
    var name = "别墅梯旧房改造"
    var createdAt = Date()
    var stops = 2
    var stairWidth: Double = 2240
    var stairDepth: Double = 3960
    var shaftWidth: Double = 1400
    var shaftDepth: Double = 1500
    var safetyMargin: Double = 120
    var overhead: Double = 2920
    var pitDepth: Double = 210
    var keepPassage: Double = 860
    var hasLoadBearingWall = true
    var hasPipeRisk = true
    var isArchived = false
    var measurements: [SurveyMeasurement] = SurveyProject.defaultMeasurements()
    var modelScanLayers: [ModelScanLayer] = SurveyProject.defaultModelScanLayers(stops: 2)
    var layers: [LayerDemolitionRecord] = [
        LayerDemolitionRecord(level: "1F-2F")
    ]

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case createdAt
        case stops
        case stairWidth
        case stairDepth
        case shaftWidth
        case shaftDepth
        case safetyMargin
        case overhead
        case pitDepth
        case keepPassage
        case hasLoadBearingWall
        case hasPipeRisk
        case isArchived
        case measurements
        case modelScanLayers
        case layers
    }

    init() {}

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? "别墅梯旧房改造"
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        stops = try container.decodeIfPresent(Int.self, forKey: .stops) ?? 2
        stairWidth = try container.decodeIfPresent(Double.self, forKey: .stairWidth) ?? 2240
        stairDepth = try container.decodeIfPresent(Double.self, forKey: .stairDepth) ?? 3960
        shaftWidth = try container.decodeIfPresent(Double.self, forKey: .shaftWidth) ?? 1400
        shaftDepth = try container.decodeIfPresent(Double.self, forKey: .shaftDepth) ?? 1500
        safetyMargin = try container.decodeIfPresent(Double.self, forKey: .safetyMargin) ?? 120
        overhead = try container.decodeIfPresent(Double.self, forKey: .overhead) ?? 2920
        pitDepth = try container.decodeIfPresent(Double.self, forKey: .pitDepth) ?? 210
        keepPassage = try container.decodeIfPresent(Double.self, forKey: .keepPassage) ?? 860
        hasLoadBearingWall = try container.decodeIfPresent(Bool.self, forKey: .hasLoadBearingWall) ?? true
        hasPipeRisk = try container.decodeIfPresent(Bool.self, forKey: .hasPipeRisk) ?? true
        isArchived = try container.decodeIfPresent(Bool.self, forKey: .isArchived) ?? false
        measurements = try container.decodeIfPresent([SurveyMeasurement].self, forKey: .measurements) ?? SurveyProject.defaultMeasurements()
        modelScanLayers = try container.decodeIfPresent([ModelScanLayer].self, forKey: .modelScanLayers) ?? SurveyProject.defaultModelScanLayers(stops: stops)
        layers = try container.decodeIfPresent([LayerDemolitionRecord].self, forKey: .layers) ?? [
            LayerDemolitionRecord(level: "1F-2F")
        ]
    }

    static func defaultMeasurements() -> [SurveyMeasurement] {
        [
            SurveyMeasurement(category: "改造预留", name: "现有楼梯洞口宽度", notes: "旧别墅梯改造补充项，用于拆除/保留示意"),
            SurveyMeasurement(category: "改造预留", name: "现有楼梯洞口进深", notes: "旧别墅梯改造补充项，用于拆除/保留示意"),
            SurveyMeasurement(category: "井道", name: "井道宽度"),
            SurveyMeasurement(category: "井道", name: "井道深度"),
            SurveyMeasurement(category: "前层门", name: "前层门入口净宽"),
            SurveyMeasurement(category: "前层门", name: "前层门入口净高"),
            SurveyMeasurement(category: "前层门", name: "前层门头梁宽"),
            SurveyMeasurement(category: "后层门", name: "后层门入口净宽"),
            SurveyMeasurement(category: "后层门", name: "后层门入口净高"),
            SurveyMeasurement(category: "后层门", name: "后层门头梁宽"),
            SurveyMeasurement(category: "门洞", name: "门洞宽度"),
            SurveyMeasurement(category: "门洞", name: "门洞高度"),
            SurveyMeasurement(category: "门洞", name: "左门垛"),
            SurveyMeasurement(category: "门洞", name: "右门垛"),
            SurveyMeasurement(category: "层站", name: "层站高度"),
            SurveyMeasurement(category: "圈梁", name: "导轨圈梁间距"),
            SurveyMeasurement(category: "圈梁", name: "导轨圈梁高度"),
            SurveyMeasurement(category: "圈梁", name: "顶层圈梁离顶层地面高度"),
            SurveyMeasurement(category: "顶层", name: "顶层高度"),
            SurveyMeasurement(category: "底坑", name: "底坑深度"),
            SurveyMeasurement(category: "底坑", name: "起台高度"),
            SurveyMeasurement(category: "井道", name: "提升高度"),
            SurveyMeasurement(category: "控制柜", name: "控制柜孔洞宽度"),
            SurveyMeasurement(category: "控制柜", name: "控制柜孔洞高度")
        ]
    }

    static func defaultModelScanLayers(stops: Int) -> [ModelScanLayer] {
        (1...max(2, stops)).map { ModelScanLayer(name: "\($0)F 空间扫描") }
    }
}

struct ScanMeasurementPayload {
    var source: String
    var confidence: MeasurementConfidence
    var stairWidth: Double?
    var stairDepth: Double?
    var shaftWidth: Double?
    var shaftDepth: Double?
    var overhead: Double?
    var pitDepth: Double?
}

final class SurveyStore: ObservableObject {
    private let projectsStorageKey = "LidarElevatorSurvey.projects.v1"

    @Published var project = SurveyProject()
    @Published var projects: [SurveyProject] = [] {
        didSet {
            persistProjects()
        }
    }
    @Published var hasActiveProject = false
    @Published var latestDistanceMillimeters: Double?
    @Published var scanStatus = "等待扫描"
    @Published var selectedMeasurementName = "井道宽度"
    @Published var importRevision = 0
    @Published var meshAnchorCount = 0
    @Published var planeAnchorCount = 0
    @Published var horizontalCalibrationStatus = "水平校准中"
    @Published var modelEstimateStatus = "尚未形成模型估算"
    @Published var currentMeasurementIndex = 0
    @Published var scanWorkflowMode = "逐项测量"
    @Published var hasModelScan = false
    @Published var isMeasuringCurrentItem = false
    @Published var currentMeasurementPendingCompletion = false
    @Published var selectedPointCount = 0
    @Published var selectedModelScanLayerId: UUID?
    @Published var selectedModelFeatureId: UUID?
    @Published var selectedModelMappingMeasurementName = "现有楼梯洞口宽度"
    @Published var isRoomPlanScannerPresented = false
    @Published var visualResetRevision = 0
    @Published var visualResetMeasurementName: String?
    @Published var photoCaptureRevision = 0
    @Published var latestMeasurementPhotoName: String?

    var measurementNames: [String] {
        project.measurements.map(\.name)
    }

    var groupedMeasurementNames: [(category: String, names: [String])] {
        var grouped: [(category: String, names: [String])] = []
        for item in project.measurements {
            if let index = grouped.firstIndex(where: { $0.category == item.category }) {
                grouped[index].names.append(item.name)
            } else {
                grouped.append((item.category, [item.name]))
            }
        }
        return grouped
    }

    var currentPrompt: String {
        guard !measurementNames.isEmpty else { return "暂无测量项" }
        let name = measurementNames[min(currentMeasurementIndex, measurementNames.count - 1)]
        return "请测量：\(name)"
    }

    var workflowProgressText: String {
        guard !measurementNames.isEmpty else { return "0/0" }
        return "\(min(currentMeasurementIndex + 1, measurementNames.count))/\(measurementNames.count)"
    }

    var completedMeasurementCount: Int {
        project.measurements.filter { $0.finalValue != nil }.count
    }

    var activeProjects: [SurveyProject] {
        projects.filter { !$0.isArchived }
    }

    var archivedProjects: [SurveyProject] {
        projects.filter(\.isArchived)
    }

    var selectedModelScanLayer: ModelScanLayer? {
        guard let selectedModelScanLayerId else { return project.modelScanLayers.first }
        return project.modelScanLayers.first { $0.id == selectedModelScanLayerId } ?? project.modelScanLayers.first
    }

    var completedModelScanLayerCount: Int {
        project.modelScanLayers.filter { $0.scanStatus != .unreviewed }.count
    }

    var selectedModelFeature: ModelScanFeature? {
        guard let selectedModelFeatureId else { return selectedModelScanLayer?.features.first }
        return selectedModelScanLayer?.features.first { $0.id == selectedModelFeatureId } ?? selectedModelScanLayer?.features.first
    }

    var aggregateModelSummary: (wallCount: Int, openingCount: Int, objectCount: Int, estimatedWidth: Double?, estimatedDepth: Double?, estimatedHeight: Double?) {
        let scannedLayers = project.modelScanLayers.filter { $0.scanStatus != .unreviewed }
        return (
            scannedLayers.reduce(0) { $0 + $1.wallCount },
            scannedLayers.reduce(0) { $0 + $1.openingCount },
            scannedLayers.reduce(0) { $0 + $1.objectCount },
            scannedLayers.compactMap(\.estimatedWidth).max(),
            scannedLayers.compactMap(\.estimatedDepth).max(),
            scannedLayers.compactMap(\.estimatedHeight).max()
        )
    }

    var canGoNext: Bool {
        currentMeasurementIndex < measurementNames.count - 1
    }

    var canGoPrevious: Bool {
        currentMeasurementIndex > 0
    }

    init() {
        loadProjects()
    }

    var requiredWidth: Double {
        project.shaftWidth + project.safetyMargin * 2
    }

    var requiredDepth: Double {
        project.shaftDepth + project.safetyMargin * 2
    }

    var retainedWidth: Double {
        project.stairWidth - requiredWidth
    }

    var retainedDepth: Double {
        project.stairDepth - requiredDepth
    }

    var demolitionArea: Double {
        let floors = max(1, project.stops - 1)
        return requiredWidth * requiredDepth * Double(floors) / 1_000_000
    }

    var risks: [RiskItem] {
        var items: [RiskItem] = []
        if retainedWidth < project.keepPassage {
            items.append(RiskItem(level: "高", title: "保留通行宽度不足", detail: "剩余宽度 \(Int(retainedWidth)) mm，低于目标 \(Int(project.keepPassage)) mm。"))
        }
        if retainedDepth < 0 {
            items.append(RiskItem(level: "高", title: "楼梯洞口进深不足", detail: "井道进深加预留边需要 \(Int(requiredDepth)) mm，现有进深 \(Int(project.stairDepth)) mm。"))
        }
        if project.hasLoadBearingWall {
            items.append(RiskItem(level: "高", title: "结构复核必需", detail: "涉及承重墙或主梁，拆除范围必须由结构人员复核。"))
        }
        if project.hasPipeRisk {
            items.append(RiskItem(level: "中", title: "疑似管线穿越", detail: "需要水电定位照片、物业图纸或开孔探查。"))
        }
        if project.pitDepth < 250 {
            items.append(RiskItem(level: "中", title: "底坑深度偏低", detail: "当前底坑 \(Int(project.pitDepth)) mm，可能需要浅底坑方案。"))
        }
        for layer in project.layers where layer.conclusion == "不可直接施工" || layer.conclusion == "需复核" {
            items.append(RiskItem(level: layer.conclusion == "不可直接施工" ? "高" : "中", title: "\(layer.level) 分层处理需确认", detail: "楼板：\(layer.slabAction)，楼梯段：\(layer.stairAction)，梁/承重墙：\(layer.beamAction)，管线：\(layer.pipeAction)。"))
        }
        return items
    }

    func apply(payload: ScanMeasurementPayload) {
        scanStatus = "已导入 \(payload.source)"
        importRevision += 1
        if let stairWidth = payload.stairWidth { project.stairWidth = stairWidth }
        if let stairDepth = payload.stairDepth { project.stairDepth = stairDepth }
        if let shaftWidth = payload.shaftWidth { project.shaftWidth = shaftWidth }
        if let shaftDepth = payload.shaftDepth { project.shaftDepth = shaftDepth }
        if let overhead = payload.overhead { project.overhead = overhead }
        if let pitDepth = payload.pitDepth { project.pitDepth = pitDepth }
        updateMeasurement(named: "现有楼梯洞口宽度", value: payload.stairWidth, payload: payload)
        updateMeasurement(named: "现有楼梯洞口进深", value: payload.stairDepth, payload: payload)
        updateMeasurement(named: "楼梯洞口宽度", value: payload.stairWidth, payload: payload)
        updateMeasurement(named: "楼梯洞口进深", value: payload.stairDepth, payload: payload)
        updateMeasurement(named: "井道宽度", value: payload.shaftWidth, payload: payload)
        updateMeasurement(named: "井道深度", value: payload.shaftDepth, payload: payload)
        updateMeasurement(named: "井道净宽", value: payload.shaftWidth, payload: payload)
        updateMeasurement(named: "井道净深", value: payload.shaftDepth, payload: payload)
        updateMeasurement(named: "底坑深度", value: payload.pitDepth, payload: payload)
        updateMeasurement(named: "顶层高度", value: payload.overhead, payload: payload)
        updateMeasurement(named: "顶层净空", value: payload.overhead, payload: payload)
        saveActiveProject()
    }

    func updatePointDistance(_ meters: Float) {
        guard isMeasuringCurrentItem else {
            scanStatus = "请先点击“开始测量该项”"
            selectedPointCount = 0
            return
        }
        let millimeters = Double(meters * 1000)
        latestDistanceMillimeters = millimeters
        writeMeasurement(named: selectedMeasurementName, value: millimeters, source: "点选 LiDAR 测距", confidence: .medium)
        isMeasuringCurrentItem = false
        currentMeasurementPendingCompletion = true
        selectedPointCount = 0
        scanStatus = "\(selectedMeasurementName) 测量成功：\(Int(millimeters)) mm。请完成或重新测量。"
        saveActiveProject()
    }

    func startCurrentMeasurement() {
        isMeasuringCurrentItem = true
        currentMeasurementPendingCompletion = false
        selectedPointCount = 0
        latestMeasurementPhotoName = nil
        selectedMeasurementName = measurementNames[currentMeasurementIndex]
        scanStatus = "正在测量 \(selectedMeasurementName)：请按指引点选第 1 个点"
    }

    func redoCurrentMeasurement() {
        latestDistanceMillimeters = nil
        latestMeasurementPhotoName = nil
        currentMeasurementPendingCompletion = false
        isMeasuringCurrentItem = true
        selectedPointCount = 0
        clearMeasurementValue(named: selectedMeasurementName)
        visualResetMeasurementName = selectedMeasurementName
        visualResetRevision += 1
        scanStatus = "重新测量 \(selectedMeasurementName)：请按指引点选第 1 个点"
    }

    func completeCurrentMeasurement() {
        guard currentMeasurementPendingCompletion else {
            scanStatus = "请先完成当前项测量"
            return
        }
        if let index = project.measurements.firstIndex(where: { $0.name == selectedMeasurementName }) {
            project.measurements[index].reviewStatus = .checked
        }
        isMeasuringCurrentItem = false
        currentMeasurementPendingCompletion = false
        selectedPointCount = 0
        if canGoNext {
            currentMeasurementIndex += 1
            selectedMeasurementName = measurementNames[currentMeasurementIndex]
            latestMeasurementPhotoName = nil
            scanStatus = "已完成，下一项：\(selectedMeasurementName)"
        } else {
            scanStatus = "逐项测量完成，请进行空间建模"
            scanWorkflowMode = "空间建模"
        }
        saveActiveProject()
    }

    func requestCurrentMeasurementPhoto() {
        guard currentMeasurementPendingCompletion else {
            scanStatus = "请先完成当前项测量后再拍照保存"
            return
        }
        scanStatus = "正在保存 \(selectedMeasurementName) 的测量照片"
        photoCaptureRevision += 1
    }

    func applyMeasurementPhoto(fileName: String, measurementName: String) {
        guard let index = project.measurements.firstIndex(where: { $0.name == measurementName }) else { return }
        var photos = project.measurements[index].evidencePhotoNames ?? []
        if !photos.contains(fileName) {
            photos.append(fileName)
        }
        project.measurements[index].evidencePhotoNames = photos
        latestMeasurementPhotoName = fileName
        scanStatus = "已保存 \(measurementName) 测量照片"
        saveActiveProject()
    }

    func measurementPhotoURL(fileName: String) -> URL {
        Self.measurementPhotoDirectory().appendingPathComponent(fileName)
    }

    func updateSelectedPointCount(_ count: Int) {
        selectedPointCount = count
        if isMeasuringCurrentItem {
            if count == 0 {
                scanStatus = "正在测量 \(selectedMeasurementName)：请按指引点选第 1 个点"
            } else if count == 1 {
                scanStatus = "已选择第 1 个点，请点选第 2 个点"
            }
        }
    }

    func enterManualMeasurement() {
        scanWorkflowMode = "逐项测量"
        isMeasuringCurrentItem = false
        currentMeasurementPendingCompletion = false
        selectedPointCount = 0
        scanStatus = "请先手动逐项测量：\(selectedMeasurementName)"
    }

    func enterModelScan() {
        scanWorkflowMode = "空间建模"
        isMeasuringCurrentItem = false
        currentMeasurementPendingCompletion = false
        selectedPointCount = 0
        scanStatus = "请点击“开始 RoomPlan 空间扫描”"
    }

    func enterCalibration() {
        scanWorkflowMode = "逐项校准"
        isMeasuringCurrentItem = false
        currentMeasurementPendingCompletion = false
        selectedPointCount = 0
        currentMeasurementIndex = firstPendingMeasurementIndex()
        selectedMeasurementName = measurementNames.isEmpty ? "井道宽度" : measurementNames[currentMeasurementIndex]
        scanStatus = "请对照模型校准：\(selectedMeasurementName)"
    }

    func updateTracking(meshAnchors: Int, planeAnchors: Int, horizontalCalibrated: Bool) {
        meshAnchorCount = meshAnchors
        planeAnchorCount = planeAnchors
        horizontalCalibrationStatus = horizontalCalibrated ? "水平面已校准" : "水平校准中"
    }

    func applyModelEstimate(width: Double?, depth: Double?, height: Double?, source: String) {
        guard scanWorkflowMode == "空间建模" else {
            return
        }

        var applied: [String] = []
        if let width {
            updateModelEstimate(named: "现有楼梯洞口宽度", value: width, source: source)
            applied.append("宽 \(Int(width)) mm")
        }
        if let depth {
            updateModelEstimate(named: "现有楼梯洞口进深", value: depth, source: source)
            applied.append("深 \(Int(depth)) mm")
        }
        if let height {
            updateModelEstimate(named: "顶层高度", value: height, source: source)
            applied.append("高 \(Int(height)) mm")
        }
        if applied.isEmpty {
            modelEstimateStatus = "模型估算不足，请继续扫描墙面、地面和顶面"
        } else {
            modelEstimateStatus = "模型估算：" + applied.joined(separator: " / ")
            scanStatus = "已生成模型估算，可进入逐项校准"
            hasModelScan = true
        }
        saveActiveProject()
    }

    func startNewProject(name: String, stops: Int) {
        var newProject = SurveyProject()
        newProject.id = UUID()
        newProject.name = name.isEmpty ? "未命名别墅梯项目" : name
        newProject.createdAt = Date()
        newProject.stops = max(2, stops)
        newProject.layers = (1..<max(2, stops)).map { LayerDemolitionRecord(level: "\($0)F-\($0 + 1)F") }
        newProject.modelScanLayers = SurveyProject.defaultModelScanLayers(stops: newProject.stops)
        newProject.measurements = SurveyProject.defaultMeasurements()
        project = newProject
        hasActiveProject = true
        currentMeasurementIndex = 0
        selectedMeasurementName = measurementNames.first ?? "井道宽度"
        selectedModelMappingMeasurementName = measurementNames.first ?? "现有楼梯洞口宽度"
        latestDistanceMillimeters = nil
        importRevision = 0
        meshAnchorCount = 0
        planeAnchorCount = 0
        selectedModelScanLayerId = project.modelScanLayers.first?.id
        selectedModelFeatureId = project.modelScanLayers.first?.features.first?.id
        hasModelScan = false
        isMeasuringCurrentItem = false
        currentMeasurementPendingCompletion = false
        selectedPointCount = 0
        scanWorkflowMode = "逐项测量"
        scanStatus = "新项目已创建，\(currentPrompt)"
        saveActiveProject()
    }

    func openProject(_ existingProject: SurveyProject) {
        project = existingProject
        mergeDefaultMeasurementsIfNeeded()
        if project.modelScanLayers.isEmpty {
            project.modelScanLayers = SurveyProject.defaultModelScanLayers(stops: project.stops)
        }
        hasActiveProject = true
        selectedModelScanLayerId = project.modelScanLayers.first?.id
        selectedModelFeatureId = selectedModelScanLayer?.features.first?.id
        currentMeasurementIndex = firstPendingMeasurementIndex()
        selectedMeasurementName = measurementNames.isEmpty ? "井道宽度" : measurementNames[currentMeasurementIndex]
        selectedModelMappingMeasurementName = measurementNames.first ?? "现有楼梯洞口宽度"
        latestDistanceMillimeters = nil
        isMeasuringCurrentItem = false
        currentMeasurementPendingCompletion = false
        selectedPointCount = 0
        scanWorkflowMode = "逐项测量"
        scanStatus = "已打开项目，\(currentPrompt)"
    }

    func closeProject() {
        saveActiveProject()
        hasActiveProject = false
    }

    func archiveProject(_ project: SurveyProject) {
        updateProject(project.id) { item in
            item.isArchived = true
        }
        scanStatus = "已归档 \(project.name)"
    }

    func restoreProject(_ project: SurveyProject) {
        updateProject(project.id) { item in
            item.isArchived = false
        }
        scanStatus = "已恢复 \(project.name)"
    }

    func deleteProject(_ project: SurveyProject) {
        projects.removeAll { $0.id == project.id }
        if self.project.id == project.id {
            hasActiveProject = false
        }
        scanStatus = "已删除 \(project.name)"
    }

    private func updateProject(_ id: UUID, mutate: (inout SurveyProject) -> Void) {
        guard let index = projects.firstIndex(where: { $0.id == id }) else { return }
        mutate(&projects[index])
        if project.id == id {
            project = projects[index]
        }
    }

    func saveActiveProject() {
        guard hasActiveProject else { return }
        if let index = projects.firstIndex(where: { $0.id == project.id }) {
            projects[index] = project
        } else {
            projects.insert(project, at: 0)
        }
    }

    func goToMeasurement(named name: String) {
        guard let index = measurementNames.firstIndex(of: name) else { return }
        currentMeasurementIndex = index
        selectedMeasurementName = name
        isMeasuringCurrentItem = false
        currentMeasurementPendingCompletion = false
        selectedPointCount = 0
        scanStatus = currentPrompt
    }

    func goNextMeasurement() {
        guard canGoNext else { return }
        currentMeasurementIndex += 1
        selectedMeasurementName = measurementNames[currentMeasurementIndex]
        isMeasuringCurrentItem = false
        currentMeasurementPendingCompletion = false
        selectedPointCount = 0
        scanStatus = currentPrompt
    }

    func goPreviousMeasurement() {
        guard canGoPrevious else { return }
        currentMeasurementIndex -= 1
        selectedMeasurementName = measurementNames[currentMeasurementIndex]
        isMeasuringCurrentItem = false
        currentMeasurementPendingCompletion = false
        selectedPointCount = 0
        scanStatus = currentPrompt
    }

    func addCustomMeasurement(name: String, category: String, unit: String, notes: String) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            scanStatus = "请输入自定义测量项名称"
            return
        }
        guard !measurementNames.contains(trimmedName) else {
            scanStatus = "\(trimmedName) 已存在，请换一个名称"
            return
        }

        let trimmedCategory = category.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedUnit = unit.trimmingCharacters(in: .whitespacesAndNewlines)
        let measurement = SurveyMeasurement(
            category: trimmedCategory.isEmpty ? "自定义" : trimmedCategory,
            name: trimmedName,
            unit: trimmedUnit.isEmpty ? "mm" : trimmedUnit,
            source: "用户自定义",
            confidence: .medium,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        project.measurements.append(measurement)
        currentMeasurementIndex = project.measurements.count - 1
        selectedMeasurementName = measurement.name
        selectedModelMappingMeasurementName = measurement.name
        isMeasuringCurrentItem = false
        currentMeasurementPendingCompletion = false
        selectedPointCount = 0
        scanStatus = "已添加自定义测量项：\(measurement.name)"
        saveActiveProject()
    }

    func markModelScanComplete() {
        hasModelScan = true
        scanWorkflowMode = "逐项校准"
        currentMeasurementIndex = firstPendingMeasurementIndex()
        selectedMeasurementName = measurementNames.isEmpty ? "井道宽度" : measurementNames[currentMeasurementIndex]
        scanStatus = "空间模型已生成，请逐项校准：\(selectedMeasurementName)"
        saveActiveProject()
    }

    func addModelScanLayer(named name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let layer = ModelScanLayer(name: trimmed.isEmpty ? "新增空间扫描 \(project.modelScanLayers.count + 1)" : trimmed)
        project.modelScanLayers.append(layer)
        selectedModelScanLayerId = layer.id
        scanWorkflowMode = "空间建模"
        scanStatus = "已添加 \(layer.name)，可开始扫描"
        saveActiveProject()
    }

    func canDeleteModelScanLayer(_ layer: ModelScanLayer) -> Bool {
        guard let index = project.modelScanLayers.firstIndex(where: { $0.id == layer.id }) else {
            return false
        }
        return index >= 2
    }

    func deleteModelScanLayer(_ layer: ModelScanLayer) {
        guard canDeleteModelScanLayer(layer),
              let index = project.modelScanLayers.firstIndex(where: { $0.id == layer.id }) else {
            scanStatus = "默认 1F / 2F 扫描层不可删除"
            return
        }

        let deletedName = project.modelScanLayers[index].name
        project.modelScanLayers.remove(at: index)
        if project.modelScanLayers.isEmpty {
            selectedModelScanLayerId = nil
        } else {
            selectedModelScanLayerId = project.modelScanLayers[min(index, project.modelScanLayers.count - 1)].id
        }
        selectedModelFeatureId = selectedModelScanLayer?.features.first?.id
        scanWorkflowMode = "空间建模"
        scanStatus = "已删除 \(deletedName)"
        saveActiveProject()
    }

    func selectModelScanLayer(_ layer: ModelScanLayer) {
        selectedModelScanLayerId = layer.id
        selectedModelFeatureId = layer.features.first?.id
        scanWorkflowMode = "空间建模"
        scanStatus = "当前扫描层：\(layer.name)"
    }

    func beginSelectedModelLayerScan() {
        guard let layer = selectedModelScanLayer else {
            addModelScanLayer(named: "1F 空间扫描")
            return
        }
        scanWorkflowMode = "空间建模"
        scanStatus = "正在扫描 \(layer.name)：请缓慢环绕空间边界"
    }

    func applySelectedLayerModelValue(kind: String, to measurementName: String) {
        guard let layer = selectedModelScanLayer else {
            scanStatus = "请先选择一个已扫描层"
            return
        }

        let value: Double?
        let sourceName: String
        switch kind {
        case "宽度":
            value = selectedModelFeature?.width ?? layer.estimatedWidth
            sourceName = selectedModelFeature?.label ?? layer.name
        case "进深":
            value = selectedModelFeature?.depth ?? layer.estimatedDepth
            sourceName = selectedModelFeature?.label ?? layer.name
        case "高度":
            value = selectedModelFeature?.height ?? layer.estimatedHeight
            sourceName = selectedModelFeature?.label ?? layer.name
        default:
            value = nil
            sourceName = layer.name
        }

        guard let value else {
            scanStatus = "\(sourceName) 暂无\(kind)估算值"
            return
        }

        updateModelEstimate(named: measurementName, value: value, source: "\(sourceName) RoomPlan \(kind)映射")
        selectedMeasurementName = measurementName
        if let index = measurementNames.firstIndex(of: measurementName) {
            currentMeasurementIndex = index
        }
        scanStatus = "已将 \(sourceName) \(kind) \(Int(value)) mm 对应到 \(measurementName)"
        saveActiveProject()
    }

    func applyRoomPlanSummary(
        wallCount: Int,
        openingCount: Int,
        objectCount: Int,
        estimatedWidth: Double?,
        estimatedDepth: Double?,
        estimatedHeight: Double?,
        modelFileName: String?,
        metadataFileName: String?,
        features: [ModelScanFeature]
    ) {
        var parts = ["墙面 \(wallCount)", "洞口 \(openingCount)", "物体 \(objectCount)"]
        let layerName = selectedModelScanLayer?.name ?? "当前层"
        if let layerId = selectedModelScanLayer?.id,
           let index = project.modelScanLayers.firstIndex(where: { $0.id == layerId }) {
            project.modelScanLayers[index].scanStatus = .checked
            project.modelScanLayers[index].wallCount = wallCount
            project.modelScanLayers[index].openingCount = openingCount
            project.modelScanLayers[index].objectCount = objectCount
            project.modelScanLayers[index].estimatedWidth = estimatedWidth
            project.modelScanLayers[index].estimatedDepth = estimatedDepth
            project.modelScanLayers[index].estimatedHeight = estimatedHeight
            project.modelScanLayers[index].modelFileName = modelFileName
            project.modelScanLayers[index].metadataFileName = metadataFileName
            project.modelScanLayers[index].features = features
            project.modelScanLayers[index].scannedAt = Date()
            project.modelScanLayers[index].notes = modelFileName.map { "模型文件：\($0)" } ?? "RoomPlan 分层扫描结果，需与逐项测量校准"
            selectedModelFeatureId = features.first?.id
        }
        if let estimatedWidth {
            updateModelEstimate(named: "现有楼梯洞口宽度", value: estimatedWidth, source: "RoomPlan 模型估算")
            parts.append("宽 \(Int(estimatedWidth)) mm")
        }
        if let estimatedDepth {
            updateModelEstimate(named: "现有楼梯洞口进深", value: estimatedDepth, source: "RoomPlan 模型估算")
            parts.append("深 \(Int(estimatedDepth)) mm")
        }
        if let estimatedHeight {
            updateModelEstimate(named: "顶层高度", value: estimatedHeight, source: "RoomPlan 模型估算")
            parts.append("高 \(Int(estimatedHeight)) mm")
        }
        if modelFileName != nil {
            parts.append("模型已保存")
        }
        hasModelScan = true
        scanWorkflowMode = "空间建模"
        modelEstimateStatus = "\(layerName)：" + parts.joined(separator: " / ")
        scanStatus = "\(layerName) 模型已生成，可继续扫描其他层或进入逐项校准"
        saveActiveProject()
    }

    func modelFileURL(for layer: ModelScanLayer) -> URL? {
        guard let modelFileName = layer.modelFileName else { return nil }
        return Self.modelStorageDirectory().appendingPathComponent(modelFileName)
    }

    static func modelStorageDirectory() -> URL {
        let base = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first ?? FileManager.default.temporaryDirectory
        let directory = base.appendingPathComponent("RoomPlanModels", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    static func measurementPhotoDirectory() -> URL {
        let base = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first ?? FileManager.default.temporaryDirectory
        let directory = base.appendingPathComponent("MeasurementEvidence", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private func mergeDefaultMeasurementsIfNeeded() {
        let existingNames = Set(project.measurements.map(\.name))
        let missing = SurveyProject.defaultMeasurements().filter { !existingNames.contains($0.name) }
        guard !missing.isEmpty else { return }
        project.measurements.append(contentsOf: missing)
        saveActiveProject()
    }

    private func firstPendingMeasurementIndex() -> Int {
        project.measurements.firstIndex(where: { $0.finalValue == nil }) ?? 0
    }

    private func loadProjects() {
        guard let data = UserDefaults.standard.data(forKey: projectsStorageKey) else { return }
        do {
            projects = try JSONDecoder().decode([SurveyProject].self, from: data)
        } catch {
            projects = []
        }
    }

    private func persistProjects() {
        do {
            let data = try JSONEncoder().encode(projects)
            UserDefaults.standard.set(data, forKey: projectsStorageKey)
        } catch {
            scanStatus = "项目保存失败"
        }
    }

    private func updateMeasurement(named name: String, value: Double?, payload: ScanMeasurementPayload) {
        guard let value, let index = project.measurements.firstIndex(where: { $0.name == name }) else { return }
        project.measurements[index].scannedValue = value
        project.measurements[index].finalValue = value
        project.measurements[index].source = payload.source
        project.measurements[index].confidence = payload.confidence
        project.measurements[index].reviewStatus = .checked
        syncProjectDimension(named: name, value: value)
        saveActiveProject()
    }

    private func writeMeasurement(named name: String, value: Double, source: String, confidence: MeasurementConfidence) {
        guard let index = project.measurements.firstIndex(where: { $0.name == name }) else { return }
        project.measurements[index].scannedValue = value
        project.measurements[index].finalValue = value
        project.measurements[index].source = source
        project.measurements[index].confidence = confidence
        project.measurements[index].reviewStatus = .checked
        syncProjectDimension(named: name, value: value)
    }

    private func updateModelEstimate(named name: String, value: Double, source: String) {
        guard let index = project.measurements.firstIndex(where: { $0.name == name }) else { return }
        project.measurements[index].modelValue = value
        project.measurements[index].source = source
        project.measurements[index].confidence = .low
        project.measurements[index].notes = "模型估算值，需逐项校准"
        if project.measurements[index].scannedValue == nil {
            project.measurements[index].finalValue = value
            syncProjectDimension(named: name, value: value)
        }
    }

    private func clearMeasurementValue(named name: String) {
        guard let index = project.measurements.firstIndex(where: { $0.name == name }) else { return }
        project.measurements[index].scannedValue = nil
        project.measurements[index].finalValue = project.measurements[index].modelValue
        project.measurements[index].reviewStatus = .unreviewed
        if let modelValue = project.measurements[index].modelValue {
            syncProjectDimension(named: name, value: modelValue)
        }
        saveActiveProject()
    }

    private func syncProjectDimension(named name: String, value: Double) {
        switch name {
        case "现有楼梯洞口宽度", "楼梯洞口宽度":
            project.stairWidth = value
        case "现有楼梯洞口进深", "楼梯洞口进深":
            project.stairDepth = value
        case "井道宽度", "井道净宽":
            project.shaftWidth = value
        case "井道深度", "井道净深":
            project.shaftDepth = value
        case "底坑深度":
            project.pitDepth = value
        case "顶层高度", "顶层净空":
            project.overhead = value
        default:
            break
        }
    }
}
