# Task 011: MIDI MCP 实现

## 概述

实现 MIDI 的 MCP (Model Context Protocol) Python 接口，遵循 Lua 侧的 API 设计，同时参考 `audio.py` 的模式。

## 核心改动

相比 `audio.py`，MIDI 的 MCP 接口有以下重要差异：

### 1. 新增 `session_id` 参数

Lua 侧的导出函数需要 `session_id` 来区分不同的导出任务：

```python
# audio.py 导出（无会话概念）
audio.render_seconds(tracks=[...], begin=0, length=10, filename="output.wav")

# midi.py 导出（有会话概念）
midi.render_seconds(tracks=[...], begin=0, length=10, session_id="my_session")
```

**目的**：导出多轨时，需要自动生成文件夹，格式为 `{datetime}_{session_id}`

### 2. 导出返回值不同

```python
# audio.py 返回值：只有文件路径
{
    "path": "/path/to/file.wav"
}

# midi.py 返回值：包含目录信息
{
    "path": "/full/path/to/20260118_104412_sec",
    "folder_name": "20260118_104412_sec",
    "session_id": "sec"
}
```

### 3. 静默导入模式

导入时使用 PCM Source 方法，完全静默：

```python
# 无弹窗导入，支持带 TimeMap 的 MIDI
midi.insert_at_second(
    file_path="path/to/file.mid",
    track="Piano",
    second=5.0
)

# 返回值包含导入信息
{
    "success": true,
    "message": "MIDI imported successfully",
    "length": 3.5
}
```

## API 设计

### 导出函数

#### `render_seconds(tracks, begin, length, session_id="sec")`

-   **参数**

    -   `tracks`: 轨道 ID 列表
    -   `begin`: 起始秒数
    -   `length`: 导出时长（秒）
    -   `session_id`: 会话 ID，默认 "sec"

-   **返回**：目录信息
    ```python
    {
        "path": "/full/path/to/folder",
        "folder_name": "20260118_104412_sec",
        "session_id": "sec"
    }
    ```

#### `render_measures(tracks, begin, length, session_id="meas")`

-   **参数**

    -   `tracks`: 轨道 ID 列表
    -   `begin`: 起始小节（1-based）
    -   `length`: 导出小节数
    -   `session_id`: 会话 ID，默认 "meas"

-   **返回**：同 `render_seconds`

### 导入函数

#### `insert_at_second(file_path, track, second=0)`

-   **参数**

    -   `file_path`: MIDI 文件路径（必须 .mid）
    -   `track`: 目标轨道 ID
    -   `second`: 导入秒数，默认 0

-   **返回**
    ```python
    {
        "success": true,
        "message": "MIDI imported successfully",
        "length": 3.5
    }
    ```

#### `insert_at_measure(file_path, track, measure=1)`

-   **参数**

    -   `file_path`: MIDI 文件路径（必须 .mid）
    -   `track`: 目标轨道 ID
    -   `measure`: 导入小节（1-based），默认 1

-   **返回**
    ```python
    {
        "success": true,
        "message": "MIDI imported successfully",
        "length": 3.5,
        "measure": 1
    }
    ```

## 实现细节

### bridge.call_reaper() 调用约定

所有函数都通过 `bridge.call_reaper()` 调用对应的 Lua 函数：

```python
return bridge.call_reaper("midi.render_seconds", {
    "tracks": tracks or [],
    "begin": begin,
    "len": length,        # 注意：Python 参数是 length，Lua 参数是 len
    "session_id": session_id
})
```

### 参数映射表

| Python 参数  | Lua 参数     | 说明              |
| ------------ | ------------ | ----------------- |
| `length`     | `len`        | 时长或小节数      |
| `second`     | `second`     | 秒数（导入时）    |
| `measure`    | `measure`    | 小节号（导入时）  |
| `session_id` | `session_id` | 会话 ID（导出时） |

### 错误处理

Python 侧不需要额外的验证，因为 Lua 侧已经完整实现了：

-   ✅ 文件路径验证（.mid 扩展名、文件存在性）
-   ✅ 轨道参数验证
-   ✅ 时间参数验证
-   ✅ 返回错误格式：`{ code: "ERROR_CODE", message: "..." }`

## 使用示例

```python
from mcp_tools import midi

# 导出多轨 MIDI 到文件夹
result = midi.render_measures(
    tracks=["Piano", "Violin", "Cello"],
    begin=1,
    length=4,
    session_id="symphony_export"
)
print(result["path"])  # /path/to/20260118_104412_symphony_export

# 导入带 TimeMap 的 MIDI（静默）
import_result = midi.insert_at_measure(
    file_path="/path/to/piece.mid",
    track="Piano",
    measure=2
)
print(import_result["length"])  # 3.5 (秒)
```

## 检查清单

-   [x] 参考 audio.py 的结构和模式
-   [x] 添加 `session_id` 参数用于导出任务区分
-   [x] 导出函数返回目录信息（path, folder_name, session_id）
-   [x] 导入函数使用静默 PCM Source 方法
-   [x] 导入函数验证 .mid 文件格式
-   [x] 参数映射正确（length -> len, second -> second）
-   [x] 完整的 docstring 说明
