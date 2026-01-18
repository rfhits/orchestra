# AGENT.md - Orchestra Project Guide

本文档为 AI 助手提供项目上下文、开发规范和最佳实践，帮助 AI 更好地理解和协助开发。

## 📋 项目概述

**Orchestra** 是一个 MCP DAW 系统，通过文件 IPC 协议连接 REAPER DAW 和 AI 助手（如 Claude Code），实现 AI 驱动的音频制作流程。

### 核心目标

-   通过 AI 助手控制 REAPER 进行音频操作（创建轨道、插入音频、渲染等）
-   最终实现 AI 辅助或全流程接管的音频制作

### 系统架构

-   **REAPER 侧（Lua）**：在 REAPER 内运行，执行实际 DAW 操作
-   **MCP Server（Python）**：作为 AI 助手与 REAPER 的桥梁，处理 MCP 协议
-   **通信方式**：基于文件系统的 IPC 协议（`~/.orchestra/inbox/` 和 `outbox/`）

## 🏗️ 架构设计

### 模块化架构

项目采用模块化设计，每个模块职责单一：

```
orchestra_loader.lua    # 模块加载器和启动入口
├── logger.lua          # 统一日志系统
├── file_manager.lua    # 文件系统操作（IPC 协议）
├── json_manager.lua    # JSON 解析和生成
├── config.lua          # 配置管理（路径、目录等）
├── track.lua           # Track 操作封装
├── audio.lua           # Audio 操作封装
├── midi.lua            # MIDI 操作封装
├── project.lua         # Project 操作封装
├── dispatcher.lua      # 动态函数分派器（核心路由）
└── orchestra_main.lua  # 主逻辑和循环（reaper.defer）
```

### 请求处理流程

1. **MCP Server** 写入请求到 `~/.orchestra/inbox/{job_id}.json`
2. **orchestra_main.lua** 通过 `reaper.defer` 循环监听 inbox
3. **file_manager.lua** 原子认领请求（移动到 outbox）
4. **dispatcher.lua** 解析 `request.func`（格式：`module.method`）
5. **对应模块** 执行操作并返回结果
6. **file_manager.lua** 写入回复到 `~/.orchestra/outbox/{job_id}.reply.json`
7. **MCP Server** 读取回复并返回给 AI

## 📝 代码风格和约定

### Lua 代码规范

#### 1. 模块结构

所有模块遵循标准 Lua 模块模式：

```lua
-- module_name.lua
local M = {}
local logger = nil  -- 模块级变量

function M.init(log_module)
    logger = log_module.get_logger("ModuleName")
end

function M.some_function(param)
    -- 实现逻辑
    return true, {result = "data"}
end

return M
```

#### 2. 函数返回值约定

所有业务函数遵循统一返回值模式：

```lua
-- 成功：返回 true, result_table
return true, {
    field1 = value1,
    field2 = value2
}

-- 失败：返回 false, error_table
return false, {
    code = "ERROR_CODE",
    message = "Error description"
}
```

#### 3. 日志使用规范

**⚠️ 重要**：必须使用统一的 `logger` 模块，不要使用 `reaper.ShowConsoleMsg` 或自定义日志方法。

```lua
-- ✅ 正确：使用 logger
local logger = nil
function M.init(log_module)
    logger = log_module.get_logger("ModuleName")
end

function M.some_function(param)
    logger.info("Processing request")
    logger.debug("Debug info: " .. tostring(value))
    logger.warn("Warning message")
    logger.error("Error occurred")
end

-- ❌ 错误：不要使用自定义日志
function M.info(message)
    reaper.ShowConsoleMsg("[Module] " .. message .. "\n")
end
```

#### 4. 参数验证

所有公开函数必须验证输入参数：

```lua
function M.create(param)
    local track_name = param.name or ""

    if track_name == nil or track_name == "" then
        logger.error("Track name is empty")
        return false, { code = "INVALID_PARAM", message = "Track name is empty" }
    end

    -- 继续处理...
end
```

