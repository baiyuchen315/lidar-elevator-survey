import RoomPlan
import RealityKit
import SceneKit
import SwiftUI

@available(iOS 16.0, *)
struct RoomPlanScannerContainer: View {
    @ObservedObject var store: SurveyStore
    @Environment(\.dismiss) private var dismiss
    @State private var finishRevision = 0
    @State private var isFinishing = false
    @State private var previewModelURL: URL?
    @State private var isShowingModelPreview = false
    private let scannerBottomReserve: CGFloat = 158

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            RoomPlanScannerView(store: store, finishRevision: finishRevision) {
                isFinishing = false
                if let layer = store.selectedModelScanLayer,
                   let url = store.modelFileURL(for: layer) {
                    previewModelURL = url
                    isShowingModelPreview = true
                } else {
                    dismiss()
                }
            }
            .id(store.selectedModelScanLayerId)
            .padding(.bottom, scannerBottomReserve)
            .ignoresSafeArea(edges: [.top, .horizontal])

            VStack(spacing: 0) {
                scanGuide
                Spacer()
                bottomControls
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 24)

            if isShowingModelPreview, let previewModelURL {
                RoomPlanModelPreview(url: previewModelURL) {
                    dismiss()
                }
                .transition(.opacity)
            }
        }
        .background(Color.black)
    }

    private var scanGuide: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(store.selectedModelScanLayer?.name ?? "当前层空间扫描")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text("缓慢绕空间一圈，先扫地面，再扫墙面、门洞、楼梯边界和顶面。避免快速转身。")
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.78))
                }
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(width: 34, height: 34)
                        .background(.black.opacity(0.45))
                        .clipShape(Circle())
                }
            }

            HStack(spacing: 8) {
                guideChip("1", "慢速环绕")
                guideChip("2", "补扫洞口")
                guideChip("3", "覆盖顶/底")
            }
        }
        .padding(12)
        .background(.black.opacity(0.58))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func guideChip(_ number: String, _ title: String) -> some View {
        HStack(spacing: 5) {
            Text(number)
                .font(.caption2.weight(.bold))
                .foregroundStyle(.black)
                .frame(width: 18, height: 18)
                .background(.white)
                .clipShape(Circle())
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 7)
        .background(.white.opacity(0.14))
        .clipShape(Capsule())
    }

    private var bottomControls: some View {
        VStack(spacing: 8) {
            Text("完成当前层后点击下方按钮，系统会生成该层模型并返回项目。")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.8))
                .multilineTextAlignment(.center)

            Button {
                isFinishing = true
                finishRevision += 1
            } label: {
                Label(isFinishing ? "正在生成模型" : "完成当前层扫描", systemImage: isFinishing ? "hourglass" : "checkmark.circle.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isFinishing)
        }
        .padding(12)
        .background(.black.opacity(0.58))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

@available(iOS 17.0, *)
private struct RoomPlanModelPreview: View {
    let url: URL
    var onDone: () -> Void
    @State private var isCentered = false

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 18) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("空间模型预览")
                            .font(.headline)
                            .foregroundStyle(.white)
                        Text("检查模型是否覆盖楼梯洞口、墙面、门洞和顶/底面")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.68))
                    }
                    Spacer()
                    Button {
                        onDone()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(.white.opacity(0.14))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 16)

                Spacer(minLength: 0)

                SceneKitModelPreview(url: url)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                .frame(maxWidth: .infinity)
                .frame(height: 380)
                .scaleEffect(isCentered ? 1 : 0.72)
                .offset(y: isCentered ? 0 : 240)
                .animation(.spring(response: 0.72, dampingFraction: 0.84), value: isCentered)

                Spacer(minLength: 0)

                VStack(spacing: 10) {
                    ShareLink(item: url) {
                        Label("导出模型文件", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(.white)

                    Button {
                        onDone()
                    } label: {
                        Label("确认并返回项目", systemImage: "checkmark.circle.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 28)
            }
        }
        .onAppear {
            isCentered = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                isCentered = true
            }
        }
    }
}

