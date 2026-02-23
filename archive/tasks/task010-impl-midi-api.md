# Task 010: MIDI API 实现文档

## API 概览

```lua
-- 导出 MIDI 文件到目录
M.render_measures(param)    -- 从小节导出：{ tracks, begin, len, session_id }
M.render_seconds(param)     -- 从秒数导出：{ tracks, begin, len, session_id }

-- 导入 MIDI 文件到轨道
M.insert_at_measure(param)  -- 在小节处插入：{ file_path, track, measure }
M.insert_at_second(param)   -- 在秒数处插入：{ file_path, track, second }
```

## 核心实现原理

### 1. MIDI 文件格式基础

MIDI 文件存储三种核心信息：

| 信息         | 说明                             | 用途                               |
| ------------ | -------------------------------- | ---------------------------------- |
| **MPQN**     | Microseconds Per Quarter Note    | 四分音符的微秒长度，编码 BPM 信息  |
| **PPQ**      | Pulses Per Quarter Note (分辨率) | 每个四分音符的 tick 数（通常 960） |
| **Time Sig** | 拍号（分子/分母）                | 定义节拍结构                       |

**关键公式**：

```
MPQN = 60,000,000 * den / (bpm * 4)
```

-   拍号分母越大（如 8），MPQN 越小
-   BPM 越高，MPQN 越小

### 2. 导出 MIDI 时的 TimeMap 平移问题

**关键点**：从 REAPER 导出选定时间段的 MIDI 时，Tempo Map 必须随之平移！

**场景**：

```
原始工程：BPM 变化发生在 3:00
导出范围：1:00 - 2:00
导出结果：BPM 变化应该发生在相对时间 2:00（3:00 - 1:00）
```

**解决方案**：

1. 使用
   eaper.MIDI_GetPPQPosFromProjTime(take, time) 获取绝对 PPQ 位置
2. 计算相对偏移：
   elative_tick = abs_tick - start_tick
3. 所有 Tempo/Time Sig 标记都基于相对位置

**代码示例**：

```lua
local function time_to_tick(calc_take, time, start_time)
    local abs_ppq = reaper.MIDI_GetPPQPosFromProjTime(calc_take, time)
    local start_ppq = reaper.MIDI_GetPPQPosFromProjTime(calc_take, start_time)
    return math.floor(abs_ppq - start_ppq + 0.5)
end
```

### 3. Tempo Map 采集中的时间签名继承

**重要**：Tempo 标记的时间签名可能为 -1/-1，表示**沿用上一个有效值**

**必须实现**：

```lua
local last_valid_num, last_valid_den = nil, nil

for i = 0, marker_count - 1 do
    local _, timepos, _, _, bpm, num, den = reaper.GetTempoTimeSigMarker(0, i)

    if num == -1 and den == -1 then
        -- 继承上一个有效的拍号
        if not last_valid_num then
            return nil  -- 错误：第一个标记不能是继承的
        end
        num, den = last_valid_num, last_valid_den
    else
        -- 更新有效拍号
        last_valid_num, last_valid_den = num, den
    end

    -- 处理标记...
end
```

**为什么重要**：

-   只有 BPM 改变，拍号保持不变时，Tempo 标记返回 -1/-1
-   不能跳过这样的标记，因为 BPM 信息丢失
-   必须保留所有标记以准确重现工程的 Tempo Map

### 4. PPQ 分辨率获取

REAPER 没有直接 API 获取全局 PPQ。**解决方案**：

```lua
-- 使用临时 Take 计算分辨率
local temp_item = reaper.CreateNewMIDIItemInProj(track, 0, 1, false)
local temp_take = reaper.GetActiveTake(temp_item)
local ppq = reaper.MIDI_GetPPQPosFromProjQN(temp_take, 1) -
            reaper.MIDI_GetPPQPosFromProjQN(temp_take, 0)
reaper.DeleteTrackMediaItem(track, temp_item)
```

**原理**：

-   MIDI_GetPPQPosFromProjQN(take, 1) 返回 1 个四分音符对应的 PPQ
-   差值就是分辨率（通常 960）

### 5. 导出流程中的关键步骤

#### 5.1 导出时间到 Tick 的转换

```lua
-- 导出的注意点：start_time 必须作为基准
local start_ppq = reaper.MIDI_GetPPQPosFromProjTime(calc_take, start_time)
local target_ppq = reaper.MIDI_GetPPQPosFromProjTime(calc_take, target_time)
local relative_tick = target_ppq - start_ppq
```

