# Orchestra File IPC Protocol v1

## 项目概述

### 系统设计结构

整个框架分为 **4 个核心组件**：

1. **Reaper 侧 Lua 客户端**

    - 扮演操作者角色，接收执行指令并执行相应操作
    - 负责执行 Reaper DAW 的原生功能，如「创建轨道」等操作

2. **MCP 服务器（Python 实现）**

    - 对外暴露 AI 可调用的 API 接口
    - 集成上述 Reaper 侧操作，提供统一的服务入口

3. **第三方 IDE 集成**

    - Claude Code、Codex、Trae 等 IDE
    - 内置 MCP 通信功能，实现无缝集成

4. **AI 音乐框架**
    - 其他第三方 AI 音乐理解和生成框架
    - 如 MIDI-GPT 等专用工具

#### 设计优势

-   **模块化架构**：分离了 DAW 实现，更换 DAW 相当于更换后端实现
-   **统一接口**：提供标准化的音乐信息检索机制，不同 DAW 可通过统一机制表达音乐状态
-   **开放集成**：第三方 AI 可通过 MCP 协议轻松接入系统
-   **IDE 集成**：原生 IDE 支持可集成 Skills 等扩展功能

---

## Orchestra File IPC Protocol v1 (Request-Reply One-Job-One-File)

本协议用于 **MCP Server（Python）** 与 **DAW Host（Reaper/Lua）** 之间通过本地文件系统进行可靠通信。

### 设计目标

**简单、可扩展、跨平台、避免文件写入冲突**，并保持"一次 request-reply 对应一个任务 id（一个 job）"的模式。

> **重要说明**：本协议的"一次交互一个文件"指 **一个 job 对应一个 id**，其状态通过文件名/目录演进表达。  
> 为保证原子性与可恢复性，允许同一 job 在不同阶段存在不同后缀（`.part`/`.json`/`.reply.json`）。

---

## 1. 路径与目录结构

### 根目录配置

-   默认根目录：`~/.orchestra/`
-   可通过配置文件自定义

### 目录结构

```
~/.orchestra/
├── inbox/       # 任务入口（由 MCP 写入，Lua 认领）
├── outbox/      # 处理区与结果输出（由 Lua 输出，MCP 消费）
└── archive/     # 归档区（可选，由 MCP 归档历史结果）
```

> **硬性要求**：`inbox/`、`outbox/`、`archive/` 必须位于**同一文件系统/分区**，否则 `rename`/`move` 操作可能不再具备原子性。

---

## 2. Job ID 与文件命名规范

### 2.1 Job ID 格式

文件名采用以下格式确保可追溯性与自然排序：

```
{ts_ms}_{agent_id}_{rand}
```

**字段说明**：

-   `ts_ms`：13 位毫秒时间戳（如 `1732854000000`），用于自然排序与问题排查
-   `agent_id`：调用方标识（如 `claude`/`trae`/`midi-gpt`），仅用于可读性与多来源区分
-   `rand`：随机字符串，用于确保唯一性，**强度要求**：
    -   **推荐**：UUIDv4（32 位十六进制，不含连字符）或等效强度随机串
    -   **最低要求**：64-bit 随机（16 位十六进制）
    -   **不推荐**：6 位短随机串（无法保证完全规避并发冲突）

> **约定**：文档中 `{id}` 指上述三段拼接后的完整字符串。

### 2.2 文件名后缀规范

| 文件类型               | 后缀                   | 状态   | 消费者说明   |
| ---------------------- | ---------------------- | ------ | ------------ |
| 请求文件（提交完成态） | `{id}.json`            | 完整   | Lua 可处理   |
| 请求文件（提交中态）   | `{id}.json.part`       | 部分   | Lua 必须忽略 |
| 认领文件               | `{id}.req.json`        | 已认领 | Lua 正在处理 |
| 回复文件（写入中态）   | `{id}.reply.json.part` | 部分   | MCP 必须忽略 |
| 回复文件（完成态）     | `{id}.reply.json`      | 完整   | MCP 可处理   |

