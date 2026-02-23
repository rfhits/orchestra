# Orchestra 架构说明

本文档描述 Orchestra 的生产架构。

## 1. 总览

Orchestra 通过文件 IPC 将 AI 工具与 REAPER 连接起来：

- **REAPER 侧（Lua）**：执行 DAW 操作
- **Python 侧（MCP Server）**：暴露工具并转发请求
- **IPC 层**：在 `~/.orchestra` 下交换请求/响应 JSON

## 2. 主要组件

### 2.1 Python 层

- `cli.py`
  - `orch scripts <path>`：安装 REAPER 脚本
  - `orch launch`：以 stdio 模式启动 MCP Server
- `server.py`
  - 自动扫描 `mcp_tools/` 下公有函数
  - 注册为 MCP 工具
- `mcp_bridge.py`
  - 向 `~/.orchestra/inbox` 写请求
  - 从 `~/.orchestra/outbox` 读取响应
  - 将处理结果归档
- `mcp_tools/*`
  - 各领域工具包装（track/item/audio/midi/project/marker/take）

### 2.2 REAPER 层

- `reaper_scripts/orchestra_loader.lua`
  - 脚本启动入口与模块加载
- `reaper_scripts/orchestra_main.lua`
  - 请求轮询/`defer` 主循环
- `reaper_scripts/dispatcher.lua`
  - 分派 `module.method`
- 领域模块（`track.lua`、`item.lua`、`audio.lua`、`midi.lua` 等）
  - 参数校验
  - 调用 REAPER API
  - 返回统一结果/错误

## 3. IPC 协议目录

`~/.orchestra/` 下目录：

- `inbox/`：请求队列
- `outbox/`：响应队列
- `archive/`：归档

调用流程：

1. MCP client 调用工具
2. Python bridge 写请求到 `inbox`
3. REAPER 消费请求并执行
4. REAPER 写响应到 `outbox`
5. Python 读取响应并返回给 MCP client

## 4. 工具命名约定

- Python 函数：`mcp_tools/<module>.py::function`
- REAPER 调用名：`"module.function"`

示例：

- Python：`mcp_tools/track.py::set_mute`
- REAPER：`track.set_mute`

## 5. 错误模型

Lua 公共函数返回约定：

- 成功：`return true, { ... }`
- 失败：`return false, { code = "...", message = "..." }`

常见错误码：

- `INVALID_PARAM`
- `NOT_FOUND`
- `INTERNAL_ERROR`
- `FILE_NOT_FOUND`
- `FILE_READ_ERROR`
- `JSON_PARSE_ERROR`
- `MODULE_NOT_FOUND`
- `METHOD_NOT_FOUND`
- `METHOD_CALL_ERROR`

## 6. 设计原则

- **类型化 MCP 接口**：Python 层用类型注解生成 schema
- **Python 薄封装**：DAW 行为尽量落在 Lua 领域模块
- **文件 IPC 可观测**：便于调试与问题定位
- **REAPER 模块化**：按领域拆分，便于扩展
- **可测试性**：`reaper_scripts/test/` 中维护 JSON 用例