#### 5.2 MIDI 事件顺序

```
初始化事件 (tick=0)：
   轨道名称 (FF 03)
   Set Tempo (FF 51) - 初始 BPM
   Time Signature (FF 58) - 初始拍号
   Reset Controllers (B0 79 00)
   Program Change (Cn pp) - 根据轨道名推断乐器

Tempo Map 事件：
   Set Tempo (FF 51) - 每个 BPM 变化
   Time Signature (FF 58) - 每个拍号变化

音符事件：
   Note On / Note Off
```

**排序规则**：

```lua
table.sort(events, function(a, b)
    if a.tick ~= b.tick then return a.tick < b.tick end
    return a.type > b.type  -- 同 tick 时，Meta 事件优先
end)
```

#### 5.3 乐器推断

```lua
-- 从轨道名称推断 GM 乐器
-- 匹配原理：分词后，计算轨道名中与乐器名的词重叠数
function infer_program_from_track_name(track_name)
    local name_lower = string.lower(track_name)
    local tokens = {}
    for word in string.gmatch(name_lower, "[a-zA-Z0-9]+") do
        table.insert(tokens, word)
    end

    -- 遍历 GM_INSTRUMENTS，找最高匹配度
    -- 返回 Program Change 编号 (0-127)
end
```

### 6. 导入 MIDI 时的静默加载

**问题**：
eaper.InsertMedia() 在导入有 TimeMap 的 MIDI 时会弹窗询问是否导入变奏

**解决方案**：使用 **PCM Source 方法**绕过弹窗

```lua
function insert_midi_via_pcm(file_path, track, start_time)
    -- 1. 创建空的 MIDI Item 作为容器
    local newItem = reaper.CreateNewMIDIItemInProj(track, start_time, start_time + 1, false)

    -- 2. 禁用循环（防止长度错误时重复）
    reaper.SetMediaItemInfo_Value(newItem, "B_LOOPSRC", 0)

    -- 3. 从文件创建 PCM Source
    local pcm_src = reaper.PCM_Source_CreateFromFile(file_path)

    -- 4. 将 Source 关联到 Take
    local take = reaper.GetActiveTake(newItem)
    reaper.SetMediaItemTake_Source(take, pcm_src)

    -- 5. 获取实际长度并更新 Item
    local length = reaper.GetMediaSourceLength(pcm_src)
    reaper.SetMediaItemInfo_Value(newItem, "D_LENGTH", length)

    -- 6. 更新界面
    reaper.UpdateArrange()
end
```

**为什么有效**：

-   PCM_Source_CreateFromFile() 是通用接口，不触发 MIDI 特定逻辑
-   REAPER 自动识别 .mid 文件的 TimeMap 信息
-   **无弹窗**，完全静默

**关键细节**：

-   必须设置 B_LOOPSRC = 0，否则加载可能出错
-   必须获取真实长度，防止 Item 长度不匹配
-   支持导入带 TimeMap 的 MIDI

### 7. 导出文件夹结构

```
outbox/
 {datetime}_{session_id}/
     01_Piano.mid
     02_Violin.mid
     03_Cello.mid
```

**格式**：

```lua
local datetime = os.date("%Y%m%d_%H%M%S")
local folder_name = string.format("%s_%s", datetime, session_id)
```

**文件名规则**：

```lua
local safe_name = track_name:gsub('[%s%p]', '_')
local file_name = string.format("%02d_%s.mid", index, safe_name)
```

**返回值**：

```lua
return {
    path = session_path,           -- 完整目录路径
    folder_name = folder_name,     -- 目录名
    session_id = session_id        -- 会话 ID
}
```

## 实现检查清单

-   [x] Tempo Map 采集时正确处理 -1/-1 时间签名继承
-   [x] 导出时使用相对 Tick 转换（start_time 作为基准）
-   [x] 保留所有 Tempo/Time Sig 标记（包括仅 BPM 变化的标记）
-   [x] 导入使用 PCM Source 方法，无弹窗
-   [x] 验证 MIDI 文件扩展名和文件存在性
-   [x] 乐器推断使用分词匹配（容错性强）
-   [x] 正确获取 PPQ 分辨率（使用临时 Take）
-   [x] 导出多轨到文件夹，返回目录信息
