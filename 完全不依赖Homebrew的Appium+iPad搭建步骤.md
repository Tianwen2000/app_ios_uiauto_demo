# 完全不依赖 Homebrew 的 Appium + iPad 搭建步骤（Mac / iOS 真机）

> 目标：**不用 Homebrew**，只用 **Xcode + Node 官方安装包 + npm + Appium Inspector**，把 iPad 真机 Appium 自动化环境跑通。  
> 适用：iPad / iPhone 真机，macOS，Appium 2。  
> 范围：本文只讲 **环境搭建、WDA 签名、Server 启动、Inspector 建 session**，**不写自动化代码**。

---

## 1. 最终验收标准

你只要跑通下面 4 件事，就说明环境已经搭好：

1. Xcode 能识别 iPad  
2. Appium Server 能启动  
3. Appium Inspector 能连上 Server  
4. 能成功创建一个 iOS 真机 session，并拉起目标 App

---

## 2. 这套方案里你要装什么

这条“**不依赖 Homebrew**”路线里，只保留最小必需组件：

- **Xcode**
- **Node.js 官方 macOS 安装包（.pkg）**
- **Appium（用 npm 安装）**
- **Appium XCUITest Driver**
- **Appium Inspector（独立 App）**

> 先不装 Homebrew，也先不装 ios-deploy / libimobiledevice / iproxy 这些辅助工具。  
> 第一阶段先把“能连上真机并跑 session”跑通，排障再说。

---

## 3. 第 0 步：确认你满足真机前提

### 3.1 设备要求
- 一台 Mac
- 一台 iPad（建议先用数据线有线连接）
- iPad 已解锁
- iPad 第一次连接时，点击过 **“信任此电脑”**
- iPadOS / iOS 16 及以上时，已开启 **Developer Mode**

### 3.2 账号要求
真机跑 Appium iOS 自动化，本质上还是要在手机上部署 **WebDriverAgent（WDA）**。  
WDA 需要签名，所以你通常需要：

- 一个可用的 Apple ID
- 最好是公司提供的开发 Team
- 或者你的 Apple ID 已被加入公司 Team

> 只是“Xcode 识别设备”不一定要账号；  
> 但只要你要在真机上跑 WDA / XCUITest / Appium，基本就会涉及签名与 Team。

---

## 4. 第 1 步：安装 Xcode

### 4.1 安装方式
直接从 App Store 安装 Xcode。

### 4.2 首次启动要做的事
安装完成后：

1. 打开 Xcode
2. 等待它完成首次组件安装
3. 打开菜单：**Xcode → Settings / Preferences**
4. 确认 Command Line Tools 已选中当前 Xcode

### 4.3 验证 Xcode
打开终端执行：

```bash
xcodebuild -version
```

如果能输出版本号，说明 Xcode 基本正常。

---

## 5. 第 2 步：让 Xcode 识别你的 iPad

1. 用数据线把 iPad 连接到 Mac
2. 打开 iPad，保持解锁
3. 如果弹出 **“信任此电脑”**，点信任
4. 打开 Xcode
5. 进入：**Window → Devices and Simulators**

验收标准：
- 左侧能看到你的 iPad
- 设备状态不是一直转圈的 “Connecting...”
- 能看到设备名、系统版本等信息

> 如果这里都看不到，后面的 Appium 先别配，先解决设备连接问题。

---

## 6. 第 3 步：安装 Node.js（官方 pkg，不用 Homebrew）

### 6.1 安装方式
去 Node.js 官网下载 **macOS Installer (.pkg)**，直接双击安装。

建议：
- 优先装 **LTS 版本**
- Apple Silicon 机器装 arm64 对应包
- Intel 机器装 x64 对应包

### 6.2 验证 Node 和 npm

安装完成后打开终端：

```bash
node -v
npm -v
```

验收标准：
- 能看到版本号
- 没有 `command not found`

---

## 7. 第 4 步：安装 Appium（用 npm，不用 Homebrew）

### 7.1 全局安装 Appium
执行：

```bash
npm i --location=global appium
```

### 7.2 验证 Appium

```bash
appium -v
```

能输出版本号就说明安装成功。

---

## 8. 第 5 步：安装 iOS 驱动（XCUITest Driver）

Appium 2 不再把所有驱动都内置进去，iOS 需要单独安装 **xcuitest driver**。

执行：

```bash
appium driver install xcuitest
```

