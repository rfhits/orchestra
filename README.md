# Orchestra

Orchestra is a lightweight MCP bridge for REAPER.
It lets AI agents call DAW operations through a Python MCP server and a Lua script running inside REAPER.

## What is Orchestra

Orchestra connects three parts:

1. REAPER-side Lua scripts (execute DAW actions)
2. Python MCP server (registers tools and handles MCP calls)
3. File-based IPC bridge (`~/.orchestra/inbox`, `outbox`, `archive`)

The design goal is practical AI-assisted music editing, not only one-shot generation.

## Installation

Prerequisites:

- `uv`
- REAPER

Install `uv` (official standalone installer):

```bash
# macOS / Linux
curl -LsSf https://astral.sh/uv/install.sh | sh

# Windows (PowerShell)
powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"
```

Install Orchestra from PyPI as a uv-managed tool:

```bash
uv tool install reaper-orchestra
orch --help
```

If `orch` is not found in your shell, add uv's tool bin directory to `PATH`:

```bash
uv tool update-shell
```

## Quick Start (5 min)

1. Install REAPER scripts:

```bash
orch scripts "<REAPER Scripts directory>"
```

This command copies files into:

- `<REAPER Scripts directory>/rfhits/orchestra`

2. In REAPER, run `orchestra_loader.lua`.
3. Add Orchestra to your MCP client config (see `MCP Client Configuration`). The client launches `orch launch` automatically.
4. Call tools from your MCP client.
5. To stop the REAPER side loop, run `orchestra_stop.lua` in REAPER.

## REAPER Integration

End-to-end flow:

1. MCP tool (Python) calls `bridge.call_reaper("module.method", params)`
2. Request JSON is written to `~/.orchestra/inbox`
3. REAPER main loop dispatches and executes
4. Reply JSON is written to `~/.orchestra/outbox` and archived

## MCP Client Configuration

For Claude Desktop, edit this MCP config file:

- macOS: `~/Library/Application Support/Claude/claude_desktop_config.json`
- Windows: `%APPDATA%\\Claude\\claude_desktop_config.json`

To use `command: "orch"` directly in MCP config, make sure `orch` is installed and available on `PATH` (for example: `uv tool install reaper-orchestra`).

Add Orchestra under `mcpServers`:

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

Why `uv` helps here: it manages the environment and keeps the CLI launch path simple (`orch`).

## Core Capabilities

- Project info, tempo/time-signature control
- Track CRUD, color, mute/solo, parent-child folder relation
- Item CRUD, split/merge, color, length
- Take add/list/activate
- Marker create/list/update/delete
- Audio insert/render (seconds/measures)
- MIDI insert/render (seconds/measures)

## Limitations

- Not a full replacement for manual mixing decisions
- No full automatic “concept-level” local audio regeneration yet
- FX-chain and automation workflows are still being expanded

## Demos and Ecosystem

Video demos:

- [when agent touches DAW (reaper) - YouTube](https://www.youtube.com/watch?v=7nNEDk1Hfw4)
- [continue and arrange MIDI in reaper via agent & MCP - YouTube](https://www.youtube.com/watch?v=ZUTUWWFiCdI)
- [当 Agent 遇见 DAW(Reaper) - 哔哩哔哩](https://www.bilibili.com/video/BV151fJB8EUF/)
- [agent 接入 reaper 进行 MIDI 续写和编曲 - 哔哩哔哩](https://www.bilibili.com/video/BV16pfwBHE5p/)

Related MCP music projects and tools:

- `awesome-music-mcp`: https://github.com/Music-MCP/awesome-music-mcp

## Contributing / License

- Issues and pull requests are welcome.
- See `LICENSE` for licensing terms.
