# LidarElevatorSurvey iOS Prototype

这是别墅梯旧房改造 LiDAR 勘测的第一版 iOS 原型。

## 当前能力

- SwiftUI 双页结构：扫描页、报告页
- ARKit + RealityKit 扫描视图
- LiDAR 设备上开启 `sceneReconstruction = .mesh`
- 非 LiDAR 设备降级为普通 AR 点选测距
- 点选两个平面点后计算距离
- 模拟扫描数据写入报告
- 与 Web 原型一致的核心数据结构：
  - 井道尺寸
  - 楼梯洞口尺寸
  - 顶层净空
  - 底坑深度
  - 分层拆除 / 保留记录
  - 风险清单

## 重要限制

- 模拟器不能测试真实 LiDAR。
- 真正的 LiDAR 网格扫描需要 iPhone Pro / iPad Pro 等带 LiDAR 的真机。
- 当前版本还没有自动从点云/网格中识别楼梯、楼板、墙面和门洞，只完成了 ARKit 扫描入口和数据承接结构。
- 当前版本还没有 PDF/Excel 导出，后续可以复用现有 Web/Excel 模板的数据字段。

## 打开方式

用 Xcode 打开：

```sh
open ios/LidarElevatorSurvey.xcodeproj
```

在 Xcode 中：

1. 选择 `LidarElevatorSurvey` target。
2. 在 `Signing & Capabilities` 中选择你的 Team。
3. 修改 Bundle Identifier，例如 `com.yourcompany.LidarElevatorSurvey`。
4. 连接带 LiDAR 的 iPhone。
5. 选择真机运行。

## 本机校验记录

当前机器的 `xcodebuild` 被 Xcode 组件状态阻塞：

- CoreSimulator 版本不匹配。
- Xcode 提示缺少 iOS 26.5 平台组件。

已完成的源码校验：

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcrun --sdk iphoneos swiftc \
  -target arm64-apple-ios17.0 \
  -sdk $(DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun --sdk iphoneos --show-sdk-path) \
  -typecheck ios/LidarElevatorSurvey/*.swift
```

结果：通过。

## 下一步开发建议

1. 在真机上确认相机权限、AR 会话启动和点选测距。
2. 把点选距离保存到指定测量字段，例如井道净宽、井道净深、底坑深度。
3. 增加扫描流程向导：井道、底坑、顶层、层门洞口、楼梯拆除范围。
4. 增加 mesh/plane 处理逻辑：
   - 墙面平面拟合
   - 楼板开孔范围估算
   - 突出物/管线障碍标记
   - 分层拆除区域记录
5. 接入 PDF/Excel 导出。