---

## 3. 文件状态机（Lifecycle）

本协议采用"**文件名状态机**"机制，利用文件系统 `rename` 的原子性实现双方同步。

| 阶段         | 文件路径与名称                | 操作方 | 状态含义                           |
| ------------ | ----------------------------- | ------ | ---------------------------------- |
| 1. 提交中    | `inbox/{id}.json.part`        | MCP    | MCP 正在写入请求，Lua 必须忽略     |
| 2. 已提交    | `inbox/{id}.json`             | MCP    | 请求写入完成，等待 Lua 认领        |
| 3. 已认领    | `outbox/{id}.req.json`        | Lua    | Lua 已原子认领该任务，避免重复处理 |
| 4. 回复中    | `outbox/{id}.reply.json.part` | Lua    | Lua 正在写入回复，MCP 必须忽略     |
| 5. 已完成    | `outbox/{id}.reply.json`      | Lua    | 回复写入完成，可被 MCP 消费        |
| 6. 销毁/归档 | 删除或移至 `archive/`         | MCP    | MCP 消费结果后清理，闭环完成       |

---

## 4. 详细交互流程

### 4.1 MCP 提交流程（写请求）

1. **生成 Job ID**：MCP 生成 `{id}` 标识符
2. **写入请求**：MCP 将请求内容写入 `inbox/{id}.json.part`
3. **原子提交**：MCP 写入完成后执行原子重命名操作：
    ```bash
    rename("inbox/{id}.json.part", "inbox/{id}.json")
    ```
4. **等待响应**：MCP 进入轮询模式，等待 `outbox/{id}.reply.json` 出现（忽略 `.part` 文件）

> **严格要求**：MCP 必须使用 `.part → .json` 的提交方式，确保 Lua 不会读取到半写文件。

### 4.2 Lua 认领与执行流程（消费请求、产出回复）

1. **轮询请求**：Lua 持续轮询 `inbox/*.json`（**必须忽略** `*.part` 文件）
2. **原子认领**：Lua 发现 `inbox/{id}.json` 后，执行原子认领：
    ```bash
    rename("inbox/{id}.json", "outbox/{id}.req.json")
    ```
3. **处理请求**：Lua 读取并解析 `outbox/{id}.req.json`，执行对应 DAW 操作
4. **生成回复**：Lua 生成回复 JSON，写入 `outbox/{id}.reply.json.part`
5. **原子提交**：Lua 写入完成后执行原子重命名：
    ```bash
    rename("outbox/{id}.reply.json.part", "outbox/{id}.reply.json")
    ```

> **严格要求**：Lua 不应"原地修改" `{id}.req.json` 来追加结果；应生成独立 reply 文件并原子提交，避免崩溃导致数据损坏与状态不确定。

### 4.3 MCP 消费与清理流程（读回复、删除请求）

1. **读取回复**：MCP 发现 `outbox/{id}.reply.json` 后读取并解析
2. **提取响应**：MCP 从回复 JSON 中读取 `response` 字段并返回给上游 agent
3. **清理文件**（两种策略选择其一）：
    - **销毁策略（默认）**：删除 `outbox/{id}.reply.json`（以及残留的 `.part` 文件）
    - **归档策略（可选）**：将 `outbox/{id}.reply.json` 移动到 `archive/`（可按日期分目录）

> **建议**：如果需要长期保留历史记录，请按日期分区，例如 `archive/2025-12-27/{id}.reply.json`，避免单目录文件堆积。

---

## 5. 文件内容格式（JSON Schema 规范）

### 5.1 顶层结构（Envelope）

所有请求/回复文件内容使用统一的 envelope 结构（便于扩展与调试）：

```json
{
  "meta": "元信息（版本、id、时间、来源）",
  "request": "请求内容（func + param）",
  "response": "响应内容（ok/result/error）"
}
```

### 5.2 请求文件格式（`inbox/{id}.json`）

**必需字段**：`meta` 与 `request`；`response` 可省略或设为 `null`

#### 字段定义

