import SwiftUI

struct ContentView: View {
    @StateObject private var store = SurveyStore()
    @State private var selectedTab = 0

    var body: some View {
        if store.hasActiveProject {
            TabView(selection: $selectedTab) {
                ScannerScreen(store: store, selectedTab: $selectedTab)
                    .tabItem {
                        Label("测算", systemImage: "viewfinder")
                    }
                    .tag(0)

                ReportScreen(store: store)
                    .tabItem {
                        Label("项目数据", systemImage: "doc.text")
                    }
                    .tag(1)
            }
        } else {
            ProjectHomeScreen(store: store, selectedTab: $selectedTab)
        }
    }
}

struct ProjectHomeScreen: View {
    @ObservedObject var store: SurveyStore
    @Binding var selectedTab: Int
    @State private var showingNewProject = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        showingNewProject = true
                    } label: {
                        Label("新建测算项目", systemImage: "plus.circle.fill")
                            .font(.headline)
                    }
                } footer: {
                    Text("新项目会按照测算优先级提示：楼梯洞口、井道、底坑、顶层、门洞。")
                }

                Section("已有项目数据") {
                    if store.activeProjects.isEmpty {
                        ContentUnavailableView("暂无项目", systemImage: "folder", description: Text("创建项目后，勘测数据会保存在当前会话中。"))
                    } else {
                        ForEach(store.activeProjects) { project in
                            projectRow(project)
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        store.deleteProject(project)
                                    } label: {
                                        Label("删除", systemImage: "trash")
                                    }

                                    Button {
                                        store.archiveProject(project)
                                    } label: {
                                        Label("归档", systemImage: "archivebox")
                                    }
                                    .tint(.orange)
                                }
                        }
                    }
                }

                if !store.archivedProjects.isEmpty {
                    Section("已归档") {
                        ForEach(store.archivedProjects) { project in
                            projectRow(project, isArchived: true)
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        store.deleteProject(project)
                                    } label: {
                                        Label("删除", systemImage: "trash")
                                    }

                                    Button {
                                        store.restoreProject(project)
                                    } label: {
                                        Label("恢复", systemImage: "arrow.uturn.backward")
                                    }
                                    .tint(.blue)
                                }
                        }
                    }
                }
            }
            .navigationTitle("别墅梯勘测")
            .sheet(isPresented: $showingNewProject) {
                NewProjectSheet(store: store, selectedTab: $selectedTab)
            }
        }
    }

    private func projectRow(_ project: SurveyProject, isArchived: Bool = false) -> some View {
        Button {
            store.openProject(project)
            selectedTab = 0
        } label: {
            HStack(spacing: 10) {
                Image(systemName: isArchived ? "archivebox.fill" : "folder.fill")
                    .foregroundStyle(isArchived ? .orange : .blue)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text(project.name)
                            .font(.headline)
                        if isArchived {
                            Text("已归档")
                                .font(.caption2.weight(.semibold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.orange.opacity(0.14))
                                .foregroundStyle(.orange)
                                .clipShape(Capsule())
                        }
                    }
                    Text("\(project.stops) 站 · 已完成 \(project.measurements.filter { $0.finalValue != nil }.count)/\(project.measurements.count) 项 · \(project.createdAt.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

struct NewProjectSheet: View {
    @ObservedObject var store: SurveyStore
    @Binding var selectedTab: Int
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var stops = 2

    var body: some View {
        NavigationStack {
            Form {
                Section("项目") {
                    TextField("项目名称", text: $name)
                    Stepper("楼层 / 站数：\(stops)", value: $stops, in: 2...6)
                }
                Section("测算流程") {
                    Label("先建立项目，再按优先级逐项使用 LiDAR 测量。", systemImage: "1.circle")
                    Label("也可以先做空间建模，再逐项校准关键尺寸。", systemImage: "2.circle")
                }
            }
            .navigationTitle("新建测算项目")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("开始") {
                        store.startNewProject(name: name, stops: stops)
                        selectedTab = 0
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ScannerScreen: View {
    @ObservedObject var store: SurveyStore
    @Binding var selectedTab: Int
    @State private var showingRoomPlanScanner = false
    @State private var showingCustomMeasurementSheet = false
    @State private var showingCombinedModelPreview = false
    @State private var newModelLayerName = ""

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .top) {
                ARScannerView(store: store)
                    .ignoresSafeArea()

                VStack(spacing: 10) {
                    statusBar
                    Spacer(minLength: 0)
                    actionPanel(maxHeight: max(230, proxy.size.height * 0.34))
                }
                .padding(.horizontal, 12)
                .padding(.top, 8)
                .padding(.bottom, 8)
            }
        }
        .fullScreenCover(isPresented: $showingRoomPlanScanner) {
            if #available(iOS 16.0, *) {
                RoomPlanScannerContainer(store: store)
                    .onDisappear {
                        store.isRoomPlanScannerPresented = false
                    }
            } else {
                Text("当前系统不支持 RoomPlan")
            }
        }
        .sheet(isPresented: $showingCustomMeasurementSheet) {
            CustomMeasurementSheet(store: store)
        }
        .fullScreenCover(isPresented: $showingCombinedModelPreview) {
            CombinedRoomPlanModelPreview(layers: combinedModelPreviewLayers) {
                showingCombinedModelPreview = false
            }
        }
    }

    private var statusBar: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(store.project.name)
                        .font(.headline)
                    Text("\(store.workflowProgressText) · \(store.scanStatus)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 3) {
                    Text("网格 \(store.meshAnchorCount)")
                    Text("平面 \(store.planeAnchorCount)")
                    Text(store.horizontalCalibrationStatus)
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            }
            if let distance = store.latestDistanceMillimeters {
                Label("最近测距 \(Int(distance)) mm，已写入 \(store.selectedMeasurementName)", systemImage: "ruler")
                    .font(.callout.weight(.semibold))
            }
            ProgressView(value: Double(store.completedMeasurementCount), total: Double(max(store.measurementNames.count, 1)))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func actionPanel(maxHeight: CGFloat) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                phaseStrip
                workflowControlPanel

                Text(promptText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                measurementGuideCard

                if store.hasModelScan || store.scanWorkflowMode == "空间建模" {
                    Label(store.modelEstimateStatus, systemImage: "cube.transparent")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                Picker("当前测量项", selection: measurementSelection) {
                    ForEach(store.measurementNames, id: \.self) { name in
                        Text(name).tag(name)
                    }
                }
                .pickerStyle(.menu)

                measurementChips

                if store.scanWorkflowMode == "空间建模" {
                    modelScanPanel
                } else {
                    measurementActionPanel
                }

                HStack(spacing: 10) {
                    Button {
                        importMockScan()
                    } label: {
                        Label("模拟扫描写入", systemImage: "square.and.arrow.down")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)

                    Button {
                        selectedTab = 1
                    } label: {
                        Label("看报告", systemImage: "doc.text")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }

                if store.importRevision > 0 {
                    Label("已完成第 \(store.importRevision) 次模拟导入，报告数据已更新。", systemImage: "checkmark.circle.fill")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.green)
                }
            }
            .padding(14)
        }
        .frame(maxHeight: maxHeight)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var phaseStrip: some View {
        HStack(spacing: 6) {
            phaseButton("1", "逐项测量", active: store.scanWorkflowMode == "逐项测量") {
                store.enterManualMeasurement()
            }
            phaseButton("2", "空间建模", active: store.scanWorkflowMode == "空间建模") {
                store.enterModelScan()
            }
            phaseButton("3", "逐项校准", active: store.scanWorkflowMode == "逐项校准") {
                store.enterCalibration()
            }
            phaseButton("4", "报告", active: false) {
                selectedTab = 1
            }
        }
    }

    private func phaseButton(_ number: String, _ title: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(number)
                    .font(.caption2.weight(.bold))
                    .frame(width: 18, height: 18)
                    .background(active ? Color.blue : Color(.tertiarySystemFill))
                    .foregroundStyle(active ? .white : .secondary)
                    .clipShape(Circle())
                Text(title)
                    .font(.caption2.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity)
            .background(active ? Color.blue.opacity(0.12) : Color(.secondarySystemBackground))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var workflowControlPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("流程控制", systemImage: "point.topleft.down.curvedto.point.bottomright.up")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            HStack(spacing: 10) {
                Button {
                    store.enterManualMeasurement()
                } label: {
                    Label("人工逐项测量", systemImage: "scope")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(store.scanWorkflowMode == "逐项测量" ? .blue : .gray)

                Button {
                    store.enterModelScan()
                } label: {
                    Label("空间建模", systemImage: "cube.viewfinder")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(store.scanWorkflowMode == "空间建模" ? .blue : .gray)
            }
        }
        .padding(12)
        .background(Color(.secondarySystemBackground).opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var measurementSelection: Binding<String> {
        Binding(
            get: { store.selectedMeasurementName },
            set: { store.goToMeasurement(named: $0) }
        )
    }

    private var promptText: String {
        switch store.scanWorkflowMode {
        case "空间建模":
            return "先缓慢环绕井道、楼梯洞口、底坑和顶层区域，让 LiDAR 形成空间模型。完成后进入逐项校准。"
        case "逐项校准":
            return "对照已建模型继续测量关键项。当前提示：\(store.currentPrompt)"
        default:
            return "当前提示：\(store.currentPrompt)。在画面中点两个位置，测得距离会直接写入该字段。"
        }
    }

    private var measurementGuideCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(store.selectedMeasurementName, systemImage: "scope")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text(pointStatusText)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(pointStatusColor)
            }

            Text(measurementInstruction(for: store.selectedMeasurementName))
                .font(.footnote)
                .foregroundStyle(.primary)

            HStack(spacing: 8) {
                guideStep("1", active: store.isMeasuringCurrentItem && store.selectedPointCount == 0, done: store.selectedPointCount > 0 || store.currentMeasurementPendingCompletion, title: "第 1 点")
                guideStep("2", active: store.isMeasuringCurrentItem && store.selectedPointCount == 1, done: store.currentMeasurementPendingCompletion, title: "第 2 点")
                guideStep("3", active: store.currentMeasurementPendingCompletion, done: false, title: "完成/重测")
            }
        }
        .padding(12)
        .background(Color(.secondarySystemBackground).opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var pointStatusText: String {
        if store.currentMeasurementPendingCompletion { return "待确认" }
        if store.isMeasuringCurrentItem {
            return store.selectedPointCount == 0 ? "选第 1 点" : "选第 2 点"
        }
        return "未开始"
    }

    private var pointStatusColor: Color {
        if store.currentMeasurementPendingCompletion { return .green }
        if store.isMeasuringCurrentItem { return .blue }
        return .secondary
    }

    private func guideStep(_ number: String, active: Bool, done: Bool, title: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: done ? "checkmark.circle.fill" : "\(number).circle.fill")
                .foregroundStyle(done ? .green : (active ? .blue : .secondary))
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(active || done ? .primary : .secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(active ? Color.blue.opacity(0.1) : Color(.tertiarySystemFill))
        .clipShape(Capsule())
    }

    private func measurementInstruction(for name: String) -> String {
        switch name {
        case "现有楼梯洞口宽度", "楼梯洞口宽度":
            return "请在同一水平高度，分别点选楼梯洞口左、右两侧内边缘。避开扶手、踢脚线和临时遮挡物。"
        case "现有楼梯洞口进深", "楼梯洞口进深":
            return "请沿拟开孔方向，点选洞口前、后两侧内边缘。优先选择能保留楼体边界的基准点。"
        case "井道宽度", "井道净宽":
            return "请点选井道左右结构内边线的两个相对点，尽量保持同一高度。优先贴近墙面、钢架或混凝土边缘。"
        case "井道深度", "井道净深":
            return "请点选井道前后结构内边线的两个相对点。若有凸梁、管线或装饰层，请按最终保留/拆除后的结构边界取点。"
        case "前层门入口净宽", "后层门入口净宽", "门洞宽度":
            return "请点选门洞左右内边缘。优先选择门套拆除后的结构边界或拟保留边界，确保两点在同一水平线附近。"
        case "前层门入口净高", "后层门入口净高", "门洞高度":
            return "请先点选地坎或完成地面基准，再点选门洞上沿、梁底或最低障碍物底面。"
        case "前层门头梁宽", "后层门头梁宽":
            return "请点选门头梁可见宽度两侧边线，用于判断层门安装和门机空间。若饰面未拆，请备注当前为饰面尺寸。"
        case "左门垛":
            return "请点选门洞左侧边线与左侧墙/井道边界之间的净尺寸两端，记录可用于门套和外召定位。"
        case "右门垛":
            return "请点选门洞右侧边线与右侧墙/井道边界之间的净尺寸两端，记录可用于门套和外召定位。"
        case "层站高度":
            return "请点选当前层完成地面和上一层完成地面之间的垂直距离基准，尽量在楼梯洞或井道边缘测量。"
        case "导轨圈梁间距":
            return "请点选相邻两道导轨圈梁中心线或同侧边线，保持取点基准一致。"
        case "导轨圈梁高度":
            return "请点选圈梁底面与顶面，或按现场约定的结构高度两端进行测量。"
        case "顶层圈梁离顶层地面高度":
            return "请先点选顶层完成地面，再点选顶层圈梁底面或图纸要求的对应边线。"
        case "底坑深度":
            return "请先点选首层完成地面基准点，再点选底坑最低完成面或拟开挖底面。"
        case "起台高度":
            return "如底坑采用起台处理，请点选原完成面与起台完成面之间的垂直距离。无起台时可跳过或备注。"
        case "顶层高度", "顶层净空":
            return "请先点选顶层完成地面，再点选顶板、梁底或最低障碍物底面。该值会影响顶层空间方案。"
        case "提升高度":
            return "请点选最低停靠层完成地面与最高停靠层完成地面之间的垂直距离。"
        case "控制柜孔洞宽度":
            return "请点选控制柜预留孔左右边缘，记录孔洞净宽。"
        case "控制柜孔洞高度":
            return "请点选控制柜预留孔下沿和上沿，记录孔洞净高。"
        default:
            return "请按该尺寸的两个结构边界点进行点选。靠近边线时系统会尝试轻微吸附，测量成功后可拍照保存、完成或重新测量。"
        }
    }

    private var modelScanPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("LiDAR 网格 \(store.meshAnchorCount)", systemImage: "cube.transparent")
                Spacer()
                Label("平面 \(store.planeAnchorCount)", systemImage: "square.on.square")
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)

            HStack {
                Text("分层扫描")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text("\(store.completedModelScanLayerCount)/\(max(store.project.modelScanLayers.count, 1))")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(store.project.modelScanLayers) { layer in
                        Button {
                            store.selectModelScanLayer(layer)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 5) {
                                    Image(systemName: layer.scanStatus == .unreviewed ? "circle" : "checkmark.circle.fill")
                                    Text(layer.name)
                                }
                                .font(.caption.weight(.semibold))
                                Text(layerSummary(layer))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .frame(minWidth: 130, alignment: .leading)
                            .background(store.selectedModelScanLayer?.id == layer.id ? Color.blue.opacity(0.16) : Color(.tertiarySystemFill))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            if store.canDeleteModelScanLayer(layer) {
                                Button(role: .destructive) {
                                    store.deleteModelScanLayer(layer)
                                } label: {
                                    Label("删除该层", systemImage: "trash")
                                }
                            } else {
                                Label("默认楼层不可删除", systemImage: "lock")
                            }
                        }
                    }
                }
            }

            HStack(spacing: 8) {
                TextField("如：3F / 夹层 / 楼梯平台", text: $newModelLayerName)
                    .textFieldStyle(.roundedBorder)
                Button {
                    store.addModelScanLayer(named: newModelLayerName)
                    newModelLayerName = ""
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                }
                .buttonStyle(.borderless)
            }

            if let selectedLayer = store.selectedModelScanLayer,
               store.canDeleteModelScanLayer(selectedLayer) {
                Button(role: .destructive) {
                    store.deleteModelScanLayer(selectedLayer)
                } label: {
                    Label("删除当前扫描层：\(selectedLayer.name)", systemImage: "trash")
                        .font(.caption.weight(.semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }

            wholeModelSummary

            if let layer = store.selectedModelScanLayer, layer.scanStatus != .unreviewed {
                modelMappingPanel(layer)
            }

            Button {
                store.beginSelectedModelLayerScan()
                store.isRoomPlanScannerPresented = true
                showingRoomPlanScanner = true
            } label: {
                Label("扫描当前层：\(store.selectedModelScanLayer?.name ?? "未选择")", systemImage: "cube.viewfinder")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            Button {
                store.markModelScanComplete()
            } label: {
                Label("跳过建模，直接校准", systemImage: "arrow.right.circle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            Text("默认按 1F / 2F 分层扫描；如现场超过两层，可继续添加楼层或楼梯平台。RoomPlan 模型结果只作为低置信度候选值，关键尺寸仍需要逐项校准。")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(Color(.secondarySystemBackground).opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var wholeModelSummary: some View {
        let summary = store.aggregateModelSummary
        return VStack(alignment: .leading, spacing: 6) {
            Label("整体模型汇总", systemImage: "square.stack.3d.up")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            HStack {
                modelMetric("墙", "\(summary.wallCount)")
                modelMetric("洞口", "\(summary.openingCount)")
                modelMetric("物体", "\(summary.objectCount)")
                modelMetric("最大宽", summary.estimatedWidth.map { "\(Int($0))" } ?? "-")
                modelMetric("最大深", summary.estimatedDepth.map { "\(Int($0))" } ?? "-")
                modelMetric("最大高", summary.estimatedHeight.map { "\(Int($0))" } ?? "-")
            }

            if !combinedModelPreviewLayers.isEmpty {
                Button {
                    showingCombinedModelPreview = true
                } label: {
                    Label("预览整体模型", systemImage: "square.stack.3d.up.fill")
                        .font(.caption.weight(.semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(10)
        .background(Color(.tertiarySystemFill))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var combinedModelPreviewLayers: [ModelPreviewLayer] {
        store.project.modelScanLayers.compactMap { layer in
            guard layer.scanStatus != .unreviewed,
                  let url = store.modelFileURL(for: layer) else {
                return nil
            }
            return ModelPreviewLayer(id: layer.id, name: layer.name, url: url, estimatedHeight: layer.estimatedHeight)
        }
    }

    private func modelMetric(_ title: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.caption.weight(.bold))
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func modelMappingPanel(_ layer: ModelScanLayer) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("模型数据对应", systemImage: "arrow.triangle.branch")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            if let url = store.modelFileURL(for: layer) {
                HStack(spacing: 8) {
                    Label("模型文件已保存", systemImage: "cube.box.fill")
                        .font(.caption.weight(.semibold))
                    Spacer()
                    ShareLink(item: url) {
                        Label("导出", systemImage: "square.and.arrow.up")
                            .font(.caption.weight(.semibold))
                    }
                }
                .padding(8)
                .background(Color.blue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            if !layer.features.isEmpty {
                Picker("模型位置", selection: Binding(
                    get: { store.selectedModelFeature?.id ?? layer.features.first?.id ?? UUID() },
                    set: { store.selectedModelFeatureId = $0 }
                )) {
                    ForEach(layer.features) { feature in
                        Text(featureTitle(feature)).tag(feature.id)
                    }
                }
                .pickerStyle(.menu)
            }

            Picker("对应测量项", selection: $store.selectedModelMappingMeasurementName) {
                ForEach(store.measurementNames, id: \.self) { name in
                    Text(name).tag(name)
                }
            }
            .pickerStyle(.menu)

            HStack(spacing: 8) {
                Button {
                    store.applySelectedLayerModelValue(kind: "宽度", to: store.selectedModelMappingMeasurementName)
                } label: {
                    Label(modelDimensionText(kind: "宽", value: store.selectedModelFeature?.width ?? layer.estimatedWidth), systemImage: "arrow.left.and.right")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled((store.selectedModelFeature?.width ?? layer.estimatedWidth) == nil)

                Button {
                    store.applySelectedLayerModelValue(kind: "进深", to: store.selectedModelMappingMeasurementName)
                } label: {
                    Label(modelDimensionText(kind: "深", value: store.selectedModelFeature?.depth ?? layer.estimatedDepth), systemImage: "arrow.down.forward.and.arrow.up.backward")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled((store.selectedModelFeature?.depth ?? layer.estimatedDepth) == nil)
            }

            HStack(spacing: 8) {
                Button {
                    store.applySelectedLayerModelValue(kind: "高度", to: store.selectedModelMappingMeasurementName)
                } label: {
                    Label(modelDimensionText(kind: "高", value: store.selectedModelFeature?.height ?? layer.estimatedHeight), systemImage: "arrow.up.and.down")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled((store.selectedModelFeature?.height ?? layer.estimatedHeight) == nil)
            }

            Text("先选择模型里的墙面、洞口、门洞或地面，再把宽/深/高对应到逐项测量字段。模型值会作为低置信度候选值，后续仍可点选校准。")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(10)
        .background(Color(.tertiarySystemFill))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func layerSummary(_ layer: ModelScanLayer) -> String {
        if layer.scanStatus == .unreviewed {
            return "未扫描"
        }
        let fileText = layer.modelFileName == nil ? "未导出" : "已导出"
        return "墙 \(layer.wallCount) · 洞口 \(layer.openingCount) · \(fileText)"
    }

    private func featureTitle(_ feature: ModelScanFeature) -> String {
        let width = feature.width.map { "宽\(Int($0))" } ?? "-"
        let height = feature.height.map { "高\(Int($0))" } ?? "-"
        return "\(feature.label) · \(feature.category) · \(width) · \(height)"
    }

    private func modelDimensionText(kind: String, value: Double?) -> String {
        guard let value else { return "无\(kind)度" }
        return "\(kind) \(Int(value)) mm"
    }

    private var measurementActionPanel: some View {
        VStack(spacing: 10) {
            Button {
                store.startCurrentMeasurement()
            } label: {
                Label(store.isMeasuringCurrentItem ? "正在测量该项" : "开始测量该项", systemImage: "scope")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(store.isMeasuringCurrentItem || store.currentMeasurementPendingCompletion)

            if store.currentMeasurementPendingCompletion {
                Button {
                    store.requestCurrentMeasurementPhoto()
                } label: {
                    Label(store.latestMeasurementPhotoName == nil ? "拍照保存测量记录" : "已保存，可继续拍照", systemImage: store.latestMeasurementPhotoName == nil ? "camera.viewfinder" : "camera.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                HStack(spacing: 10) {
                    Button {
                        store.redoCurrentMeasurement()
                    } label: {
                        Label("重新测量", systemImage: "arrow.counterclockwise")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)

                    Button {
                        store.completeCurrentMeasurement()
                    } label: {
                        Label("完成该项", systemImage: "checkmark")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }

            HStack(spacing: 10) {
                Button {
                    store.goPreviousMeasurement()
                } label: {
                    Label("上一项", systemImage: "chevron.left")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(!store.canGoPrevious || store.isMeasuringCurrentItem)

                Button {
                    store.goNextMeasurement()
                } label: {
                    Label("跳过/下一项", systemImage: "chevron.right")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(!store.canGoNext || store.isMeasuringCurrentItem)
            }
        }
    }

    private var measurementChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(store.measurementNames, id: \.self) { name in
                    Button {
                        store.goToMeasurement(named: name)
                    } label: {
                        HStack(spacing: 5) {
                            if isCompleted(name) {
                                Image(systemName: "checkmark.circle.fill")
                            }
                            Text(name)
                        }
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(store.selectedMeasurementName == name ? Color.blue : Color(.secondarySystemBackground))
                        .foregroundStyle(store.selectedMeasurementName == name ? .white : .primary)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
                Button {
                    showingCustomMeasurementSheet = true
                } label: {
                    Label("自定义", systemImage: "plus")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func isCompleted(_ name: String) -> Bool {
        store.project.measurements.first(where: { $0.name == name })?.finalValue != nil
    }

    private func importMockScan() {
        store.apply(payload: ScanMeasurementPayload(
            source: "模拟 ARKit LiDAR",
            confidence: .medium,
            stairWidth: 2240,
            stairDepth: 3960,
            shaftWidth: 1400,
            shaftDepth: 1500,
            overhead: 2920,
            pitDepth: 210
        ))
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        selectedTab = 1
    }
}

struct CustomMeasurementSheet: View {
    @ObservedObject var store: SurveyStore
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var category = "自定义"
    @State private var unit = "mm"
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("测量项") {
                    TextField("如：梁底净高 / 管线避让宽度", text: $name)
                    TextField("类别", text: $category)
                    TextField("单位", text: $unit)
                        .textInputAutocapitalization(.never)
                }

                Section("现场备注") {
                    TextField("如：饰面未拆，需复核结构边界", text: $notes, axis: .vertical)
                        .lineLimit(3, reservesSpace: true)
                }

                Section {
                    Text("自定义项会加入当前项目的测量顺序，并可继续使用 LiDAR 点选、拍照保存和模型数据对应。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("添加测量项")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("添加") {
                        store.addCustomMeasurement(name: name, category: category, unit: unit, notes: notes)
                        if store.selectedMeasurementName == name.trimmingCharacters(in: .whitespacesAndNewlines) {
                            dismiss()
                        }
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

struct ReportScreen: View {
    @ObservedObject var store: SurveyStore

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        store.closeProject()
                    } label: {
                        Label("返回项目首页", systemImage: "folder")
                    }
                }

                Section("项目判断") {
                    reportRow("拆除面积", String(format: "%.2f m²", store.demolitionArea))
                    reportRow("保留通行宽度", "\(Int(store.retainedWidth)) mm")
                    reportRow("保留进深余量", "\(Int(store.retainedDepth)) mm")
                    reportRow("顶层净空", "\(Int(store.project.overhead)) mm")
                    reportRow("底坑深度", "\(Int(store.project.pitDepth)) mm")
                }

                Section("拆除 / 保留示意") {
                    DemolitionRetentionDiagram(store: store)
                        .listRowInsets(EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12))
                }

                Section("LiDAR / 人工尺寸") {
                    ForEach(store.project.measurements) { item in
                        VStack(alignment: .leading, spacing: 5) {
                            HStack {
                                Text(item.name)
                                    .font(.headline)
                                Spacer()
                                Text(displayValue(item.finalValue, unit: item.unit))
                                    .font(.headline)
                            }
                            Text("\(item.source) · 置信度 \(item.confidence.rawValue) · \(item.reviewStatus.rawValue)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            if let modelValue = item.modelValue {
                                Text("模型估算：\(Int(modelValue)) \(item.unit)")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            if let evidencePhotoNames = item.evidencePhotoNames, !evidencePhotoNames.isEmpty {
                                Label("测量照片 \(evidencePhotoNames.count) 张", systemImage: "photo.on.rectangle")
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                }

                Section("扫描状态") {
                    reportRow("最近状态", store.scanStatus)
                    reportRow("模型估算", store.modelEstimateStatus)
                    reportRow("LiDAR 网格数", "\(store.meshAnchorCount)")
                    reportRow("识别平面数", "\(store.planeAnchorCount)")
                    reportRow("模拟导入次数", "\(store.importRevision)")
                }

                Section("分层拆除 / 保留") {
                    ForEach(store.project.layers) { layer in
                        VStack(alignment: .leading, spacing: 5) {
                            HStack {
                                Text(layer.level)
                                    .font(.headline)
                                Spacer()
                                Text(layer.conclusion)
                                    .font(.subheadline.weight(.semibold))
                            }
                            Text("楼板：\(layer.slabAction)  楼梯段：\(layer.stairAction)")
                                .font(.caption)
                            Text("梁/承重墙：\(layer.beamAction)  管线：\(layer.pipeAction)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("风险与建议") {
                    ForEach(store.risks) { risk in
                        VStack(alignment: .leading, spacing: 5) {
                            HStack {
                                Text(risk.title)
                                    .font(.headline)
                                Spacer()
                                Text(risk.level)
                                    .font(.subheadline.weight(.bold))
                                    .foregroundStyle(risk.level == "高" ? .red : .orange)
                            }
                            Text(risk.detail)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("勘测报告")
        }
    }

    private func reportRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
        }
    }

    private func displayValue(_ value: Double?, unit: String) -> String {
        guard let value else { return "未采集" }
        return "\(Int(value)) \(unit)"
    }
}

struct DemolitionRetentionDiagram: View {
    @ObservedObject var store: SurveyStore

    private var measuredCount: Int {
        store.project.measurements.filter { $0.scannedValue != nil }.count
    }

    private var modelCount: Int {
        store.completedModelScanLayerCount
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("拆除 / 保留示意")
                        .font(.headline)
                    Text("按逐项测量尺寸生成，RoomPlan 模型用于辅助校准边界")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                legend
            }

            GeometryReader { proxy in
                diagram(in: proxy.size)
            }
            .frame(height: 360)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(.separator), lineWidth: 1)
            }

            HStack(spacing: 8) {
                fusionChip("测量", "\(measuredCount)/\(store.project.measurements.count)", .blue)
                fusionChip("模型", "\(modelCount)/\(max(store.project.modelScanLayers.count, 1)) 层", .purple)
                fusionChip("结论", store.retainedWidth >= store.project.keepPassage ? "通行可保留" : "需调整", store.retainedWidth >= store.project.keepPassage ? .green : .red)
            }
        }
    }

    private var legend: some View {
        HStack(spacing: 8) {
            HStack(spacing: 4) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.blue.opacity(0.16))
                    .frame(width: 14, height: 14)
                Text("保留")
            }
            HStack(spacing: 4) {
                RoundedRectangle(cornerRadius: 3)
                    .stroke(Color.red, lineWidth: 1.5)
                    .frame(width: 14, height: 14)
                Text("拆除")
            }
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(.secondary)
    }

    private func diagram(in size: CGSize) -> some View {
        let stairWidth = max(store.project.stairWidth, 1)
        let stairDepth = max(store.project.stairDepth, 1)
        let requiredWidth = max(store.requiredWidth, 1)
        let requiredDepth = max(store.requiredDepth, 1)
        let scale = min((size.width - 92) / stairWidth, (size.height - 112) / stairDepth)
        let openingWidth = stairWidth * scale
        let openingHeight = stairDepth * scale
        let openingX = (size.width - openingWidth) / 2
        let openingY: CGFloat = 54
        let removalWidth = min(requiredWidth * scale, openingWidth)
        let removalHeight = min(requiredDepth * scale, openingHeight)
        let shaftX = openingX + store.project.safetyMargin * scale
        let shaftY = openingY + store.project.safetyMargin * scale
        let shaftWidth = min(store.project.shaftWidth * scale, max(removalWidth - store.project.safetyMargin * scale * 2, 1))
        let shaftDepth = min(store.project.shaftDepth * scale, max(removalHeight - store.project.safetyMargin * scale * 2, 1))
        let passageWidth = max(openingWidth - removalWidth, 0)

        return ZStack(alignment: .topLeading) {
            Text("现有楼梯洞口 \(Int(stairWidth)) x \(Int(stairDepth)) mm")
                .font(.caption.weight(.bold))
                .foregroundStyle(.primary)
                .position(x: openingX + openingWidth / 2, y: openingY - 22)

            RoundedRectangle(cornerRadius: 8)
                .fill(Color.blue.opacity(0.12))
                .frame(width: openingWidth, height: openingHeight)
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.blue.opacity(0.55), lineWidth: 1.5)
                }
                .position(x: openingX + openingWidth / 2, y: openingY + openingHeight / 2)

            Rectangle()
                .fill(Color.blue.opacity(0.06))
                .frame(width: passageWidth, height: openingHeight)
                .overlay {
                    Rectangle()
                        .stroke(Color.blue, style: StrokeStyle(lineWidth: 1.2, dash: [6, 5]))
                }
                .position(x: openingX + removalWidth + passageWidth / 2, y: openingY + openingHeight / 2)

            if passageWidth > 28 {
                Text("保留通行\n\(Int(store.retainedWidth)) mm")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.blue)
                    .multilineTextAlignment(.center)
                    .position(x: openingX + removalWidth + passageWidth / 2, y: openingY + 52)
            }

            demolitionZone(width: removalWidth, height: removalHeight)
                .position(x: openingX + removalWidth / 2, y: openingY + removalHeight / 2)

            RoundedRectangle(cornerRadius: 5)
                .fill(Color.green.opacity(0.15))
                .overlay {
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(Color.green, lineWidth: 1.5)
                }
                .frame(width: shaftWidth, height: shaftDepth)
                .position(x: shaftX + shaftWidth / 2, y: shaftY + shaftDepth / 2)

            VStack(alignment: .leading, spacing: 3) {
                Text("拟建井道")
                    .font(.caption.weight(.bold))
                Text("\(Int(store.project.shaftWidth)) x \(Int(store.project.shaftDepth)) mm")
                    .font(.caption2)
                Spacer(minLength: 4)
                Text("拆除楼板 / 楼梯段")
                    .font(.caption2.weight(.medium))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 3)
                    .background(.white.opacity(0.72))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
            .foregroundStyle(.primary)
            .padding(8)
            .frame(width: shaftWidth, height: shaftDepth, alignment: .topLeading)
            .position(x: shaftX + shaftWidth / 2, y: shaftY + shaftDepth / 2)

            axisLabel("宽度方向", x: openingX + openingWidth / 2, y: openingY + openingHeight + 42)
            axisLabel("进深方向", x: openingX - 38, y: openingY + openingHeight / 2, rotation: -90)
        }
    }

    private func demolitionZone(width: CGFloat, height: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.red.opacity(0.08))
            Canvas { context, size in
                var path = Path()
                var x: CGFloat = -size.height
                while x < size.width {
                    path.move(to: CGPoint(x: x, y: size.height))
                    path.addLine(to: CGPoint(x: x + size.height, y: 0))
                    x += 12
                }
                context.stroke(path, with: .color(.red.opacity(0.38)), lineWidth: 1)
            }
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.red, lineWidth: 1.8)
        }
        .frame(width: width, height: height)
    }

    private func axisLabel(_ text: String, x: CGFloat, y: CGFloat, rotation: Double = 0) -> some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.secondary)
            .rotationEffect(.degrees(rotation))
            .position(x: x, y: y)
    }

    private func fusionChip(_ title: String, _ value: String, _ color: Color) -> some View {
        VStack(spacing: 3) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption.weight(.bold))
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.09))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    ContentView()
}
