# reaper takes 操作接入 MCP

当大模型生成续写候选时，需要把多个候选落在同一个 item 的多个 takes 上。
这里的关键是：不仅要能 add take，还要能定位和观测 item。

## 方案：Item/Take 双模块 + 秒/小节双接口

### 模块拆分
- item.lua：创建/查找/列表化 item，支持时间定位
- take.lua：添加/列出/激活 take，支持 item 匹配策略

### MCP API（Python -> REAPER）

item:
- item.create_at_second({ track, second, length })
- item.create_at_measure({ track, measure, length })
- item.find_by_guid({ item_guid })
- item.set_length({ item_guid, length })
- item.list_by_track({ track, begin_second?, end_second?, include_takes? })
- item.find_at_second({ track, second, match_mode?, include_takes? })
- item.find_at_measure({ track, measure, match_mode?, include_takes? })

take:
- take.add_at_second({ item_guid? | track+second, files, item_match_mode?, names?, set_active?, length? })
- take.add_at_measure({ item_guid? | track+measure, files, item_match_mode?, names?, set_active?, length? })
- take.list({ item_guid })
- take.set_active({ item_guid, take_index? | take_guid? })

### item_match_mode（新增）
用于 `take.add_at_second/add_at_measure` 在未提供 `item_guid` 时如何定位 item：

- `cover_or_create`（默认）：优先复用“覆盖该时间点”的已有 item，否则新建
- `exact_start`：仅复用起点与时间点一致的 item，否则新建
- `always_new`：总是新建 item（保持旧行为）

### 关键实现点
- item GUID 查找：`CountMediaItems + GetSetMediaItemInfo_String("GUID")`
- 轨道内 item 枚举：`GetTrackNumMediaItems + GetTrackMediaItem`
- item 时间：`GetMediaItemInfo_Value(D_POSITION, D_LENGTH)`
- 秒/小节转换：`time_map.second_to_measure`, `time_map.measure_to_second`
- take source：`PCM_Source_CreateFromFile`
- MIDI lengthIsQN 转秒：`TimeMap2_timeToQN + TimeMap2_QNToTime`
- item length 策略：`max(旧长度, 新增 takes 最大长度, 显式 length)`

### 关键 API（来自 docs/standards/reaper-api-functions.md）
- `GetTrackNumMediaItems`
- `GetTrackMediaItem`
- `GetMediaItemInfo_Value`
- `GetMediaItem_Track`
- `GetSetMediaItemInfo_String`
- `AddTakeToMediaItem`
- `CountTakes`
- `GetTake`
- `GetActiveTake`
- `SetActiveTake`
- `TakeIsMIDI`
- `GetMediaItemTakeByGUID`
- `GetSetMediaItemTakeInfo_String`
- `PCM_Source_CreateFromFile`
- `GetMediaSourceLength`
- `GetMediaSourceFileName`