-   `meta.version`：协议版本号（整数），v1 固定为 `1`
-   `meta.id`：job id（必须与文件名一致）
-   `meta.ts_ms`：毫秒时间戳（建议与文件名一致）
-   `meta.agent_id`：来源标识（建议与文件名一致）
-   `request.func`：函数/动作名（字符串，如 `track.create`）
-   `request.param`：参数对象（JSON object）

### 5.3 回复文件格式（`outbox/{id}.reply.json`）

**必需字段**：`meta`、`request`（原样回显）以及 `response`

#### 字段定义

-   `response.ok`：布尔值，`true` 表示成功，`false` 表示失败
-   `response.result`：成功时返回的数据（object，允许为空对象 `{}`）
-   `response.error`：失败时的错误对象（object），成功时必须为 `null` 或省略

#### 错误对象结构

-   `error.code`：稳定错误码（如 `INVALID_PARAM` / `NOT_FOUND` / `INTERNAL_ERROR`）
-   `error.message`：人类可读的详细错误信息
-   `error.data`：（可选）结构化附加信息，便于 MCP/AI 进行策略判断

---

## 6. 完整示例

### 6.1 请求示例（提交完成态）

**文件**：`inbox/1732854000000_claude_7f3a9c1d2e4b6a8f.json`

```json
{
  "meta": {
    "version": 1,
    "id": "1732854000000_claude_7f3a9c1d2e4b6a8f",
    "ts_ms": 1732854000000,
    "agent_id": "claude"
  },
  "request": {
    "func": "track.create",
    "param": {
      "name": "piano",
      "index": -1
    }
  }
}
```

### 6.2 成功回复示例

**文件**：`outbox/1732854000000_claude_7f3a9c1d2e4b6a8f.reply.json`

```json
{
  "meta": {
    "version": 1,
    "id": "1732854000000_claude_7f3a9c1d2e4b6a8f",
    "ts_ms": 1732854000000,
    "agent_id": "claude"
  },
  "request": {
    "func": "track.create",
    "param": {
      "name": "piano",
      "index": -1
    }
  },
  "response": {
    "ok": true,
    "result": {
      "track_guid": "{B3D2...}",
      "created": true
    },
    "error": null
  }
}
```

### 6.3 失败回复示例

```json
{
  "meta": {
    "version": 1,
    "id": "1732854000000_claude_7f3a9c1d2e4b6a8f",
    "ts_ms": 1732854000000,
    "agent_id": "claude"
  },
  "request": {
    "func": "media_insert",
    "param": {
      "file": "/path/to/missing.wav",
      "track_guid": "{...}"
    }
  },
  "response": {
    "ok": false,
    "result": null,
    "error": {
      "code": "FILE_NOT_FOUND",
      "message": "Audio file not found: /path/to/missing.wav",
      "data": {
        "file": "/path/to/missing.wav"
      }
    }
  }
}
```

---

## 7. 可靠性约束（必须严格遵守）

### 原子性保证

-   **原子提交**：请求与回复都必须使用 `.part → rename` 原子提交机制
-   **消费者规则**：消费者必须忽略 `.part` 文件

### 单消费者语义

-   **原子认领**：Lua 通过 `rename(inbox → outbox)` 实现原子认领，保证同一请求不会被重复执行

### 文件系统约束

-   **同文件系统要求**：`inbox/outbox/archive` 必须在同一文件系统上，避免跨分区 move 操作失去原子性

### 崩溃恢复机制

-   **未完成请求**：若存在 `outbox/{id}.req.json` 但无对应 reply 文件，说明 Lua 认领后发生崩溃：

    -   可由 Lua 下次启动时继续处理，或
    -   由 MCP 标记超时后重新发送（具体策略需在系统层面统一定义）

-   **未完成写入**：若存在 `.part` 文件，说明写入过程未完成，可安全删除或下次重试覆盖

### 性能与存储管理

-   **目录膨胀控制**：若启用归档功能，建议按日期分目录组织；若不归档，MCP 消费后应立即删除 reply 文件，避免 outbox 长期文件堆积影响性能
