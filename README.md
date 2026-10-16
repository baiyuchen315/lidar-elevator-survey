# 别墅梯 LiDAR 勘测

用于别墅电梯旧房改造的现场测量与空间建模原型，包含 iOS App、Web 原型和中英文 Excel 勘测模板。

## 项目内容

- `ios/`：SwiftUI、ARKit、RealityKit 和 RoomPlan iOS 项目。
- `app/`：Web 原型，可通过本地静态服务器预览。
- `outputs/`：Excel 勘测模板与预览图片。
- `scripts/`：模板生成和验证脚本。
- 根目录 Markdown：产品方案与报告字段说明。

## iOS 运行

使用 Xcode 打开 `ios/LidarElevatorSurvey.xcodeproj`，在 Signing & Capabilities 中配置自己的开发团队和 Bundle Identifier，然后连接支持 LiDAR 的真机运行。

App 包括项目管理、逐项测量、自定义测量项、测量照片、分层 RoomPlan 扫描、模型预览及报告数据展示。空间建模默认两层，可添加后续楼层。

整体模型预览目前采用楼层模型居中叠放，尚未实现共同基准点精确配准；扫描与测量数据需要现场复核，拆除与保留示意用于方案讨论。

## Web 原型

在项目根目录运行：

```sh
python3 -m http.server 4173
```

访问 `http://localhost:4173/app/`。

Excel 脚本依赖原开发环境中的运行库和路径，迁移运行环境时需要调整。
