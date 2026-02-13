# AGENTS.md - Orchestra Project Guide

本文档为 AI 助手提供项目最新结构、开发规范和最佳实践，帮助你快速理解并正确协助开发。

## 📋 项目概述

**Orchestra** 是一个 MCP DAW 系统，通过文件 IPC 协议连接 REAPER 与 AI 助手，实现 AI 驱动的音频制作流程。

### 关键组成

- **REAPER 侧（Lua）**：运行于 REAPER 内部，执行实际 DAW 操作。
- **MCP Server（Python）**：FastMCP 服务器，自动注册工具并通过文件 IPC 调用 REAPER。
- **通信方式**：基于文件系统 IPC（`~/.orchestra/inbox/`, `outbox/`, `archive/`）。

## 🧭 当前仓库结构

```
cli.py                  # CLI 入口（orch/orchestra）
server.py               # FastMCP 服务器，自动注册 mcp_tools
mcp_bridge.py           # 文件 IPC 桥接层（~/.orchestra）
mcp_tools/              # Python MCP 工具定义（audio/midi/track/project）
reaper_scripts/         # REAPER Lua 脚本（orchestra_loader/main/dispatcher 等）
docs/                   # 设计与 API 文档
tasks/                  # 任务记录
skills/                 # Skills 工作流
pyproject.toml          # 打包与依赖配置
```

## 🔌 运行流程（端到端）

1. **安装 REAPER 脚本**
   - CLI：`orch scripts <REAPER Scripts 目录>`
   - 会复制到 `.../Scripts/rfhits/orchestra`
2. **REAPER 启动**
   - 在 REAPER 中运行 `orchestra_loader.lua`
3. **Python MCP 启动**
   - CLI：`orch launch`（stdio 模式）
4. **调用流程**
   - Python 工具函数 → `mcp_bridge.call_reaper()` 写入 `~/.orchestra/inbox/*.json`
   - REAPER `orchestra_main.lua` 轮询处理 → `dispatcher` 分派 → 生成 reply
   - Python 读取 `outbox/*.reply.json`，并归档到 `archive/`

## 🧱 Python 侧开发规范

### 1) 工具定义

在 `mcp_tools/` 中新增模块，函数名即工具名（自动注册）：

```python
# mcp_tools/foo.py
from typing import Any, Dict
from mcp_bridge import bridge

def bar(value: int) -> Dict[str, Any]:
    return bridge.call_reaper("foo.bar", {"value": value})
```

**关键规则**
- **不要写装饰器注册**：`server.py` 会自动扫描并注册函数。
- **必须使用类型注解**：FastMCP 依赖类型提示生成 schema。
- **工具名格式**：`模块名.函数名`，与 REAPER 侧一致。

### 2) MCP 服务器

`server.py` 会扫描 `mcp_tools/` 并注册所有公有函数。

## 🎛️ REAPER（Lua）侧开发规范

### 1) 模块与初始化

`orchestra_loader.lua` 负责加载模块并启动 `orchestra_main.lua`。新增模块时：

1. 新增 `reaper_scripts/<module>.lua`
2. 将模块名加入 `orchestra_loader.lua` 的模块列表
3. 如需 logger 或依赖模块，在 `orchestra_main.lua` 中初始化

### 2) 返回值规范

```lua
-- 成功
return true, { field = value }

-- 失败
return false, { code = "ERROR_CODE", message = "Error description" }
```

### 3) 日志与调试

模块内部必须使用 `logger`，启动阶段可使用 `reaper.ShowConsoleMsg` 做 bootstrap。

### 4) 参数验证（强制）

对所有公共函数执行参数验证，异常直接返回错误并记录日志。

### 5) REAPER API 调用规范

- 执行动作前后使用 `reaper.Undo_BeginBlock()` / `reaper.Undo_EndBlock()`
- 操作后调用 `reaper.UpdateArrange()`
- 轨道索引为 0-based

### 6) 错误码标准

- `INVALID_PARAM`
- `NOT_FOUND`
- `INTERNAL_ERROR`
- `FILE_NOT_FOUND`
- `FILE_READ_ERROR`
- `JSON_PARSE_ERROR`
- `MODULE_NOT_FOUND`
- `METHOD_NOT_FOUND`
- `METHOD_CALL_ERROR`

## ➕ 新增功能的标准流程

1. **Python 侧**
   - 在 `mcp_tools/` 新建模块或新增函数
   - 通过 `bridge.call_reaper("module.method", params)` 发送
2. **REAPER 侧**
   - 在 `reaper_scripts/` 新建同名模块
   - 确保函数名与 Python 侧一致
   - 更新 `orchestra_loader.lua` 的模块列表
   - 如果需要依赖注入或 logger，在 `orchestra_main.lua` 中初始化

## 🧪 测试与调试

### 测试入口

REAPER 侧测试脚本在 `reaper_scripts/test/`，可使用 `test_runner.lua` 运行。

### 关键调试点

- `~/.orchestra/orchestra.log`：统一日志
- `~/.orchestra/inbox/`：请求队列
- `~/.orchestra/outbox/`：响应队列
- `~/.orchestra/archive/`：已处理响应
- REAPER 控制台：启动阶段输出

## 📚 相关文档

- `ARCHITECTURE.md`：详细架构说明
- `README.md`：项目概述
- `docs/`：REAPER API / MCP 规范
- `tasks/`：任务跟踪记录
