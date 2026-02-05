# Orchestra (MCP DAW)

## Project Overview
Orchestra is a hybrid system designed to integrate AI capabilities into the Reaper Digital Audio Workstation (DAW) via the Model Context Protocol (MCP). It enables AI assistants (like Claude or Gemini) to control Reaper remotely, performing tasks such as track creation, media insertion, and project management.

The system uses a **File-Based IPC (Inter-Process Communication)** mechanism to bridge the gap between the Python-based MCP server and the Lua-based Reaper scripting environment.

## Architecture

The system consists of two main components:

1.  **Reaper Host Script (Lua)**
    *   Runs inside Reaper.
    *   **Entry Point:** `orchestra_loader.lua`
    *   **Core Logic:** `orchestra_main.lua` uses a `reaper.defer` loop to poll for incoming JSON request files in `~/.orchestra/inbox/`.
    *   **Dispatch:** `dispatcher.lua` routes requests to specific modules (e.g., `track.lua`, `media.lua`, `project.lua`).
    *   **Response:** Writes results back to `~/.orchestra/outbox/`.

2.  **MCP Server (Python)**
    *   Runs as an external process.
    *   **Entry Point:** `server.py` (uses `FastMCP`).
    *   **Tools:** Dynamically loads tools from the `mcp_tools/` directory.
    *   **Bridge:** `mcp_bridge.py` handles the file I/O to communicate with the Lua script. It writes request files and waits for response files.

## Directory Structure

*   `orchestra_loader.lua`: Main entry point for Reaper.
*   `orchestra_main.lua`: Main processing loop.
*   `dispatcher.lua`: Routes requests to functions.
*   `server.py`: Python MCP server entry point.
*   `mcp_bridge.py`: Handles communication with Reaper (via files).
*   `mcp_tools/`: Python implementations of MCP tools (wrappers around the bridge).
*   `models/`: Contains AI models and related scripts.
*   `test/`: Lua test scripts and JSON test data.

## Setup & Usage

### Prerequisites
*   **Reaper:** Installed and running.
*   **Python:** With `uv` package manager installed.

### 1. Start the Lua Server (in Reaper)
1.  Open Reaper.
2.  Open the Action List (`?`).
3.  Load and run `orchestra_loader.lua`.
    *   *Note: This script initializes the system and starts monitoring the `~/.orchestra/inbox` directory.*

### 2. Start the MCP Server (Terminal)
Run the server using `uv`:

```bash
uv run server.py
```

## Development Workflow

### Adding a New Tool

1.  **Lua Side (Implementation):**
    *   Create or update a module (e.g., `my_module.lua`).
    *   Implement the function (e.g., `function M.my_action(params)`).
    *   Register the module in `orchestra_loader.lua` (if it's a new file).
    *   The function is now accessible via `my_module.my_action`.

2.  **Python Side (Interface):**
    *   Create a new file in `mcp_tools/` (e.g., `my_tool.py`) or add to an existing one.
    *   Define a function that calls `bridge.call_reaper("my_module.my_action", params)`.
    *   `server.py` will automatically discover and register this function as an MCP tool.

### Testing
*   **Lua Tests:** Run `test_runner.lua` in Reaper to execute tests found in the `test/` directory.
*   **Manual Testing:** Drop JSON files into `~/.orchestra/inbox/` to manually trigger Lua actions.

## Communication Protocol

Requests and responses are JSON files.

**Request (`~/.orchestra/inbox/<job_id>.json`):**
```json
{
  "meta": {
    "version": "1",
    "id": "job_123",
    "ts_ms": 1700000000000
  },
  "request": {
    "func": "track.create",
    "param": { "name": "Violin" }
  }
}
```

**Response (`~/.orchestra/outbox/<job_id>.reply.json`):**
```json
{
  "meta": { ... },
  "response": {
    "ok": true,
    "result": { "track_index": 1 }
  }
}
```