private struct SceneKitModelPreview: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> SCNView {
        let view = SCNView(frame: .zero)
        view.backgroundColor = .black
        view.autoenablesDefaultLighting = false
        view.allowsCameraControl = true
        view.antialiasingMode = .multisampling4X
        view.scene = makeScene()
        return view
    }

    func updateUIView(_ uiView: SCNView, context: Context) {}

    private func makeScene() -> SCNScene {
        let scene = (try? SCNScene(url: url, options: nil)) ?? SCNScene()
        scene.background.contents = UIColor.black
        scene.lightingEnvironment.intensity = 0.34
        scene.fogColor = UIColor.black
        scene.fogStartDistance = 7
        scene.fogEndDistance = 18
        normalizeMaterials(in: scene.rootNode)

        let cameraNode = SCNNode()
        let camera = SCNCamera()
        camera.fieldOfView = 55
        camera.wantsHDR = false
        camera.exposureOffset = -0.1
        camera.minimumExposure = -0.8
        camera.maximumExposure = 0.9
        cameraNode.camera = camera

        let bounds = scene.rootNode.boundingBox
        let minVector = bounds.min
        let maxVector = bounds.max
        let center = SCNVector3(
            (minVector.x + maxVector.x) / 2,
            (minVector.y + maxVector.y) / 2,
            (minVector.z + maxVector.z) / 2
        )
        let span = Swift.max(maxVector.x - minVector.x, Swift.max(maxVector.y - minVector.y, maxVector.z - minVector.z))
        let distance = Swift.max(span * 1.8, 2)
        cameraNode.position = SCNVector3(center.x, center.y + span * 0.25, center.z + distance)
        cameraNode.look(at: center)
        scene.rootNode.addChildNode(cameraNode)

        let keyLightNode = SCNNode()
        let keyLight = SCNLight()
        keyLight.type = .directional
        keyLight.intensity = 680
        keyLight.castsShadow = true
        keyLight.shadowMode = .deferred
        keyLight.shadowColor = UIColor.black.withAlphaComponent(0.22)
        keyLightNode.light = keyLight
        keyLightNode.eulerAngles = SCNVector3(-Float.pi / 3, Float.pi / 5, 0)
        scene.rootNode.addChildNode(keyLightNode)

        let fillLightNode = SCNNode()
        let fillLight = SCNLight()
        fillLight.type = .ambient
        fillLight.color = UIColor(white: 0.82, alpha: 1)
        fillLight.intensity = 280
        fillLightNode.light = fillLight
        scene.rootNode.addChildNode(fillLightNode)

        return scene
    }

    private func normalizeMaterials(in node: SCNNode) {
        node.geometry?.materials.forEach { material in
            material.lightingModel = .lambert
            material.diffuse.contents = UIColor(white: 0.82, alpha: 1)
            material.emission.contents = UIColor.black
            material.selfIllumination.contents = UIColor.black
            material.specular.contents = UIColor(white: 0.22, alpha: 1)
            material.shininess = 0.08
            material.isDoubleSided = true
        }

        node.childNodes.forEach { normalizeMaterials(in: $0) }
    }
}

struct ModelPreviewLayer: Identifiable {
    let id: UUID
    let name: String
    let url: URL
    let estimatedHeight: Double?
}

struct CombinedRoomPlanModelPreview: View {
    let layers: [ModelPreviewLayer]
    var onDone: () -> Void
    @State private var isCentered = false

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("整体模型预览")
                            .font(.headline)
                            .foregroundStyle(.white)
                        Text("已按楼层顺序叠放 \(layers.count) 个扫描模型，可旋转检查上下层关系")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.72))
                    }
                    Spacer()
                    Button {
                        onDone()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(.white.opacity(0.14))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 16)

                CombinedSceneKitModelPreview(layers: layers)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .frame(maxWidth: .infinity)
                    .frame(height: 470)
                    .scaleEffect(isCentered ? 1 : 0.82)
                    .offset(y: isCentered ? 0 : 220)
                    .animation(.spring(response: 0.72, dampingFraction: 0.84), value: isCentered)

                VStack(alignment: .leading, spacing: 8) {
                    ForEach(layers) { layer in
                        HStack {
                            Image(systemName: "cube.box.fill")
                            Text(layer.name)
                            Spacer()
                            Text(layer.estimatedHeight.map { "层高 \(Int($0)) mm" } ?? "按默认层高叠放")
                                .foregroundStyle(.white.opacity(0.62))
                        }
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                    }
                }
                .padding(.horizontal, 18)

                Button {
                    onDone()
                } label: {
                    Label("返回空间建模", systemImage: "checkmark.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal, 18)
                .padding(.bottom, 24)
            }
        }
        .onAppear {
            isCentered = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                isCentered = true
            }
        }
    }
}

