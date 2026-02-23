# item 模块新增 split / merge / delete 接口

## 背景

当前 `item` 模块已有创建、查询、定位、改长度能力，但缺少编排编辑中最常用的三类操作：

1. 按绝对时间切分 item
2. 将多个 item 合并为一个 item
3. 按 GUID 删除 item

在自动化编曲/结构重排中，这三类能力属于基础编辑原语，需要通过 MCP 暴露给上层流程。

## 目标

在保持接口简洁的前提下，新增以下 MCP 接口：

- `item.split(item_guid, times)`
- `item.merge(item_guids)`
- `item.delete(item_guid)`

并统一采用 GUID 作为 item 标识。

## 接口约束

### item.split

- 入参：
  - `item_guid: str`
  - `times: List[float]`（项目绝对秒数）
- 规则：
  - `times` 必须严格递增
  - 每个切分点必须严格位于 item 内部（不能等于起止点）
  - 任一非法则整体失败（严格模式）
- 出参：
  - 原 item GUID
  - 生效的切分点列表
  - 切分后 item 列表（含 GUID/位置/长度等详细信息）

### item.merge

- 入参：
  - `item_guids: List[str]`
- 规则：
  - 至少两个 item
  - 必须全部存在
  - 必须位于同一轨道
  - 按时间排序后必须连续或重叠（不允许间隙）
- 出参：
  - 原 item GUID 列表（排序后）
  - 合并后新 item 的详细信息

### item.delete

- 入参：
  - `item_guid: str`
- 出参：
  - `deleted: true`
  - 被删除的 GUID

## 实现范围

### Python

- 更新 `mcp_tools/item.py`
  - 新增 `split() / merge() / delete()`

### Lua

- 更新 `reaper_scripts/item.lua`
  - 新增 `M.split / M.merge / M.delete`
  - split 使用 `SplitMediaItem`
  - merge 使用选中 + Glue 命令流程
  - delete 使用 `DeleteTrackMediaItem`

## 错误码

- `INVALID_PARAM`：参数类型、范围、顺序不合法，或 merge 约束不满足
- `NOT_FOUND`：目标 item 不存在
- `INTERNAL_ERROR`：REAPER API 执行失败

## 验收标准

1. split 成功后返回多个新段 item，位置与长度正确
2. split 对无效切分点整体报错，不部分执行
3. merge 对同轨道连续 item 成功，返回新 item GUID
4. merge 对不同轨道/有间隙输入直接报错
5. delete 成功后通过 `find_by_guid` 无法再找到该 item
