# 测试 take 和 items 功能

## 目标

验证两件事：

1. 能清楚看到某条 track 上有哪些 items（位置、长度、GUID）
2. 在不知道 item*guid 的情况下，`take.add*\*` 也能稳定落到目标 item（或按策略新建）

## 测试覆盖范围

### A. Item 观测能力

-   在指定位置新建 item（秒/小节）
-   按 track 拉取 items 列表：`item.list_by_track`
-   指定时间点定位 item：`item.find_at_second` / `item.find_at_measure`
-   验证 item 长度字段（秒与小节）

### B. Take 添加行为

-   指定 `item_guid` 添加 takes（基线）
-   仅指定 `track+time` 添加 takes（关键）
-   验证 `item_match_mode`：
    -   `cover_or_create`：复用覆盖项（默认）
    -   `exact_start`：只复用起点一致项
    -   `always_new`：总是新建

## 测试样例（JSON）

-   [x] `test/item/item_create_at_second_test.json`
-   [x] `test/item/item_create_at_measure_test.json`
-   [x] `test/item/item_list_by_track_test.json`
-   [x] `test/item/item_list_by_track_range_test.json`
-   [x] `test/item/item_find_at_second_test.json`
-   [x] `test/item/item_find_at_measure_test.json`
-   [x] `test/take/take_add_at_second_cover_or_create_test.json`
-   [x] `test/take/take_add_at_second_always_new_test.json`
-   [x] `test/take/take_add_at_measure_cover_or_create_test.json`

## 预期结果（重点）

1. `item.list_by_track` 返回 item 列表，至少包含：
    - `item_guid`
    - `position_sec/end_sec/length_sec`
    - `position_measure/end_measure/length_measure`
2. `take.add_at_second` 在默认模式下，命中已有覆盖 item 时返回同一个 `item_guid`
3. `take.add_at_second(item_match_mode=\"always_new\")` 返回新的 `item_guid`

## 真实使用流程（面向续写）

1. agent 用 `item.list_by_track` 找到目标 item 和长度
2. 导出该片段，调用续写模型得到多个候选 MIDI/audio
3. 用 `take.add_at_*` 写回（默认复用覆盖 item）
4. 用 `take.list` 和 `take.set_active` 做候选切换试听
