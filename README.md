# Nebula

Nebula 是一个基于 Flutter 构建的实验性社交应用项目，当前阶段主要目标是搭建稳定的基础架构，包括用户认证、基础数据模型以及应用整体结构。

本项目采用 **先稳定运行、再逐步扩展功能** 的方式推进开发。

---

## 当前状态（Phase 1）

- Flutter 项目基础结构已完成
- 登录界面与基础 UI 可正常运行
- 用户与帖子等核心数据模型已定义
- Firebase 相关代码已预留，但不作为当前阶段的强依赖
- CI 已配置用于静态分析（`flutter analyze`）

> 说明：  
> 本阶段 **不实现 ActivityPub 联邦通信**，仅在目录结构和数据模型中进行预留，便于后续扩展。

---

## 技术栈

- **Flutter / Dart**
- **Riverpod**（状态管理）
- **Firebase**（计划用于认证与数据存储，尚未强制接入）
- GitHub Actions（基础 CI）

---

## 项目结构

```text
lib/
├── core/           # 路由、主题、常量等基础配置
├── models/         # 数据模型（User / Post）
├── services/       # 服务层（如 AuthService）
├── providers/      # Riverpod 状态管理
├── screens/        # 页面（登录、主页等）
├── widgets/        # 通用 UI 组件
└── activitypub/    # ActivityPub 预留目录（当前为空）