#### 4.5 防御性编程

**⚠️ 重要原则**：不要默默地使用默认值或跳过错误。任何不符合预期的情况都必须记录错误日志，这样便于调试。

```lua
-- ❌ 错误：默默使用默认值，无法调试
local last_value = 4  -- 默认 4/4
if num == -1 then
    num = last_value  -- 如果逻辑有问题，无法察觉
end

-- ✅ 正确：先检查前提条件，否则报错
if num == -1 then
    if not last_valid_num then
        logger.error("Cannot inherit value: no previous valid value exists")
        return false, { code = "INVALID_PARAM", message = "Inheritance without valid predecessor" }
    end
    num = last_valid_num
    logger.info("Using inherited value: " .. tostring(num))
end

-- ✅ 也可以用于初始化检查
if not bpm or bpm <= 0 then
    logger.error(string.format("Invalid BPM: %s", tostring(bpm)))
    return false, { code = "INVALID_PARAM", message = "BPM must be positive" }
end
```

**关键规则**：

1. **关键数据不能沉默失败**：第一个/必需的数据必须有效，否则返回错误而不是默认值
2. **可选数据才能有默认值**：只有明确是可选的参数才能使用默认值
3. **错误必须可见**：用 `logger.error()` 记录所有异常情况，便于调试
4. **早期返回**：在数据验证阶段早期返回错误，不要让坏数据传播到后续逻辑

#### 5. REAPER API 调用

-   使用 REAPER API 后必须调用 `reaper.UpdateArrange()` 刷新界面
-   使用 `reaper.Undo_BeginBlock()` 和 `reaper.Undo_EndBlock()` 包装操作
-   注意 API 的返回值格式（有些返回单个值，有些返回多个值）

```lua
reaper.Undo_BeginBlock()
-- 执行操作
reaper.InsertTrackAtIndex(index, true)
reaper.UpdateArrange()
reaper.Undo_EndBlock("Operation description", -1)
```

#### 6. 错误代码规范

使用统一的错误代码：

-   `INVALID_PARAM`：参数无效
-   `NOT_FOUND`：资源不存在
-   `INTERNAL_ERROR`：内部错误
-   `FILE_NOT_FOUND`：文件不存在
-   `FILE_READ_ERROR`：文件读取错误
-   `JSON_PARSE_ERROR`：JSON 解析错误
-   `MODULE_NOT_FOUND`：模块未找到
-   `METHOD_NOT_FOUND`：方法未找到
-   `METHOD_CALL_ERROR`：方法调用错误

### Python 代码规范

#### 1. MCP 工具定义

在 `mcp_tools/` 目录下定义工具

```python
# mcp_tools/track.py
from mcp_bridge import mcp_tool

def create_track(name: str, index: int = -1):
    """创建轨道"""
    # 实现逻辑
    pass
```

## 🔧 开发工作流程

### 检查文档

Reaper API 在 [reaper-docs](./docs/reaper-api-functions.md)

在写代码前，需要确认所有使用 API 存在

### 添加新功能模块

1. **创建模块文件**（如 `effects.lua`）：

```lua
-- effects.lua
local M = {}
local logger = nil

function M.init(log_module)
    logger = log_module.get_logger("Effects")
end

function M.apply_reverb(param)
    local intensity = param.intensity or 0.5
    -- 实现逻辑
    logger.info("Applying reverb with intensity: " .. tostring(intensity))
    return true, {result = "reverb applied", intensity = intensity}
end

return M
```

2. **在 `orchestra_loader.lua` 中注册**：

```lua
local modules = {
    "file_manager",
    "json_manager",
    "track",
    "audio",
    "midi",
    "project",
    "dispatcher",
    "logger",
    "effects"  -- 新模块
}
```

3. **在 `orchestra_main.lua` 中初始化**（如果需要 logger）：

```lua
if modules.effects and modules.logger then
    modules.effects.init(modules.logger)
end
```

