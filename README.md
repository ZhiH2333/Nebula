# Nebula

Nebula 是一个基于 Flutter 构建的移动应用，目前处于早期开发阶段。  
当前版本已完成基础架构搭建，并成功接入 Firebase Firestore 进行 Feed 数据读取。

本项目采用 **阶段式推进**，优先保证「可运行、可验证、可扩展」。

---

## 🚀 当前功能状态

### ✅ 已完成

- Flutter 项目基础结构搭建
- 登录流程（开发阶段占位实现）
- Feed 页面基础骨架
- Post 数据模型（`Post`）
- Feed UI 组件（`PostCard` / `FeedView`）
- Riverpod 状态管理接入
- 异步数据加载（`FutureProvider`）
- Firebase Firestore **只读接入**
- iOS / Android 双端支持

### 🔄 当前数据来源

- Firestore 集合：`posts`
- 首页 Feed 数据从 Firebase 云端读取
- 无 mock 数据、无本地假数据

---

## 🧱 项目结构（核心）

```text
lib/
├── main.dart
├── models/
│   └── post.dart
├── providers/
│   └── posts_provider.dart
├── screens/
│   └── home/
│       ├── home_screen.dart
│       ├── feed_view.dart
│       └── widgets/
│           └── post_card.dart

'''

架构原则：

UI 层不直接访问 Firebase

Provider 层负责数据来源

模型层只做数据结构与解析

🔥 Firebase 状态

已绑定现有 Firebase 项目

使用 flutterfire configure 生成配置

使用以下依赖：

firebase_core

cloud_firestore

Firebase 初始化在 main.dart 中完成

▶️ 本地运行
flutter pub get
flutter run


支持：

Android Emulator / 真机

iOS Simulator / 真机

🧪 验证方式

flutter analyze：通过

登录后可进入首页 Feed

首次进入显示加载状态

成功渲染 Firestore 中的帖子列表

无红屏、无崩溃

📌 开发阶段说明

当前阶段重点是 结构与数据流正确性，暂不关注：

UI 视觉设计

动画与交互细节

写入 / 发布内容

权限与安全规则细化

🛣️ 后续计划（未开始）

Firebase Auth（用户体系）

用户 Profile

Feed 写入 / 发布

评论 / 点赞

UI 设计与主题系统

📝 备注

这是一个学习与实践并行的项目，代码会随着阶段推进持续重构与演进。
