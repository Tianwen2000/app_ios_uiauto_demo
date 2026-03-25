# Flutter Demo 项目 XCUITest 使用说明

## 1. 说明

这套 UI 自动化基于 Apple 官方 `XCTest / XCUITest` 方式实现，测试类继承 `XCTestCase`，测试方法以 `test` 开头，并通过 `setUpWithError` / `tearDownWithError` 管理启动和收尾。

实现时同时对齐了本目录的技术调研报告思路：

- 统一走 `Xcode / XCTest` 执行通道
- 关键页面控件补充稳定可测标识
- 用 `S001-S007` 这种 step 编号组织流程
- 每个 step 自动附带截图，并落本地 artifact 目录
- 通过 `QA_RUN_ID` 统一一次执行的上下文
- 生成 `JSONL + Markdown/HTML` 最小闭环报告

## 2. 关键文件

- `ios/RunnerUITests/RunnerUITests.swift`
  XCUITest 主测试文件，包含：
  - `testSmoke_LoginBrowseProfileLogout`
  - `testSearchAndCategoryFilters`
  - 页面对象与输入辅助方法
  - step 级与 action 级结构化日志
  - 失败截图和 `debugDescription` 落盘

- `lib/app.dart`
  底部导航已改成更适合自动化定位的按钮结构，补了稳定语义 id。

- `lib/screens/login_screen.dart`
- `lib/screens/discover_screen.dart`
- `lib/screens/profile_screen.dart`
- `lib/widgets/demo_product_card.dart`
  这些 Flutter 页面和组件补了 `Semantics(identifier: ...)` / `semanticsIdentifier`，用于提升可测性。

## 3. 当前覆盖的用例

### 3.1 冒烟主流程

`testSmoke_LoginBrowseProfileLogout`

覆盖步骤：

- S001 等待登录页
- S002 输入账号密码并登录
- S003 进入发现页并搜索商品
- S004 加入购物袋
- S005 进入个人页并校验状态
- S006 切换个人页开关
- S007 退出登录并返回登录页

### 3.2 搜索与筛选

`testSearchAndCategoryFilters`

覆盖步骤：

- 登录
- 搜索命中商品
- 清空搜索后切换分类
- 驱动空态页面

## 4. 为什么部分 selector 不是直接用语义 id

Flutter 的 `Semantics(identifier: ...)` 在 iOS 可访问性树里，某些控件会额外生成一个“语义代理节点”。

这在 `TextField` 上最明显：

- 一个节点带 `identifier`
- 另一个节点才是真正可输入、可获得键盘焦点的原生输入框

所以当前实现里：

- 文本输入优先选择真正可输入的原生节点
- 页面切换、按钮、空态、摘要等优先用稳定可见文案或稳定结构定位
- 导航区直接改成了更稳定的按钮结构，避免 `NavigationBar` 在 Flutter + iOS 下的映射不稳定

这是为了让 XCUITest 在 iOS 侧稳定通过，而不是为了追求“所有选择器都必须是 id”。

## 5. 如何在 Xcode 里运行

### 5.1 打开工程

打开：

```text
flutter_client_demo/ios/Runner.xcodeproj
```

如果后续这个项目引入了 Pods，再优先打开：

```text
flutter_client_demo/ios/Runner.xcworkspace
```

### 5.2 在 Xcode 中执行

1. 选择 `Runner` scheme
2. 选择一个 iOS Simulator 或真机
3. 打开 Test Navigator
4. 运行 `RunnerUITests`

也可以只点单个测试方法：

- `testSmoke_LoginBrowseProfileLogout`
- `testSearchAndCategoryFilters`

## 6. 命令行运行方式

在项目根目录执行：

```bash
cd /Users/a123/PycharmProjects/Virtualenv_project/yueling_project/tests/ui_auto/flutter_client_demo
```

### 6.1 跑全部 UI 用例

```bash
xcodebuild test \
  -project ios/Runner.xcodeproj \
  -scheme Runner \
  -destination 'platform=iOS Simulator,id=97BF0148-DC59-4E82-99B2-9F86865AB457' \
  -only-testing:RunnerUITests
```

### 6.2 只跑冒烟用例