4. **直接使用**：无需修改 dispatcher，直接通过 `effects.apply_reverb` 调用

### 测试新功能

1. **创建测试 JSON 文件**（放在 `test/` 目录下）：

```json
{
  "meta": {
    "version": "1",
    "id": "test_001",
    "ts_ms": 1234567890,
    "agent_id": "test"
  },
  "request": {
    "func": "effects.apply_reverb",
    "param": {
      "intensity": 0.8
    }
  }
}
```

2. **运行测试**：
    - 使用 `test_runner.lua` 选择测试
    - 或手动复制 JSON 到 `~/.orchestra/inbox/`

## ⚠️ 开发注意事项

### 1. 参数打印

打印复杂对象时，使用 `json_manager.stringify()` 而不是 `tostring()`：

```lua
logger.debug("Parameters: " .. json_manager.stringify(param))
```

### 2. 模块依赖管理

通过 `orchestra_main.lua` 注入依赖，不要在模块内部使用 `require()`：

```lua
-- ✅ 正确：通过 init 注入
function M.init(log_module, track_module)
    logger = log_module.get_logger("ModuleName")
    track = track_module
end

-- ❌ 错误：模块内 require
local track = require("track")
```

### 3. REAPER API 注意事项

-   **轨道索引**：REAPER 使用 0-based 索引
-   **时间单位**：注意秒（second）和小节（measure）的转换
-   **GUID**：轨道使用 GUID 作为唯一标识，格式为 `{GUID...}`
-   **颜色值**：需要加上 `0x1000000` 标志位才能启用自定义颜色

### 6. 文件 IPC 协议

-   使用原子操作（`os.rename`）避免文件冲突
-   `.part` 后缀表示写入中，必须忽略
-   确保 `inbox/` 和 `outbox/` 在同一文件系统分区

### 7. 循环机制

使用 `reaper.defer` 而非 `while true + sleep`，避免阻塞 REAPER 界面。

## 🧪 测试指南

### 测试文件结构

测试文件位于 `test/` 目录，按模块分类：

```
test/
├── track/
│   ├── track_create_test.json
│   └── track_delete_test.json
├── audio/
│   ├── audio_insert_test.json
│   └── audio_render_test.json
└── project/
    └── project_info_test.json
```

### 测试 JSON 格式

```json
{
  "meta": {
    "version": "1",
    "id": "{timestamp}_{agent_id}_{random}",
    "ts_ms": 1234567890123,
    "agent_id": "test"
  },
  "request": {
    "func": "module.method",
    "param": {
      "field1": "value1",
      "field2": 123
    }
  }
}
```

### 运行测试

1. 启动 Orchestra：运行 `orchestra_loader.lua`
2. 运行测试：使用 `test_runner.lua` 或手动复制 JSON 到 inbox
3. 查看结果：检查 `~/.orchestra/outbox/` 中的回复文件

## 📚 相关文档

-   `ARCHITECTURE.md`：详细架构说明
-   `README.md`：项目概述和设计目标
-   `tasks/task001-architect-lua-mcp.md`：IPC 协议规范
-   `docs/`：REAPER API 文档

## 🎯 开发原则

1. **模块化**：每个模块职责单一，接口清晰
2. **可扩展**：新增功能无需修改核心代码
3. **错误处理**：统一的错误响应格式
4. **日志统一**：使用 `logger` 模块，不要自定义日志方法
5. **非阻塞**：使用 `reaper.defer` 保持界面响应
6. **原子操作**：文件操作使用原子 rename
7. **向后兼容**：保持 IPC 协议兼容性

## 🔍 调试技巧

1. **查看日志**：检查 `~/.orchestra/orchestra.log`
2. **REAPER 控制台**：查看 `reaper.ShowConsoleMsg` 输出
3. **文件状态**：检查 `inbox/` 和 `outbox/` 中的文件
4. **模块状态**：使用 `orchestra_main.get_status()` 获取运行状态
