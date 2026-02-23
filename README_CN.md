# Orchestra

Orchestra 是一个面向 REAPER 的轻量 MCP 桥接系统。  
它通过 Python MCP Server + REAPER 内 Lua 脚本，让 AI Agent 可以执行 DAW 操作。

## Orchestra 是什么

Orchestra 连接了三部分：

1. REAPER 侧 Lua 脚本（执行 DAW 操作）
2. Python MCP Server（注册工具、处理 MCP 调用）
3. 文件 IPC 通道（`~/.orchestra/inbox`、`outbox`、`archive`）

设计目标是可落地的 AI 辅助音乐编辑，而不只是一次性生成。

## 安装

前置条件：

- `uv`
- REAPER

先安装 `uv`（官方安装脚本）：

```bash
# macOS / Linux
curl -LsSf https://astral.sh/uv/install.sh | sh

# Windows (PowerShell)
powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"
```

然后从 PyPI 安装 Orchestra（包名：`reaper-orchestra`）：

```bash
uv tool install reaper-orchestra
orch --help
```

如果 shell 里找不到 `orch`，把 uv 工具目录加入 `PATH`：

```bash
uv tool update-shell
```

## 5 分钟快速开始

1. 安装 REAPER 脚本：

```bash
orch scripts "<REAPER Scripts 目录>"
```

这个命令会把脚本复制到：

- `<REAPER Scripts 目录>/rfhits/orchestra`

2. 在 REAPER 中运行 `orchestra_loader.lua`。
3. 在 MCP Client 中添加 Orchestra 配置（见 `MCP Client 配置`）。Client 会自动拉起 `orch launch`。
4. 在 MCP Client 中调用工具。
5. 如需停止 REAPER 侧循环，在 REAPER 中运行 `orchestra_stop.lua`。

## REAPER 集成方式

端到端流程：

1. Python 工具调用 `bridge.call_reaper("module.method", params)`
2. 请求写入 `~/.orchestra/inbox`
3. REAPER 主循环分派并执行
4. 响应写入 `~/.orchestra/outbox` 并归档

## MCP Client 配置

以 Claude Desktop 为例，MCP 配置文件位置：

- macOS：`~/Library/Application Support/Claude/claude_desktop_config.json`
- Windows：`%APPDATA%\\Claude\\claude_desktop_config.json`

若要在 MCP 配置里直接使用 `command: "orch"`，请先保证 `orch` 已安装并且在 `PATH` 中（例如先执行：`uv tool install reaper-orchestra`）。

在 `mcpServers` 下添加 Orchestra：

```json
{
  "mcpServers": {
    "orchestra": {
      "command": "orch",
      "args": ["launch"]
    }
  }
}
```

`uv` 的好处是环境和命令统一管理，CLI 启动入口保持简洁（`orch`）。

## 核心能力

- 工程信息、速度/拍号控制
- 轨道 CRUD、颜色、mute/solo、父子轨（folder）关系
- Item CRUD、split/merge、颜色、长度
- Take 添加/查询/激活
- Marker 增删改查
- Audio 插入与渲染（按秒/按小节）
- MIDI 插入与导出（按秒/按小节）

## 当前限制

- 不能替代人工进行最终混音审美决策
- 还不支持完整的“概念级”局部音频重生成
- FX 链和自动化能力仍在持续补齐

## 演示与生态

视频演示：

- [when agent touches DAW (reaper) - YouTube](https://www.youtube.com/watch?v=7nNEDk1Hfw4)
- [continue and arrange MIDI in reaper via agent & MCP - YouTube](https://www.youtube.com/watch?v=ZUTUWWFiCdI)
- [当 Agent 遇见 DAW(Reaper) - 哔哩哔哩](https://www.bilibili.com/video/BV151fJB8EUF/)
- [agent 接入 reaper 进行 MIDI 续写和编曲 - 哔哩哔哩](https://www.bilibili.com/video/BV16pfwBHE5p/)

相关 MCP 音乐项目：

- `awesome-music-mcp`: https://github.com/Music-MCP/awesome-music-mcp

## 贡献与许可证

- 欢迎提交 Issue 和 PR。
- 许可证见 `LICENSE`。