安装完成后检查：

```bash
appium driver list
```

验收标准：
- 输出里能看到 `xcuitest`

---

## 9. 第 6 步：安装 Appium Inspector（独立 App）

### 9.1 安装方式
去 Appium Inspector 官方页面下载 **macOS .dmg**，然后拖到 Applications。

### 9.2 第一次打不开怎么办
因为它可能没有经过苹果公证，macOS 第一次可能拦截。

处理方式：
1. Finder 里找到 Appium Inspector
2. 右键 / 双指点按 → **Open（打开）**
3. 再次确认打开

> 第一次放行后，后面通常就能正常打开。

---

## 10. 第 7 步：启动 Appium Server

先在终端启动 Appium：

```bash
appium
```

看到类似下面的输出就可以：

```text
[Appium] Welcome to Appium ...
[Appium] Appium REST http interface listener started on http://0.0.0.0:4723
```

说明：
- 默认端口通常是 **4723**
- 这个终端窗口先不要关，Inspector 连接要用它

---

## 11. 第 8 步：处理 WebDriverAgent（WDA）

> 这是 iOS 真机最关键、也最容易卡住的一步。  
> 如果你只记一个结论，那就是：  
> **Appium 在 iOS 真机上能不能跑，核心不在 Appium，而在 WDA 能不能成功签名并部署。**

---

## 12. 第 9 步：先尝试“自动签名”路线（推荐先试）

Appium 在真机上可以尝试自动处理 WDA，但前提是你在 capability 里给出签名相关参数。

后面创建 session 时，你会用到这些参数：

- `platformName = iOS`
- `automationName = XCUITest`
- `udid = 你的设备 UDID`
- `bundleId = 目标 App 的 bundle id`（如果目标 App 已安装）
- `xcodeOrgId = 你的 Team ID`
- `xcodeSigningId = Apple Development`

如果这条路线能跑通，就不用手工处理 WDA 工程。

---

## 13. 第 10 步：如果自动签名失败，就改走“手工签名 WDA”路线

这是最稳的办法。

### 13.1 找到 WebDriverAgent 工程
Appium 的 xcuitest driver 里会包含 WDA 工程。  
你要找到：

```text
WebDriverAgent.xcodeproj
```

> 不同机器、不同安装方式，具体路径可能略有差异。  
> 核心不是死记路径，而是找到 Appium 安装目录下的 `WebDriverAgent.xcodeproj`。

### 13.2 用 Xcode 打开这个工程
双击打开 `WebDriverAgent.xcodeproj`

### 13.3 签名配置
在 Xcode 左侧项目设置中，重点看这两个 target：

- `WebDriverAgentLib`
- `WebDriverAgentRunner`

对它们分别做：

1. 打开 **Signing & Capabilities**
2. 勾选 / 开启 **Automatically manage signing**
3. 在 **Team** 里选择你的开发团队

### 13.4 处理 Bundle Identifier 冲突
如果报 bundle id 冲突：
- 把 `WebDriverAgentRunner` 的 bundle id 改成一个唯一值
- 例如加上你名字、项目名或日期后缀

---

## 14. 第 11 步：在 Xcode 里跑 WDA

1. 运行目标设备选成你的 iPad
2. 选择 `WebDriverAgentRunner`
3. 执行：**Product → Test**（快捷键 `Cmd + U`）

成功时常见现象：
- iPad 上会短暂启动一个无图标或特殊图标的测试应用
- Xcode 控制台不再报签名错误
- Runner 能正常启动

> 如果这里失败，先不要继续折腾 Inspector。  
> 先把 Xcode 跑 WDA 这件事搞定。

---

## 15. 第 12 步：准备 Inspector 的能力参数（Capabilities）

打开 Appium Inspector，创建新会话时，先填这组“最小必需参数”。

### 15.1 已安装 App 场景（推荐）
如果目标 App 已经装在 iPad 上：

```json
{
  "platformName": "iOS",
  "appium:automationName": "XCUITest",
  "appium:udid": "你的设备UDID",
  "appium:bundleId": "目标App的bundleId",
  "appium:xcodeOrgId": "你的TeamID",
  "appium:xcodeSigningId": "Apple Development"
}
```

### 15.2 未安装 App 场景
如果目标 App 还没装，你可以改成传 `.app` 或 `.ipa` 文件路径：

