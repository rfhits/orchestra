# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Orchestra** is an MCP (Model Context Protocol) server that bridges AI assistants with REAPER DAW (Digital Audio Workstation). It enables AI-driven audio production through a file-based IPC protocol.

**Core Architecture:**
- **REAPER Client (Lua)**: Runs inside REAPER, executes DAW operations
- **MCP Server (Python)**: Bridges AI assistants to REAPER via MCP protocol
- **Communication**: File-based IPC using `~/.orchestra/inbox/` and `outbox/`

**Goal**: Enable AI assistants to control REAPER for audio production tasks (create tracks, insert audio/MIDI, render) through natural language commands.

## System Architecture

### Request Flow
1. MCP Server writes request to `~/.orchestra/inbox/{job_id}.json`
2. `orchestra_main.lua` monitors inbox via `reaper.defer` loop
3. `file_manager.lua` atomically claims request (moves to outbox)
4. `dispatcher.lua` parses `request.func` (format: `module.method`)
5. Target module executes operation and returns result
6. `file_manager.lua` writes reply to `~/.orchestra/outbox/{job_id}.reply.json`
7. MCP Server reads reply and returns to AI

### Lua Module Structure
```
orchestra_loader.lua    # Module loader and entry point
├── logger.lua          # Unified logging system
├── file_manager.lua    # File system operations (IPC protocol)
├── json_manager.lua    # JSON parsing and generation
├── config.lua          # Configuration management
├── track.lua           # Track operations
├── audio.lua           # Audio operations
├── midi.lua            # MIDI operations
├── project.lua         # Project operations
├── time_map.lua        # Time/measure conversion
├── dispatcher.lua      # Dynamic function dispatcher
└── orchestra_main.lua  # Main logic loop (reaper.defer)
```

### Python MCP Server
- **Entry**: `server.py` - Auto-registers all tools from `mcp_tools/`
- **Bridge**: `mcp_bridge.py` - Handles file IPC communication
- **Tools**: `mcp_tools/{track,audio,midi,project}.py` - MCP tool definitions

## Development Commands

### Starting Orchestra
Run `orchestra_loader.lua` in REAPER to start the client.

### Stopping Orchestra
Run `orchestra_stop.lua` to gracefully stop the client.

### Running Tests
1. Run `test_runner.lua` in REAPER
2. Select test from menu
3. Check `~/.orchestra/outbox/` for results

Alternatively, manually copy test JSON files from `test/` to `~/.orchestra/inbox/`.

### Starting MCP Server
The MCP server is configured to run via Claude Code's MCP integration. Check your MCP configuration for the startup command (typically uses `uv` or Python).

## Code Conventions

### Lua Module Pattern
All Lua modules follow this structure:
```lua
local M = {}
local logger = nil

function M.init(log_module)
    logger = log_module.get_logger("ModuleName")
end

function M.some_function(param)
    -- Implementation
    return true, {result = "data"}
end

return M
```

### Function Return Convention
All business functions return `(success: boolean, data: table)`:
```lua
-- Success
return true, {field1 = value1, field2 = value2}

-- Failure
return false, {code = "ERROR_CODE", message = "Error description"}
```

### Logging Requirements
**CRITICAL**: Always use the unified `logger` module. Never use `reaper.ShowConsoleMsg` or custom logging.
```lua
logger.info("Processing request")
logger.debug("Debug info: " .. tostring(value))
logger.warn("Warning message")
logger.error("Error occurred")
```

### Parameter Validation
All public functions must validate inputs:
```lua
function M.create(param)
    local track_name = param.name or ""

    if track_name == nil or track_name == "" then
        logger.error("Track name is empty")
        return false, {code = "INVALID_PARAM", message = "Track name is empty"}
    end

    -- Continue processing...
end
```

