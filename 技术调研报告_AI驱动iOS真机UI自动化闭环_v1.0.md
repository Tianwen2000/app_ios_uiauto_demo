# AI 驱动 iOS 真机 UI 自动化测试闭环｜技术调研报告（0→1）

- **版本**：v1.1  
- **日期**：2026-03-20（Asia/Shanghai）  
- **适用项目**：Flutter（iOS）/ Swift（iOS 原生）  
- **目标读者**：QA / iOS / Flutter / 测试平台同学  

---

## 1. 背景与现状问题

目前测试工作主要依赖手动操作，带来以下核心痛点：

1. **覆盖面有限**：特定数据组合、边缘输入、异常流容易遗漏  
2. **回归效率低**：改一个模块后，很难快速确认关联模块是否受影响  
3. **UI 与接口割裂**：UI 操作与接口状态无法自动关联，问题发现依赖人工经验  
4. **边缘场景难覆盖**：弱网、前后台切换、权限弹窗、网络切换、异常处理等难以系统化覆盖  

同时团队需要兼顾：

- Flutter iOS 项目
- Swift 原生 iOS 项目

因此需要一套既能在 iOS 生态内长期稳定运行，又能复用统一采集与报告体系的方案。

---

## 2. 调研目标与范围

### 2.1 目标（理想工作流）

搭建一套**一次搭建、可重复使用**的测试环境，使日常流程逐步变为：

- 输入：需求描述、场景范围、回归目标  
- 过程：自动执行 UI 流程并采集证据  
- 输出：报告、截图、错误信息、接口线索与排查建议  

### 2.2 范围（本次调研覆盖）

- iOS UI 自动化执行器选型（Swift / Flutter）  
- 采集体系（日志、截图、失败证据）与统一规范  
- 本地证据目录与导出方式  
- AI 分析与报告生成的落地方式（先规则，后模型）  
- 风险、限制与工作量评估  

### 2.3 不在范围（后续扩展）

- Android 真机自动化  
- 多机并发、设备池、全量用例管理平台  
- 业务代码的全部测试数据治理  

---

## 3. 需求拆解：落地所需能力清单

### 3.1 执行器（Runner）

要求执行器能稳定驱动 iOS 设备完成：

- 点击  
- 输入  
- 滑动  
- 页面切换  
- 基础断言  

并支持命令行执行，便于本地与 CI 统一接入。

### 3.2 采集（Instrumentation）

最小闭环必须统一采集：

- `run_id`
- step 日志
- action 日志
- 截图
- 失败调试信息
- 每条用例结果 JSON

进一步增强项包括：

- 网络日志 JSONL  
- `run_id / step_id / req_id` 串联  
- 接口异常与 UI 截图关联  

### 3.3 产物归档（Reports / Evidence）

执行完成后，需要把结果统一写到本地目录，而不是散落在终端输出中。

当前推荐统一目录：

- `qa/reports/<run_id>/`

### 3.4 分析与报告（Analyzer）

至少需要：

- 规则预检  
- Markdown / HTML 报告  
- 问题汇总  

中长期再考虑：

- AI 语义分析  
- 多轮归因  
- 风险优先级建议  

---

## 4. 执行器选型调研（iOS）

### 4.1 候选方案

- **XCUITest**：Apple 官方 UI 自动化框架  
- **flutter_driver**：Flutter 自带 driver 测试链路  
- **integration_test**：Flutter 官方集成测试方案  
- **Patrol**：增强版 Flutter E2E 方案  
- **Appium**：跨平台 UI 自动化体系  
- **Maestro**：DSL 驱动自动化方案  

### 4.2 核心对比（贴合“日用 + 可落地”）