```json
{
  "platformName": "iOS",
  "appium:automationName": "XCUITest",
  "appium:udid": "你的设备UDID",
  "appium:app": "/你的本地文件路径/xxx.app",
  "appium:xcodeOrgId": "你的TeamID",
  "appium:xcodeSigningId": "Apple Development"
}
```

### 15.3 可选增强参数
后面你稳定后可以加：

```json
{
  "appium:wdaLocalPort": 8100,
  "appium:newCommandTimeout": 120,
  "appium:useNewWDA": false
}
```

说明：
- `wdaLocalPort`：多设备并发时很有用
- `newCommandTimeout`：避免长时间无操作断开
- `useNewWDA`：排障时可设为 `true` 强制重装 WDA；平时建议 `false`

---

## 16. 第 13 步：在 Inspector 里创建 session

1. 打开 Appium Inspector
2. Server 地址填：
   - `http://127.0.0.1:4723`
3. 粘贴上面的 capabilities
4. 点 **Start Session**

成功时你会看到：
- App 被拉起
- Inspector 左侧出现页面结构树
- 可以点元素、查看属性、录制基础操作

---

## 17. 常见报错与处理思路

### 17.1 `xcodeOrgId` / Team / signing 相关报错
说明本质上还是签名没通。

处理：
- 回到 Xcode 手工签 WDA
- 确认 `WebDriverAgentRunner` 的 Team 已选对
- 确认 Bundle Identifier 没冲突

### 17.2 设备明明连着，但 Inspector 建 session 失败
先确认下面这三件事：
- Xcode 里设备是否可见
- WDA 在 Xcode 里能否单独跑通
- Appium Server 是否已启动

### 17.3 Inspector 连得上 Server，但 App 拉不起来
排查顺序：
1. `bundleId` 是否写错
2. 目标 App 是否真的已安装
3. 如果传的是 `.app/.ipa` 路径，路径是否正确
4. 是否有签名/权限问题导致安装失败

### 17.4 App 拉起来了，但元素层级很怪 / 找不到元素
这通常不是 Appium 环境问题，而是 **App 可测性问题**：
- iOS 原生：关键控件没加 `accessibilityIdentifier`
- Flutter：没做 Key / Semantics，或没有正确暴露到 iOS Accessibility

---

## 18. 这条“不用 Homebrew”路线的局限

这条路线的优点是：
- 简单
- 干净
- 更符合你“不想装 Homebrew”的偏好
- 足够把第一阶段主链路跑通

但它的局限也很明确：
- 没有 `iproxy` 这类工具，端口转发排障不方便
- 没有 `libimobiledevice` 这类工具，命令行设备信息获取不方便
- 没有 `ios-deploy`，命令行装包与排障能力弱一些

所以建议是：
- **第一阶段**：先用这套最小链路跑通  
- **第二阶段**：只有当你真的卡在排障、批量装包、多机并发时，再决定要不要补外围工具

---

## 19. 最小检查清单

你只要一项项打勾即可：

- [ ] Xcode 已安装并能输出版本
- [ ] iPad 在 Xcode 的 Devices and Simulators 中可见
- [ ] Node.js 已安装，`node -v` 正常
- [ ] npm 已安装，`npm -v` 正常
- [ ] Appium 已安装，`appium -v` 正常
- [ ] XCUITest driver 已安装，`appium driver list` 能看到 `xcuitest`
- [ ] Appium Inspector 已安装并能打开
- [ ] WDA 在 Xcode 中能签名并运行
- [ ] Appium Server 已启动
- [ ] Inspector 能成功建立 session

---

## 20. 推荐你现在就按这个顺序做

### 第一天只做 4 件事：
1. 装 Xcode  
2. 让 Xcode 识别 iPad  
3. 装 Node pkg  
4. 用 npm 装 Appium 和 xcuitest driver  

### 第二天只攻 WDA：
1. 找到 `WebDriverAgent.xcodeproj`
2. 配签名
3. 在 Xcode 里 Product → Test 跑通

### 第三天再做 Inspector：
1. 安装 Inspector
2. 填 capabilities
3. 建 session

---

## 21. 一句话总结

如果你不想用 Homebrew，**完全没问题**。  
你只要记住一句话：

> **Xcode 负责真机识别和 WDA 签名，Node+npm 负责安装 Appium，Inspector 负责建 session；只要 WDA 能在 Xcode 里跑起来，后面的 Appium 通常就能接上。**

（完）
