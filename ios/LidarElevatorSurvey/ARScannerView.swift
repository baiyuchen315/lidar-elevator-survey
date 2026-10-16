import ARKit
import Photos
import RealityKit
import SwiftUI

struct ARScannerView: UIViewRepresentable {
    @ObservedObject var store: SurveyStore

    func makeCoordinator() -> Coordinator {
        Coordinator(store: store)
    }

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        arView.automaticallyConfigureSession = false
        context.coordinator.arView = arView
        arView.session.delegate = context.coordinator
        addCenterReticle(to: arView)

        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        arView.addGestureRecognizer(tap)

        let config = makeWorldTrackingConfiguration()
        if config.sceneReconstruction == .mesh {
            store.scanStatus = "LiDAR 网格扫描已开启"
        } else {
            store.scanStatus = "当前设备不支持 LiDAR 网格，已启用普通 AR 测量"
        }

        arView.session.run(config)
        return arView
    }

    private func makeWorldTrackingConfiguration() -> ARWorldTrackingConfiguration {
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal, .vertical]
        config.environmentTexturing = .automatic
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            config.sceneReconstruction = .mesh
        }
        return config
    }

    private func addCenterReticle(to arView: ARView) {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.isUserInteractionEnabled = false
        container.backgroundColor = UIColor.black.withAlphaComponent(0.2)
        container.layer.cornerRadius = 20
        container.layer.borderColor = UIColor.white.withAlphaComponent(0.9).cgColor
        container.layer.borderWidth = 1

        let horizontal = UIView()
        horizontal.translatesAutoresizingMaskIntoConstraints = false
        horizontal.backgroundColor = .white

        let vertical = UIView()
        vertical.translatesAutoresizingMaskIntoConstraints = false
        vertical.backgroundColor = .white

        arView.addSubview(container)
        container.addSubview(horizontal)
        container.addSubview(vertical)

        NSLayoutConstraint.activate([
            container.centerXAnchor.constraint(equalTo: arView.centerXAnchor),
            container.centerYAnchor.constraint(equalTo: arView.centerYAnchor),
            container.widthAnchor.constraint(equalToConstant: 40),
            container.heightAnchor.constraint(equalToConstant: 40),

            horizontal.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            horizontal.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            horizontal.widthAnchor.constraint(equalToConstant: 24),
            horizontal.heightAnchor.constraint(equalToConstant: 2),

            vertical.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            vertical.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            vertical.widthAnchor.constraint(equalToConstant: 2),
            vertical.heightAnchor.constraint(equalToConstant: 24)
        ])
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        if context.coordinator.lastVisualResetRevision != store.visualResetRevision {
            context.coordinator.lastVisualResetRevision = store.visualResetRevision
            if let name = store.visualResetMeasurementName {
                context.coordinator.clearVisuals(for: name, in: uiView)
            }
        }

        if context.coordinator.lastPhotoCaptureRevision != store.photoCaptureRevision {
            context.coordinator.lastPhotoCaptureRevision = store.photoCaptureRevision
            context.coordinator.captureMeasurementEvidence(in: uiView)
        }

        if store.isRoomPlanScannerPresented {
            if !context.coordinator.isPausedForRoomPlan {
                uiView.isHidden = true
                uiView.session.pause()
                context.coordinator.isPausedForRoomPlan = true
            }
        } else if context.coordinator.isPausedForRoomPlan {
            uiView.isHidden = false
            uiView.session.run(makeWorldTrackingConfiguration())
            context.coordinator.isPausedForRoomPlan = false
        }
    }

    static func dismantleUIView(_ uiView: ARView, coordinator: Coordinator) {
        uiView.session.pause()
    }

    final class Coordinator: NSObject, ARSessionDelegate {
        weak var arView: ARView?
        private let store: SurveyStore
        private var selectedPoints: [SIMD3<Float>] = []
        private var horizontalPlaneExtents: [SIMD2<Float>] = []
        private var verticalPlaneExtents: [SIMD2<Float>] = []
        private var minPlaneY: Float?
        private var maxPlaneY: Float?
        private var measurementLabels: [(measurementName: String, position: SIMD3<Float>, label: UILabel)] = []
        private var measurementAnchors: [String: [AnchorEntity]] = [:]
        private var reusablePoints: [(measurementName: String, position: SIMD3<Float>)] = []
        var lastVisualResetRevision = 0
        var lastPhotoCaptureRevision = 0
        var isPausedForRoomPlan = false

        init(store: SurveyStore) {
            self.store = store
        }

        @objc func handleTap(_ recognizer: UITapGestureRecognizer) {
            guard let arView else { return }
            guard store.isMeasuringCurrentItem else {
                selectedPoints.removeAll()
                store.updateSelectedPointCount(0)
                store.scanStatus = "请先点击“开始测量该项”"
                return
            }
            let location = recognizer.location(in: arView)
            let result = arView.raycast(from: location, allowing: .existingPlaneGeometry, alignment: .any).first
                ?? arView.raycast(from: location, allowing: .estimatedPlane, alignment: .any).first
            guard let result else {
                store.scanStatus = "未识别到可测量平面"
                return
            }

            let raycastPoint = SIMD3<Float>(
                result.worldTransform.columns.3.x,
                result.worldTransform.columns.3.y,
                result.worldTransform.columns.3.z
            )
            let snapped = snappedPoint(near: location, fallback: raycastPoint, in: arView)
            let point = snapped.position
            let measurementName = store.selectedMeasurementName
            selectedPoints.append(point)
            addMarker(at: point, measurementName: measurementName, in: arView)
            store.updateSelectedPointCount(selectedPoints.count)
            if let snapMessage = snapped.message, selectedPoints.count < 2 {
                store.scanStatus = "\(snapMessage)，请继续点选第 2 个点"
            }

            if selectedPoints.count == 2 {
                let distance = simd_distance(selectedPoints[0], selectedPoints[1])
                store.updatePointDistance(distance)
                addLine(from: selectedPoints[0], to: selectedPoints[1], measurementName: measurementName, in: arView)
                addMeasurementLabel(from: selectedPoints[0], to: selectedPoints[1], measurementName: measurementName, distance: distance, in: arView)
                selectedPoints.removeAll()
                store.updateSelectedPointCount(0)
            }
        }

        func clearVisuals(for measurementName: String, in arView: ARView) {
            selectedPoints.removeAll()
            store.updateSelectedPointCount(0)

            for anchor in measurementAnchors[measurementName] ?? [] {
                arView.scene.removeAnchor(anchor)
            }
            measurementAnchors[measurementName] = []

            measurementLabels.removeAll { item in
                if item.measurementName == measurementName {
                    item.label.removeFromSuperview()
                    return true
                }
                return false
            }

            reusablePoints.removeAll { $0.measurementName == measurementName }
        }

        private func register(_ anchor: AnchorEntity, for measurementName: String) {
            measurementAnchors[measurementName, default: []].append(anchor)
        }

        private func addMarker(at point: SIMD3<Float>, measurementName: String, in arView: ARView) {
            reusablePoints.append((measurementName: measurementName, position: point))

            let markerColor = UIColor.white
            let sphereMesh = MeshResource.generateSphere(radius: 0.011)
            let sphereMaterial = SimpleMaterial(color: markerColor.withAlphaComponent(0.36), isMetallic: false)
            let sphere = ModelEntity(mesh: sphereMesh, materials: [sphereMaterial])
            sphere.position = .zero

            let haloMesh = MeshResource.generateSphere(radius: 0.019)
            let haloMaterial = SimpleMaterial(color: UIColor.systemBlue.withAlphaComponent(0.16), isMetallic: false)
            let halo = ModelEntity(mesh: haloMesh, materials: [haloMaterial])
            halo.position = .zero

            let anchor = AnchorEntity(world: point)
            anchor.addChild(halo)
            anchor.addChild(sphere)
            arView.scene.addAnchor(anchor)
            register(anchor, for: measurementName)
        }

        private func addLine(from start: SIMD3<Float>, to end: SIMD3<Float>, measurementName: String, in arView: ARView) {
            let vector = end - start
            let length = simd_length(vector)
            guard length > 0.001 else { return }

            let direction = simd_normalize(vector)
            let mesh: MeshResource
            let baseAxis: SIMD3<Float>
            if #available(iOS 18.0, *) {
                mesh = MeshResource.generateCylinder(height: length, radius: 0.0045)
                baseAxis = SIMD3<Float>(0, 1, 0)
            } else {
                mesh = MeshResource.generateBox(size: [0.008, 0.008, length])
                baseAxis = SIMD3<Float>(0, 0, 1)
            }
            let material = SimpleMaterial(color: UIColor.systemBlue.withAlphaComponent(0.42), isMetallic: false)
            let entity = ModelEntity(mesh: mesh, materials: [material])
            entity.position = .zero
            entity.orientation = simd_quatf(from: baseAxis, to: direction)
            let anchor = AnchorEntity(world: (start + end) / 2)
            anchor.addChild(entity)
            arView.scene.addAnchor(anchor)
            register(anchor, for: measurementName)
        }

        private struct SnapResult {
            var position: SIMD3<Float>
            var message: String?
        }

        private func snappedPoint(near screenPoint: CGPoint, fallback: SIMD3<Float>, in arView: ARView) -> SnapResult {
            if let reusable = reusablePoint(near: screenPoint, fallback: fallback, in: arView) {
                return SnapResult(position: reusable, message: "已复用附近基准点")
            }
            if let edgePoint = planeBoundarySnapPoint(near: fallback, in: arView) {
                return SnapResult(position: edgePoint, message: "已吸附到识别边缘")
            }
            return SnapResult(position: fallback, message: nil)
        }

        private func reusablePoint(near screenPoint: CGPoint, fallback: SIMD3<Float>, in arView: ARView) -> SIMD3<Float>? {
            let candidates = reusablePoints.compactMap { item -> (position: SIMD3<Float>, screenDistance: CGFloat, worldDistance: Float)? in
                guard let projected = arView.project(item.position) else { return nil }
                let dx = projected.x - screenPoint.x
                let dy = projected.y - screenPoint.y
                return (item.position, hypot(dx, dy), simd_distance(item.position, fallback))
            }

            if let nearest = candidates
                .filter({ $0.screenDistance <= 34 || $0.worldDistance <= 0.045 })
                .min(by: { lhs, rhs in
                    if lhs.screenDistance == rhs.screenDistance {
                        return lhs.worldDistance < rhs.worldDistance
                    }
                    return lhs.screenDistance < rhs.screenDistance
                }) {
                return nearest.position
            }

            return nil
        }

        private func planeBoundarySnapPoint(near fallback: SIMD3<Float>, in arView: ARView) -> SIMD3<Float>? {
            let snapThreshold: Float = 0.07
            let anchors = arView.session.currentFrame?.anchors.compactMap { $0 as? ARPlaneAnchor } ?? []

            var best: (point: SIMD3<Float>, distance: Float)?
            for anchor in anchors {
                let extent = anchor.planeExtent
                guard extent.width > 0.08, extent.height > 0.08 else { continue }

                let inverse = simd_inverse(anchor.transform)
                let local4 = inverse * SIMD4<Float>(fallback.x, fallback.y, fallback.z, 1)
                var local = SIMD3<Float>(local4.x, local4.y, local4.z)
                let halfWidth = extent.width / 2
                let halfHeight = extent.height / 2

                let candidate: (point: SIMD3<Float>, distance: Float)?
                if anchor.alignment == .horizontal {
                    candidate = snapLocalPoint(&local, halfPrimary: halfWidth, halfSecondary: halfHeight, useYForSecondary: false, threshold: snapThreshold)
                } else if anchor.alignment == .vertical {
                    candidate = snapLocalPoint(&local, halfPrimary: halfWidth, halfSecondary: halfHeight, useYForSecondary: true, threshold: snapThreshold)
                } else {
                    candidate = nil
                }

                guard let candidate else { continue }
                let world4 = anchor.transform * SIMD4<Float>(candidate.point.x, candidate.point.y, candidate.point.z, 1)
                let world = SIMD3<Float>(world4.x, world4.y, world4.z)
                if best == nil || candidate.distance < best!.distance {
                    best = (world, candidate.distance)
                }
            }

            return best?.point
        }

        private func snapLocalPoint(
            _ local: inout SIMD3<Float>,
            halfPrimary: Float,
            halfSecondary: Float,
            useYForSecondary: Bool,
            threshold: Float
        ) -> (point: SIMD3<Float>, distance: Float)? {
            let secondaryValue = useYForSecondary ? local.y : local.z
            guard abs(local.x) <= halfPrimary + threshold,
                  abs(secondaryValue) <= halfSecondary + threshold else {
                return nil
            }

            let primaryDistance = abs(halfPrimary - abs(local.x))
            let secondaryDistance = abs(halfSecondary - abs(secondaryValue))
            guard min(primaryDistance, secondaryDistance) <= threshold else { return nil }

            if primaryDistance <= secondaryDistance {
                local.x = local.x >= 0 ? halfPrimary : -halfPrimary
                return (local, primaryDistance)
            }

            if useYForSecondary {
                local.y = local.y >= 0 ? halfSecondary : -halfSecondary
            } else {
                local.z = local.z >= 0 ? halfSecondary : -halfSecondary
            }
            return (local, secondaryDistance)
        }

        private func addMeasurementLabel(from start: SIMD3<Float>, to end: SIMD3<Float>, measurementName: String, distance: Float, in arView: ARView) {
            let midpoint = (start + end) / 2
            let millimeters = Int(distance * 1000)
            let title = measurementName
            let label = UILabel()
            label.numberOfLines = 2
            label.textAlignment = .center
            label.backgroundColor = UIColor.black.withAlphaComponent(0.68)
            label.layer.cornerRadius = 8
            label.layer.masksToBounds = true
            label.layer.borderWidth = 1
            label.layer.borderColor = UIColor.white.withAlphaComponent(0.18).cgColor

            let text = NSMutableAttributedString(
                string: "\(title)\n",
                attributes: [
                    .font: UIFont.systemFont(ofSize: 13, weight: .semibold),
                    .foregroundColor: UIColor.white
                ]
            )
            text.append(NSAttributedString(
                string: "\(millimeters) mm",
                attributes: [
                    .font: UIFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium),
                    .foregroundColor: UIColor.white.withAlphaComponent(0.86)
                ]
            ))
            label.attributedText = text
            label.frame.size = CGSize(width: max(128, min(190, label.intrinsicContentSize.width + 20)), height: 44)
            label.isUserInteractionEnabled = false
            arView.addSubview(label)

            let labelPosition = midpoint + SIMD3<Float>(0, 0.045, 0)
            measurementLabels.append((measurementName: measurementName, position: labelPosition, label: label))
            if measurementLabels.count > 24 {
                let removed = measurementLabels.removeFirst()
                removed.label.removeFromSuperview()
            }
            updateScreenLabels(in: arView)
        }

        func captureMeasurementEvidence(in arView: ARView) {
            let measurementName = store.selectedMeasurementName
            arView.snapshot(saveToHDR: false) { image in
                DispatchQueue.main.async {
                    guard let image else {
                        self.store.scanStatus = "测量照片保存失败，请稍后重试"
                        return
                    }
                    let finalImage = self.renderEvidenceImage(baseImage: image, in: arView)
                    guard let data = finalImage.jpegData(compressionQuality: 0.92) else {
                        self.store.scanStatus = "测量照片编码失败"
                        return
                    }

                    let safeName = measurementName
                        .replacingOccurrences(of: "/", with: "-")
                        .replacingOccurrences(of: " ", with: "-")
                    let fileName = "\(safeName)-\(Int(Date().timeIntervalSince1970)).jpg"
                    let url = SurveyStore.measurementPhotoDirectory().appendingPathComponent(fileName)
                    do {
                        try data.write(to: url)
                        self.store.applyMeasurementPhoto(fileName: fileName, measurementName: measurementName)
                        self.saveToPhotoLibrary(finalImage, measurementName: measurementName)
                    } catch {
                        self.store.scanStatus = "测量照片写入失败：\(error.localizedDescription)"
                    }
                }
            }
        }

        private func saveToPhotoLibrary(_ image: UIImage, measurementName: String) {
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
                guard status == .authorized || status == .limited else {
                    DispatchQueue.main.async {
                        self.store.scanStatus = "已保存到App内，未获得系统相册写入权限"
                    }
                    return
                }

                PHPhotoLibrary.shared().performChanges {
                    PHAssetChangeRequest.creationRequestForAsset(from: image)
                } completionHandler: { success, error in
                    DispatchQueue.main.async {
                        if success {
                            self.store.scanStatus = "已保存 \(measurementName) 测量照片到系统相册"
                        } else if let error {
                            self.store.scanStatus = "App内已保存，相册写入失败：\(error.localizedDescription)"
                        }
                    }
                }
            }
        }

        private func renderEvidenceImage(baseImage: UIImage, in arView: ARView) -> UIImage {
            let format = UIGraphicsImageRendererFormat()
            format.scale = UIScreen.main.scale
            format.opaque = true
            let renderer = UIGraphicsImageRenderer(size: arView.bounds.size, format: format)
            return renderer.image { _ in
                baseImage.draw(in: arView.bounds)
                for label in measurementLabels.map(\.label) where !label.isHidden {
                    label.drawHierarchy(in: label.frame, afterScreenUpdates: true)
                }
            }
        }

        func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
            updateAnchorCounts(session: session)
        }

        func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
            updateAnchorCounts(session: session)
        }

        func session(_ session: ARSession, didUpdate frame: ARFrame) {
            DispatchQueue.main.async {
                guard let arView = self.arView else { return }
                self.updateScreenLabels(in: arView)
            }
        }

        private func updateScreenLabels(in arView: ARView) {
            for item in measurementLabels {
                if let point = arView.project(item.position) {
                    item.label.isHidden = false
                    item.label.center = CGPoint(x: point.x, y: point.y - 34)
                } else {
                    item.label.isHidden = true
                }
            }
        }

        private func updateAnchorCounts(session: ARSession) {
            let anchors = session.currentFrame?.anchors ?? []
            let meshCount = anchors.compactMap { $0 as? ARMeshAnchor }.count
            let planeAnchors = anchors.compactMap { $0 as? ARPlaneAnchor }
            let planeCount = planeAnchors.count
            let horizontalCalibrated = planeAnchors.contains { anchor in
                anchor.alignment == .horizontal && anchor.planeExtent.width * anchor.planeExtent.height > 0.12
            }
            updatePlaneEstimates(planeAnchors)
            DispatchQueue.main.async {
                self.store.updateTracking(meshAnchors: meshCount, planeAnchors: planeCount, horizontalCalibrated: horizontalCalibrated)
            }
        }

        private func updatePlaneEstimates(_ planeAnchors: [ARPlaneAnchor]) {
            horizontalPlaneExtents = []
            verticalPlaneExtents = []
            minPlaneY = nil
            maxPlaneY = nil

            for anchor in planeAnchors {
                let extent = SIMD2<Float>(anchor.planeExtent.width, anchor.planeExtent.height)
                let y = anchor.transform.columns.3.y
                if anchor.alignment == .horizontal {
                    horizontalPlaneExtents.append(extent)
                    minPlaneY = min(minPlaneY ?? y, y)
                    maxPlaneY = max(maxPlaneY ?? y, y)
                } else if anchor.alignment == .vertical {
                    verticalPlaneExtents.append(extent)
                }
            }

            let width = horizontalPlaneExtents.map(\.x).max().map { Double($0 * 1000) }
            let depth = horizontalPlaneExtents.map(\.y).max().map { Double($0 * 1000) }
            var height: Double?
            if let minPlaneY, let maxPlaneY, maxPlaneY > minPlaneY {
                height = Double((maxPlaneY - minPlaneY) * 1000)
            } else if let verticalHeight = verticalPlaneExtents.map(\.y).max() {
                height = Double(verticalHeight * 1000)
            }

            guard width != nil || depth != nil || height != nil else { return }

            DispatchQueue.main.async {
                self.store.applyModelEstimate(width: width, depth: depth, height: height, source: "ARKit 平面模型估算")
            }
        }
    }
}
