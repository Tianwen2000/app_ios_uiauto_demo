# UI 自动化测试报告

- 运行ID: `swift_ui_20260319_122023_3aba987e`
- 生成时间: 2026-03-19 12:22:35 CST
- 产物目录: `/Users/a123/PycharmProjects/Virtualenv_project/yueling_project/tests/ui_auto/qa/artifacts/swift_ui_20260319_122023_3aba987e`

## 总览

- 用例总数: 2
- 通过用例: 2
- 失败用例: 0
- 截图数量: 11
- JSONL 日志数量: 4
- 失败步骤数: 0
- 失败动作数: 0

## 用例详情

### 搜索与分类筛选

- 状态: 通过
- 耗时: 26936 ms
- 开始时间: 2026-03-19 12:21:26
- 结束时间: 2026-03-19 12:21:53
- 失败步骤: 暂无
- 调试描述: 暂无

| 步骤ID | 步骤名称 | 状态 | 耗时 | 截图 | 错误信息 |
| --- | --- | --- | --- | --- | --- |
| S001 | 登录进入演示应用 | 通过 | 11520 ms | [查看截图](screens/testSearchAndCategoryFilters/S001_success.png) | - |
| S002 | 搜索命中的商品 | 通过 | 3746 ms | [查看截图](screens/testSearchAndCategoryFilters/S002_success.png) | - |
| S003 | 清空搜索并按分类筛选 | 通过 | 6245 ms | [查看截图](screens/testSearchAndCategoryFilters/S003_success.png) | - |
| S004 | 触发空状态页面 | 通过 | 5421 ms | [查看截图](screens/testSearchAndCategoryFilters/S004_success.png) | - |

#### 失败动作

- 无

### 登录、浏览、个人页校验并退出

- 状态: 通过
- 耗时: 34025 ms
- 开始时间: 2026-03-19 12:21:57
- 结束时间: 2026-03-19 12:22:31
- 失败步骤: 暂无
- 调试描述: 暂无

| 步骤ID | 步骤名称 | 状态 | 耗时 | 截图 | 错误信息 |
| --- | --- | --- | --- | --- | --- |
| S001 | 等待登录页出现 | 通过 | 3253 ms | [查看截图](screens/testSmoke_LoginBrowseProfileLogout/S001_success.png) | - |
| S002 | 提交有效账号密码 | 通过 | 9359 ms | [查看截图](screens/testSmoke_LoginBrowseProfileLogout/S002_success.png) | - |
| S003 | 校验发现页并执行搜索 | 通过 | 5543 ms | [查看截图](screens/testSmoke_LoginBrowseProfileLogout/S003_success.png) | - |
| S004 | 将商品加入购物袋 | 通过 | 2654 ms | [查看截图](screens/testSmoke_LoginBrowseProfileLogout/S004_success.png) | - |
| S005 | 进入个人页并校验状态 | 通过 | 3617 ms | [查看截图](screens/testSmoke_LoginBrowseProfileLogout/S005_success.png) | - |
| S006 | 切换个人页开关项 | 通过 | 4971 ms | [查看截图](screens/testSmoke_LoginBrowseProfileLogout/S006_success.png) | - |
| S007 | 退出并返回登录页 | 通过 | 4625 ms | [查看截图](screens/testSmoke_LoginBrowseProfileLogout/S007_success.png) | - |

#### 失败动作

- 无

## 接口采集说明

当前未发现应用侧网络日志文件。在“不能改业务源码”的约束下，请求与响应明细仍需要依赖外部代理抓包，或等待后续接入客户端网络层日志钩子。

## 备注

- 本报告基于测试侧本地采集到的 JSONL、截图和结果文件生成。
- `.xcresult` 仍保留，但不作为唯一证据来源，因为 Xcode 可能出现附件写入 warning。