### Defensive Programming
**Never silently use default values for critical data**. Always log errors for unexpected conditions:
```lua
-- ❌ Wrong: Silent fallback
if num == -1 then
    num = last_value  -- Can't debug if logic is wrong
end

-- ✅ Correct: Check preconditions, fail loudly
if num == -1 then
    if not last_valid_num then
        logger.error("Cannot inherit value: no previous valid value exists")
        return false, {code = "INVALID_PARAM", message = "Inheritance without valid predecessor"}
    end
    num = last_valid_num
    logger.info("Using inherited value: " .. tostring(num))
end
```

### REAPER API Usage
- Always call `reaper.UpdateArrange()` after API operations
- Wrap operations with `reaper.Undo_BeginBlock()` and `reaper.Undo_EndBlock()`
- Track indices are 0-based
- Colors need `0x1000000` flag to enable custom colors

### Error Codes
Standard error codes:
- `INVALID_PARAM`: Invalid parameter
- `NOT_FOUND`: Resource not found
- `INTERNAL_ERROR`: Internal error
- `FILE_NOT_FOUND`: File not found
- `FILE_READ_ERROR`: File read error
- `JSON_PARSE_ERROR`: JSON parse error
- `MODULE_NOT_FOUND`: Module not found
- `METHOD_NOT_FOUND`: Method not found
- `METHOD_CALL_ERROR`: Method call error

## Adding New Features

### 1. Create Lua Module
```lua
-- effects.lua
local M = {}
local logger = nil

function M.init(log_module)
    logger = log_module.get_logger("Effects")
end

function M.apply_reverb(param)
    local intensity = param.intensity or 0.5
    logger.info("Applying reverb with intensity: " .. tostring(intensity))
    return true, {result = "reverb applied", intensity = intensity}
end

return M
```

### 2. Register in orchestra_loader.lua
Add to modules list:
```lua
local modules = {
    "file_manager", "json_manager", "track", "audio", "midi",
    "project", "dispatcher", "logger", "effects"  -- New module
}
```

### 3. Initialize in orchestra_main.lua
```lua
if modules.effects and modules.logger then
    modules.effects.init(modules.logger)
end
```

### 4. Create Python MCP Tool (Optional)
```python
# mcp_tools/effects.py
from mcp_bridge import bridge

def apply_reverb(intensity: float = 0.5):
    """Apply reverb effect"""
    return bridge.call_reaper("effects.apply_reverb", {"intensity": intensity})
```

The dispatcher automatically routes `effects.apply_reverb` calls to the Lua module.

## Important Notes

### File IPC Protocol
- Uses atomic operations (`os.rename`) to avoid conflicts
- `.part` suffix indicates file is being written (must be ignored)
- `inbox/` and `outbox/` must be on same filesystem partition

### Non-Blocking Loop
Uses `reaper.defer` instead of `while true + sleep` to avoid blocking REAPER UI.

### Time Conversion
- `time_map.lua` handles conversion between seconds and measures
- Accounts for tempo changes and time signature variations
- Use `time_map.measure_to_second()` and `time_map.second_to_measure()`

### MIDI Import
MIDI files are imported silently without dialogs, even if they contain tempo/time signature changes. The system automatically handles TimeMap information.

### Debugging
- Check logs: `~/.orchestra/orchestra.log`
- Check REAPER console for immediate output
- Inspect files in `inbox/`, `outbox/`, and `archive/` directories
- Use `json_manager.stringify()` to print complex objects

## Project Goals

The ultimate goal is to enable AI-assisted music production where users can create complete songs through voice commands alone, similar to SUNO but with full DAW control. The workflow targets:
1. Lyrics → Melody generation (MIDI)
2. Melody → Harmony generation
3. Melody → Accompaniment generation (multiple instruments)
4. Import to REAPER and render

## Related Documentation

- `ARCHITECTURE.md`: Detailed architecture explanation
- `AGENTS.md`: Comprehensive development guide with coding standards
- `README.md`: Project vision and design goals
- `docs/reaper-api-functions.md`: REAPER API reference
- `test/README.md`: Testing guide
