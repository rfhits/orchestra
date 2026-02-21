# REAPER Marker CRUD 接入 MCP

## 背景

目前 Orchestra 已支持轨道、项目、音频、MIDI、item/take 等能力，但还缺少项目结构标注能力。  
在实际编曲流程里，需要在时间线上打 `Verse`、`Chorus`、`Bridge` 等 marker，便于 AI 与人协同编辑。

## 目标

在保持接口简单的前提下，新增 marker 的基础 CRUD：

1. 在某个时间点创建 marker
2. 获取当前工程所有 marker
3. 修改 marker 描述
4. 删除 marker

## 范围

### In Scope

- 新增 `marker` MCP 模块（Python + Lua）
- 新增接口：
  - `marker.create(time, desc)`
  - `marker.list()`
  - `marker.update(marker_id, desc)`（仅修改描述）
  - `marker.delete(marker_id)`
- 接口参数校验、错误码与日志
- 更新 loader/main 初始化流程
- 补充 REAPER 侧测试请求样例

### Out of Scope（本任务不做）

- region CRUD
- marker 颜色设置
- 批量增删改
- 小节维度接口（如 `create_at_measure`）
- marker GUID 作为主标识

## 设计约束

1. 标识符采用 `marker_id`（REAPER marker 编号）
2. `update` 仅更新描述，位置保持不变
3. 保持现有协议风格：`return true, result` / `return false, {code, message}`
4. 修改类操作统一走 Undo 包裹并 `UpdateArrange()`

## 接口草案

### marker.create

- 入参：
  - `time: number`（秒，`>=0`）
  - `desc: string`
- 出参：
  - `marker_id: number`
  - `time: number`
  - `desc: string`
  - `created: true`

### marker.list

- 入参：无
- 出参：
  - `markers: array`
  - `count: number`
- `markers[i]` 结构：
  - `marker_id: number`
  - `time: number`
  - `desc: string`

### marker.update

- 入参：
  - `marker_id: number`
  - `desc: string`（允许空字符串，表示清空描述）
- 出参：
  - `marker_id: number`
  - `time: number`
  - `desc: string`
  - `updated: true`

### marker.delete

- 入参：
  - `marker_id: number`
- 出参：
  - `marker_id: number`
  - `deleted: true`

## 实现清单

1. Python 侧新增 `mcp_tools/marker.py`
2. Lua 侧新增 `reaper_scripts/marker.lua`
3. 在 `orchestra_loader.lua` 注册 `marker` 模块
4. 在 `orchestra_main.lua` 初始化 `modules.marker`
5. 新增 `reaper_scripts/test/marker/*.json`
6. 更新 `reaper_scripts/test_runner.lua` 菜单入口

## 验收标准

1. 可以成功创建并看到 marker
2. `marker.list` 可返回所有 marker，且不包含 region
3. `marker.update` 可修改描述，并支持清空描述
4. `marker.delete` 删除后列表中不可见
5. 非法参数返回 `INVALID_PARAM`
6. marker 不存在返回 `NOT_FOUND`