| 维度 | XCUITest | flutter_driver | integration_test | Patrol | Appium |
|---|---|---|---|---|---|
| iOS 原生一致性 | 高 | 中 | 中 | 中 | 中 |
| 对业务源码侵入 | 中 | 低 | 中 | 中 | 低 |
| Flutter 项目前期接入成本 | 中-高 | 低 | 中 | 中 | 高 |
| 系统级交互能力 | 强 | 一般 | 一般 | 强 | 强 |
| 命令和目录统一难度 | 中 | 低 | 中 | 中 | 高 |
| 当前仓库 POC 验证情况 | 已验证 | 已验证 | 未作为主线验证 | 未作为主线验证 | 未作为主线验证 |

### 4.3 推荐选型结论

更务实的推荐不是“只保留一条路线”，而是按项目类型和当前阶段分层选择：

1. **Swift 原生项目**：优先 `XCUITest`
2. **Flutter 项目，如果目标是低侵入、快速闭环、尽量不改 `lib/` 业务源码**：优先 `flutter_driver`
3. **Flutter 项目，如果后续需要更强系统级交互或更贴近 iOS 原生行为**：再评估 `XCUITest`

### 4.4 当前项目的实际验证结果

当前工作区已经实际验证：

- `XCUITest` 路线：可以跑通 iOS UI 自动化、step 截图、日志、报告闭环  
- `flutter_driver` 路线：可以在不改 `flutter_client_demo/lib/` 的前提下，跑通同等闭环  

因此当前最值得沉淀的不是某一个 demo 页面，而是：

- `qa/` 执行中台  
- `run_id` 约定  
- 日志与截图格式  
- 报告链路  

---

## 5. 推荐技术方案（分层架构）

### 5.1 执行器层

两条主方案：

1. **Swift 项目**
- `XCTest`
- `XCUITest`
- `xcodebuild`

2. **Flutter 项目**
- `flutter_driver`
- `flutter drive`

### 5.2 采集层

不论选哪条路线，统一要求至少记录：

- `run_id`
- `step_id`
- action 日志
- 截图
- 失败调试信息
- 用例结果 JSON

### 5.3 归档层

统一写入：

- `qa/reports/<run_id>/`

目录下建议至少包含：

- `logs/`
- `screens/`
- `report.md`
- `report.html`
- `report_single_file.html`

### 5.4 分析层

优先做：

- 本地规则分析  
- Markdown 报告  
- HTML 报告  

后续再接：

- AI 分析  
- 失败归因  
- 接口异常与 UI 证据联动  

---

## 6. 工程落地方式（仓库结构 + 命令约定）

### 6.1 推荐目录结构（可直接落地）

```text
repo-root/
  qa/
    Makefile
    configs/
    scripts/
    analyzer/
    reports/
  flutter_client_demo/
    lib/
    test/
    test_driver/
      app.dart
      main.dart
      cases/
      pages/
      support/
    ios/
```

如果是 Swift 原生项目，也可落成：

```text
swift_app/
  Sources/
  Tests/
  UITests/
    RunnerUITests.swift
    cases/
    pages/
    support/
```

### 6.2 统一参数文件

推荐统一放在：

- `qa/configs/devices.env`

没有本地文件时，可以自动回退到：

- `qa/configs/devices.example.env`

### 6.3 统一命令约定（建议 Makefile）

- `make -C qa doctor`：检查依赖与设备环境  
- `make -C qa swift-smoke`：Swift / XCUITest 冒烟  
- `make -C qa flutter-it-smoke`：Flutter / flutter_driver 冒烟  
- `make -C qa report`：生成报告  
- `make -C qa all`：doctor → run → report 一键闭环  

---

## 7. POC 方案（用“一条核心流程”跑通全链路）

### 7.1 POC 范围

建议先只选：

- 1 个项目  
- 1 台设备  
- 1 到 2 条核心流程  

推荐最小链路：

- 启动 app  
- 登录  
- 进入首页  
- 搜索或浏览  
- 进入个人页  
- 退出登录  

### 7.2 POC 产出物清单

至少应有：