private struct CombinedSceneKitModelPreview: UIViewRepresentable {
    let layers: [ModelPreviewLayer]

    func makeUIView(context: Context) -> SCNView {
        let view = SCNView(frame: .zero)
        view.backgroundColor = .black
        view.autoenablesDefaultLighting = false
        view.allowsCameraControl = true
        view.antialiasingMode = .multisampling4X
        view.scene = makeScene()
        return view
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        uiView.scene = makeScene()
    }

    private func makeScene() -> SCNScene {
        let scene = SCNScene()
        scene.background.contents = UIColor.black
        scene.lightingEnvironment.intensity = 0.42

        var yOffset: Float = 0
        for (index, layer) in layers.enumerated() {
            guard let layerScene = try? SCNScene(url: layer.url, options: nil) else { continue }
            normalizeMaterials(in: layerScene.rootNode, index: index)

            let wrapper = SCNNode()
            for child in layerScene.rootNode.childNodes {
                wrapper.addChildNode(child.clone())
            }

            let bounds = wrapper.boundingBox
            let center = centerPoint(min: bounds.min, max: bounds.max)
            let height = max(bounds.max.y - bounds.min.y, 0.2)
            wrapper.position = SCNVector3(-center.x, yOffset - bounds.min.y, -center.z)
            scene.rootNode.addChildNode(wrapper)

            let label = makeLayerLabel(layer.name)
            label.position = SCNVector3(1.35, yOffset + height * 0.5, 0)
            scene.rootNode.addChildNode(label)

            let measuredStep = Float((layer.estimatedHeight ?? 0) / 1000)
            yOffset += max(measuredStep, height, 2.7)
        }

        addCameraAndLights(to: scene)
        return scene
    }

    private func makeLayerLabel(_ text: String) -> SCNNode {
        let geometry = SCNText(string: text, extrusionDepth: 0.01)
        geometry.font = UIFont.systemFont(ofSize: 0.16, weight: .semibold)
        geometry.firstMaterial?.diffuse.contents = UIColor.white
        geometry.firstMaterial?.emission.contents = UIColor.white.withAlphaComponent(0.25)
        let node = SCNNode(geometry: geometry)
        node.scale = SCNVector3(1, 1, 1)
        return node
    }

    private func addCameraAndLights(to scene: SCNScene) {
        let bounds = scene.rootNode.boundingBox
        let center = centerPoint(min: bounds.min, max: bounds.max)
        let span = max(
            bounds.max.x - bounds.min.x,
            max(bounds.max.y - bounds.min.y, bounds.max.z - bounds.min.z)
        )
        let distance = max(span * 1.45, 4)

        let cameraNode = SCNNode()
        let camera = SCNCamera()
        camera.fieldOfView = 52
        camera.wantsHDR = false
        camera.exposureOffset = 0.05
        camera.minimumExposure = -0.5
        camera.maximumExposure = 1
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(center.x + span * 0.2, center.y + span * 0.18, center.z + distance)
        cameraNode.look(at: center)
        scene.rootNode.addChildNode(cameraNode)

        let keyLightNode = SCNNode()
        let keyLight = SCNLight()
        keyLight.type = .directional
        keyLight.intensity = 760
        keyLight.castsShadow = true
        keyLight.shadowColor = UIColor.black.withAlphaComponent(0.18)
        keyLightNode.light = keyLight
        keyLightNode.eulerAngles = SCNVector3(-Float.pi / 3, Float.pi / 5, 0)
        scene.rootNode.addChildNode(keyLightNode)

        let fillLightNode = SCNNode()
        let fillLight = SCNLight()
        fillLight.type = .ambient
        fillLight.color = UIColor(white: 0.86, alpha: 1)
        fillLight.intensity = 320
        fillLightNode.light = fillLight
        scene.rootNode.addChildNode(fillLightNode)
    }

    private func centerPoint(min: SCNVector3, max: SCNVector3) -> SCNVector3 {
        SCNVector3((min.x + max.x) / 2, (min.y + max.y) / 2, (min.z + max.z) / 2)
    }