```bash
xcodebuild test \
  -project ios/Runner.xcodeproj \
  -scheme Runner \
  -destination 'platform=iOS Simulator,id=97BF0148-DC59-4E82-99B2-9F86865AB457' \
  -only-testing:RunnerUITests/RunnerUITests/testSmoke_LoginBrowseProfileLogout
```

### 6.3 只跑搜索筛选用例

```bash
xcodebuild test \
  -project ios/Runner.xcodeproj \
  -scheme Runner \
  -destination 'platform=iOS Simulator,id=97BF0148-DC59-4E82-99B2-9F86865AB457' \
  -only-testing:RunnerUITests/RunnerUITests/testSearchAndCategoryFilters
```

### 6.4 执行前做 Flutter 静态检查

```bash
/Users/a123/develop/flutter/bin/flutter analyze
```

### 6.5 通过 qa 脚本执行并生成报告

在仓库根目录执行：

```bash
cd /Users/a123/PycharmProjects/Virtualenv_project/yueling_project/tests/ui_auto
make -C qa swift-smoke
make -C qa report
```

如果没有单独的 `qa/configs/devices.env`，脚本会自动回退到 `qa/configs/devices.example.env`。

## 7. 可选环境变量

当前测试支持：

- `QA_RUN_ID`
  自定义一次执行的 run 标识
- `QA_REPORTS_DIR`
  自定义本地证据目录；未显式传入时，`qa/scripts/run_swift_ui.sh` 会自动设置
- `QA_TEST_USERNAME`
  登录用户名
- `QA_TEST_PASSWORD`
  登录密码

示例：

```bash
QA_RUN_ID=smoke_001 \
QA_TEST_USERNAME=demo_operator \
QA_TEST_PASSWORD=123456 \
xcodebuild test \
  -project ios/Runner.xcodeproj \
  -scheme Runner \
  -destination 'platform=iOS Simulator,id=97BF0148-DC59-4E82-99B2-9F86865AB457' \
  -only-testing:RunnerUITests/RunnerUITests/testSmoke_LoginBrowseProfileLogout
```

## 8. 已知现象

当前 Xcode 15.2 在本机上执行时，会反复出现类似下面的 warning：

- attachment data 写入 `.xcresult/Staging/.../Attachments/...` 失败

这类 warning 目前不影响测试方法本身通过，属于结果附件落盘阶段的 Xcode 侧异常。

也就是说：

- 测试逻辑可以通过
- 但 `.xcresult` 里的附件可能不完整
- 当前报告优先使用 `qa/reports/<run_id>/` 下的本地截图和日志，不依赖 `.xcresult` 完整性

## 9. 产物目录与报告

执行完成后，默认会在：

```text
qa/reports/<run_id>/
```

下生成这些文件：

- `logs/xcodebuild.log`
- `logs/<test_name>_step_events.jsonl`
- `logs/<test_name>_action_events.jsonl`
- `logs/<test_name>_test_result.json`
- `logs/<test_name>_<step>_debug_description.txt`（失败时）
- `screens/<test_name>/*.png`
- `report.md`
- `report.html`

其中：

- `step_events.jsonl` 记录 step 编号、状态、耗时、截图路径
- `action_events.jsonl` 记录点击/输入等关键动作
- `test_result.json` 记录单条用例最终状态
- `report.md` / `report.html` 汇总展示所有证据

## 10. 接口日志的边界

当前这套增强只改了测试代码，没有改业务源码，所以：

- 可以稳定记录 UI 操作、step、错误、截图
- 不能稳定拿到 app 内最准确的请求/响应明细

如果后续要把 `step_id -> req_id -> request/response` 真正串起来，仍然需要：

- Flutter 网络层配合埋点
- 或外部抓包代理作为补充证据
## 11. 后续扩展建议

如果你把真实 Flutter 客户端代码接进来，下一步建议按同样模式继续扩展：

- 先给关键控件补稳定语义 id
- 每个业务流程拆成 step
- 页面对象和断言分层
- 保留少量“可见文案兜底 selector”
- 再把 `run_id / step_id / req_id` 跟客户端网络日志打通

这样就能继续往技术调研报告里的“执行 + 采集 + 分析 + 报告”闭环靠拢。