1. 可执行命令  
2. 可跑通用例  
3. `run_id`  
4. step 日志  
5. action 日志  
6. 截图  
7. 报告  

### 7.3 当前仓库已验证的 POC 结论

当前仓库已经验证：

- `make -C qa flutter-it-smoke report`

可以直接生成：

- `qa/reports/<run_id>/logs/`
- `qa/reports/<run_id>/screens/`
- `qa/reports/<run_id>/report.md`
- `qa/reports/<run_id>/report.html`
- `qa/reports/<run_id>/report_single_file.html`

---

## 8. 数据安全与日志管理（必须提前定规则）

### 8.1 数据安全

建议默认遵守：

- 先脱敏再出端  
- 默认使用测试账号  
- 长响应体做截断或白名单保留  
- 避免把敏感字段直接写入报告  

### 8.2 日志文件管理

建议：

- 每次 run 单独目录  
- 日志按 test_name 拆分  
- 截图按 step 命名  
- 只保留最近 N 次运行  

---

## 9. 风险、限制与应对

### 9.1 最大风险：控件不可测或 locator 策略失控

应对：

- 关键控件优先补可测性  
- 页面对象统一维护 locator  
- 页面结构变化时优先改 `pages/`  

### 9.2 第二风险：只做执行，不做留证

应对：

- 强制保留截图  
- 强制保留 step / action 日志  
- 强制输出结果 JSON  

### 9.3 第三风险：过早平台化

应对：

- 先本地闭环  
- 再设备池、多机并发、CI 平台化  

### 9.4 当前残留限制

当前工作区虽然已经跑通闭环，但仍有这些现实边界：

- 真实接口请求 / 响应日志还未与 UI 步骤完全串联  
- Flutter 大项目中，完全不改业务源码的 locator 稳定性不一定长期成立  
- Xcode 或 iOS 版本升级后，需要重新验证工具链  

---

## 10. 工作量评估（面向落地节奏）

### 10.1 POC（跑通 1 到 2 条闭环）

约 3 到 5 个工作日：

- 环境和设备跑通  
- 执行器打通  
- 日志和截图落盘  
- 报告生成  

### 10.2 可日用（覆盖核心流程）

约 2 到 4 周：

- 覆盖 3 到 5 条主流程  
- 稳定 locator / selector 策略  
- 初步形成目录和命令规范  

### 10.3 工程化稳定态

持续迭代：

- 等待机制  
- 判断机制  
- 重试机制  
- 边缘场景  
- 接口采集  
- AI 分析  

---

## 11. 结论与下一步建议

### 11.1 结论

当前更可靠的落地结论是：

- Swift 项目：`XCUITest` 是主线  
- Flutter 项目：如果当前目标是低侵入快速闭环，`flutter_driver` 是更务实的方案  
- 真正值得沉淀的不是单个 demo，而是统一的 `qa/` 执行中台、`run_id`、日志格式、截图和报告链路  

### 11.2 下一步（按周推进）

- **第 1 周**：选 1 个项目，把执行 + 日志 + 截图 + 报告闭环跑通  
- **第 2 周**：覆盖 3 到 5 条核心主流程，固定目录结构与命令约定  
- **第 3 周+**：补稳定性层、边缘场景、接口采集、AI 报告质量提升  

---

## 附录：从 0→1 的检查清单（可直接复制到周报）

- [ ] Xcode 能识别设备或模拟器  
- [ ] 设备开启 Developer Mode（真机场景）  
- [ ] Swift：XCUITest 冒烟跑通  
- [ ] Flutter：`flutter_driver + flutter drive` 冒烟跑通  
- [ ] `qa/reports/<run_id>/` 正常生成  
- [ ] 报告能输出 `report.md`、`report.html`、`report_single_file.html`  
- [ ] 失败时能定位到具体 step 和截图  
- [ ] 后续接口采集结构已预留接入位  

（完）