    private func normalizeMaterials(in node: SCNNode, index: Int) {
        let palette = [
            UIColor(red: 0.78, green: 0.86, blue: 0.98, alpha: 1),
            UIColor(red: 0.82, green: 0.92, blue: 0.84, alpha: 1),
            UIColor(red: 0.98, green: 0.88, blue: 0.72, alpha: 1),
            UIColor(red: 0.90, green: 0.84, blue: 0.98, alpha: 1)
        ]
        let color = palette[index % palette.count]

        node.geometry?.materials.forEach { material in
            material.lightingModel = .lambert
            material.diffuse.contents = color
            material.emission.contents = UIColor.black
            material.selfIllumination.contents = UIColor.black
            material.specular.contents = UIColor(white: 0.2, alpha: 1)
            material.shininess = 0.08
            material.isDoubleSided = true
        }

        node.childNodes.forEach { normalizeMaterials(in: $0, index: index) }
    }
}

@available(iOS 16.0, *)
struct RoomPlanScannerView: UIViewRepresentable {
    @ObservedObject var store: SurveyStore
    var finishRevision: Int
    var onFinished: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(store: store, onFinished: onFinished)
    }

    func makeUIView(context: Context) -> RoomCaptureView {
        let view = RoomCaptureView(frame: .zero)
        view.backgroundColor = .black
        view.isOpaque = true
        view.alpha = 1
        view.isModelEnabled = true
        view.captureSession.delegate = context.coordinator
        view.delegate = context.coordinator
        context.coordinator.lastFinishRevision = finishRevision
        view.captureSession.run(configuration: RoomCaptureSession.Configuration())
        return view
    }

    func updateUIView(_ uiView: RoomCaptureView, context: Context) {
        if context.coordinator.lastFinishRevision != finishRevision {
            context.coordinator.lastFinishRevision = finishRevision
            context.coordinator.finishScan(in: uiView)
        }
    }

    static func dismantleUIView(_ uiView: RoomCaptureView, coordinator: Coordinator) {
        uiView.captureSession.stop()
    }

    @objc(LidarRoomPlanCoordinator)
    final class Coordinator: NSObject, RoomCaptureSessionDelegate, RoomCaptureViewDelegate {
        private var store: SurveyStore!
        private var onFinished: () -> Void
        private let roomBuilder = RoomBuilder(options: [])
        private var isFinishing = false
        var lastFinishRevision = 0

        init(store: SurveyStore, onFinished: @escaping () -> Void) {
            self.store = store
            self.onFinished = onFinished
            super.init()
        }

        required init?(coder: NSCoder) {
            self.onFinished = {}
            super.init()
        }

        func encode(with coder: NSCoder) {
            // RoomCaptureViewDelegate inherits NSCoding in the current SDK.
            // This coordinator is runtime-only and does not persist state.
        }

        func captureSession(_ session: RoomCaptureSession, didStartWith configuration: RoomCaptureSession.Configuration) {
            store.scanStatus = "RoomPlan 空间建模已开始"
        }

        func captureSession(_ session: RoomCaptureSession, didEndWith data: CapturedRoomData, error: Error?) {
            if let error {
                store.scanStatus = "RoomPlan 建模结束，存在错误：\(error.localizedDescription)"
                isFinishing = false
                onFinished()
            } else {
                store.scanStatus = "RoomPlan 已完成采集，正在生成模型"
                buildAndSaveRoom(from: data)
            }
        }

        func captureView(shouldPresent roomDataForProcessing: CapturedRoomData, error: Error?) -> Bool {
            false
        }

        func captureView(didPresent processedResult: CapturedRoom, error: Error?) {
            if let error {
                store.scanStatus = "RoomPlan 模型生成失败：\(error.localizedDescription)"
                return
            }

            save(processedResult)
        }

        func finishScan(in view: RoomCaptureView) {
            guard !isFinishing else { return }
            isFinishing = true
            store.scanStatus = "正在结束 RoomPlan 扫描并生成模型"
            if #available(iOS 17.0, *) {
                view.captureSession.stop(pauseARSession: true)
            } else {
                view.captureSession.stop()
            }
        }

        private func buildAndSaveRoom(from data: CapturedRoomData) {
            Task { @MainActor in
                do {
                    let room = try await roomBuilder.capturedRoom(from: data)
                    save(room)
                    isFinishing = false
                    onFinished()
                } catch {
                    store.scanStatus = "RoomPlan 模型生成失败：\(error.localizedDescription)"
                    isFinishing = false
                    onFinished()
                }
            }
        }

        private func save(_ processedResult: CapturedRoom) {
            let wallCount = processedResult.walls.count
            let openingCount = processedResult.openings.count + processedResult.doors.count + processedResult.windows.count
            let objectCount = processedResult.objects.count
            let allSurfaces = processedResult.walls + processedResult.openings + processedResult.doors + processedResult.windows
            let widths = allSurfaces.map { Double($0.dimensions.x * 1000) }
            let heights = allSurfaces.map { Double($0.dimensions.y * 1000) }
            let depths = processedResult.objects.map { Double($0.dimensions.z * 1000) }
            let features = makeFeatures(from: processedResult)
            let filenames = export(processedResult)

            store.applyRoomPlanSummary(
                wallCount: wallCount,
                openingCount: openingCount,
                objectCount: objectCount,
                estimatedWidth: widths.max(),
                estimatedDepth: depths.max(),
                estimatedHeight: heights.max(),
                modelFileName: filenames.modelFileName,
                metadataFileName: filenames.metadataFileName,
                features: features
            )
        }

        private func export(_ room: CapturedRoom) -> (modelFileName: String?, metadataFileName: String?) {
            let directory = SurveyStore.modelStorageDirectory()
            let layerPrefix = (store.selectedModelScanLayer?.name ?? "roomplan")
                .replacingOccurrences(of: "/", with: "-")
                .replacingOccurrences(of: " ", with: "-")
            let stamp = Int(Date().timeIntervalSince1970)
            let modelFileName = "\(layerPrefix)-\(stamp).usdz"
            let metadataFileName = "\(layerPrefix)-\(stamp).json"
            let modelURL = directory.appendingPathComponent(modelFileName)
            let metadataURL = directory.appendingPathComponent(metadataFileName)

            do {
                if #available(iOS 17.0, *) {
                    try room.export(to: modelURL, metadataURL: metadataURL, exportOptions: .mesh)
                } else {
                    try room.export(to: modelURL, exportOptions: .mesh)
                    let data = try JSONEncoder().encode(room)
                    try data.write(to: metadataURL)
                }
                return (modelFileName, metadataFileName)
            } catch {
                store.scanStatus = "模型已生成，但文件导出失败：\(error.localizedDescription)"
                return (nil, nil)
            }
        }

        private func makeFeatures(from room: CapturedRoom) -> [ModelScanFeature] {
            var features: [ModelScanFeature] = []
            features.append(contentsOf: room.walls.enumerated().map { index, surface in
                feature(from: surface, category: "墙面", label: "墙面 \(index + 1)")
            })
            features.append(contentsOf: room.openings.enumerated().map { index, surface in
                feature(from: surface, category: "洞口", label: "洞口 \(index + 1)")
            })
            features.append(contentsOf: room.doors.enumerated().map { index, surface in
                feature(from: surface, category: "门洞", label: "门洞 \(index + 1)")
            })
            features.append(contentsOf: room.windows.enumerated().map { index, surface in
                feature(from: surface, category: "窗洞", label: "窗洞 \(index + 1)")
            })
            if #available(iOS 17.0, *) {
                features.append(contentsOf: room.floors.enumerated().map { index, surface in
                    feature(from: surface, category: "地面", label: "地面 \(index + 1)")
                })
            }
            features.append(contentsOf: room.objects.prefix(12).enumerated().map { index, object in
                ModelScanFeature(
                    sourceId: object.identifier,
                    category: "物体",
                    label: "物体 \(index + 1)",
                    width: Double(object.dimensions.x * 1000),
                    depth: Double(object.dimensions.z * 1000),
                    height: Double(object.dimensions.y * 1000),
                    confidence: "\(object.confidence)"
                )
            })
            return features
        }

        private func feature(from surface: CapturedRoom.Surface, category: String, label: String) -> ModelScanFeature {
            ModelScanFeature(
                sourceId: surface.identifier,
                category: category,
                label: label,
                width: Double(surface.dimensions.x * 1000),
                depth: Double(surface.dimensions.z * 1000),
                height: Double(surface.dimensions.y * 1000),
                confidence: "\(surface.confidence)"
            )
        }
    }
}
