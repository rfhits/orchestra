# Orchestra Architecture

This document describes the production architecture of Orchestra.

## 1. Overview

Orchestra bridges AI tools and REAPER through file-based IPC.

- **REAPER side (Lua):** executes DAW operations
- **Python side (MCP server):** exposes tools and forwards requests
- **IPC layer:** request/reply JSON files in `~/.orchestra`

## 2. Main Components

### 2.1 Python Layer

- `cli.py`
  - `orch scripts <path>`: install REAPER scripts
  - `orch launch`: run MCP server on stdio
- `server.py`
  - auto-discovers public functions under `mcp_tools/`
  - registers them as MCP tools
- `mcp_bridge.py`
  - writes request JSON to `~/.orchestra/inbox`
  - waits for reply JSON from `~/.orchestra/outbox`
  - archives handled replies
- `mcp_tools/*`
  - typed tool wrappers (track/item/audio/midi/project/marker/take)

### 2.2 REAPER Layer

- `reaper_scripts/orchestra_loader.lua`
  - bootstrap and module loading entrypoint
- `reaper_scripts/orchestra_main.lua`
  - polling/defer loop for incoming requests
- `reaper_scripts/dispatcher.lua`
  - dispatches `module.method` calls
- domain modules (`track.lua`, `item.lua`, `audio.lua`, `midi.lua`, etc.)
  - validate params
  - call REAPER API
  - return normalized result/error

## 3. IPC Contract

Directories under `~/.orchestra/`:

- `inbox/`: incoming request files
- `outbox/`: reply files from REAPER side
- `archive/`: historical processed replies

Call flow:

1. MCP tool receives call
2. Python bridge writes request JSON to `inbox`
3. REAPER loop consumes request and executes function
4. REAPER writes reply JSON to `outbox`
5. Python reads reply and returns result to MCP client

## 4. Tool Naming Convention

- Python function path: `mcp_tools/<module>.py::function`
- REAPER method name: `"module.function"`

Example:

- Python: `mcp_tools/track.py::set_mute`
- REAPER call: `track.set_mute`

## 5. Error Model

Lua module functions return:

- success: `return true, { ... }`
- failure: `return false, { code = "...", message = "..." }`

Common error codes:

- `INVALID_PARAM`
- `NOT_FOUND`
- `INTERNAL_ERROR`
- `FILE_NOT_FOUND`
- `FILE_READ_ERROR`
- `JSON_PARSE_ERROR`
- `MODULE_NOT_FOUND`
- `METHOD_NOT_FOUND`
- `METHOD_CALL_ERROR`

## 6. Design Principles

- **Typed MCP surface:** Python wrappers use type hints for schema generation
- **Thin Python wrappers:** DAW behavior lives in REAPER Lua modules
- **Atomic file-based IPC:** robust and easy to inspect/debug
- **Modular REAPER scripts:** each module owns one DAW domain
- **Testability:** JSON request tests under `reaper_scripts/test/`

