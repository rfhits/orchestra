---
name: create-song
description: 依据用户需求完成完整歌曲创作与工程组织（歌词与段落结构、风格、BPM/拍号、时长、生成音频、可选分离 stems、结构分析、lead sheet/MIDI、配器、可选导入 REAPER）。当用户请求“写歌/生成歌曲/从歌词生成成品/生成伴奏”等任务时使用。
---

确认必要信息（缺失就先问；若用户明确授权“你来决定/自由发挥”，可由你决定并在回复中写明）：

-   song name（用于文件夹与文件命名；文件夹固定为 /media/songs/{date}-{song-name}，date 使用 YYYYMMDD）
-   语言与风格/流派
-   BPM、拍号、时长
-   若用户明确“你来决定/自由发挥”，允许自行确定 song name/BPM/拍号/时长，并在回复中说明
-   原曲 BPM/拍号
-   是否已有歌词；若没有，是否需要你创作
-   只需要某一子任务还是完整流程（如“只要歌词/只要伴奏/只要导入 REAPER”）

执行流程（按需执行，用户只要子任务就停止）：

1. 在当前项目目录 /media/songs/ 下新建 `{date}-{song-name}` 目录（date=YYYYMMDD；避免覆盖，若已存在先确认），
   并在文件夹内部新建一个 {agent-name}-work.txt，这个文件用来追踪你的创作记录和思考
2. 收集或创作歌词：结构标记必须使用方括号并单独成行，仅允许以下集合：
   [intro] [inst] [verse] [chorus] [bridge] [outro]
   标记行之后为该段歌词直到下一个标记，建议统一小写；
   禁止包含其他 tag，否则 MCP 不识别，
   歌曲的结构参考 [sea_zh.txt](./lyrics-examples/sea_zh.txt) 或 [pop_en.txt](./lyrics-examples/what_en.txt)
   慢歌/抒情： 约 40-60 字/分钟。
   中速/流行： 约 60-90 字/分钟。
3. 保存歌词为 `{song-name}.lyrics.txt`。
4. 生成歌曲音频：使用已知可用的歌曲生成工具；若无可用工具，向用户确认下一步或停止。
    - 保存为 `{song-name}.{ext}`。
5. 可选：分离 stems（如 vocals/instruments）。若无对应工具，提示用户并跳过。
6. 可选：结构分析，生成 `struct.msa.txt`。
7. 可选：生成 lead sheet，保存为 `lead_sheet_auto_analyze.mid`。
8. 可选：读取 lead sheet 的 BPM/拍号并与“原曲 BPM/拍号”比对。
    - 若一致：将 `lead_sheet_auto_analyze.mid` 作为最终 `lead sheet.mid`（复制/重命名均可）。
    - 若不一致：使用可用的 MIDI remap 工具对齐 BPM/拍号，输出为 `lead sheet.mid`。
    - 若无法读取 lead sheet 的 BPM/拍号或缺少 remap 工具：记录原因并询问用户是否手动指定或跳过。
9. 可选：分析 lead sheet/MIDI 结构，保存分析结果文件（命名与结果一致）。
10. 可选：生成配器 MIDI（如 Bass/Guitar/Piano），保存到素材文件夹。
11. 可选：检查配器 MIDI 的 BPM、Time Signature 和 Lead Sheet 是否一致，不一致需要 remap，并直接覆盖原文件
12. 可选：使用 MCP 工具将配器 MIDI 拆分为多个 midi track，保存到素材文件夹
13. 用户要求且存在 REAPER 工具时，导入原曲、stems 与配器 MIDI。
    如果配器轨道被拆分，则新建一个轨道作为各种配器的 parent track，只需要导入拆分后的轨道作为 child tracks

工具选择策略（不写死工具名；以 MCP 工具列表为准）：

-   从当前 MCP 工具列表中按语义匹配选择：结构分析 / BPM-拍号 remap / 配器 / 导入。
-   BPM/拍号 remap 的工具能力要求：至少支持 input_path、output_path、target_bpm、target_ts_num、target_ts_den。
-   若当前 MCP 没有对应能力，先提示用户并跳过该步骤。

操作准则（避免踩坑）：

-   传给 MCP 的本地文件一律使用绝对路径（Windows 全路径），不要相对路径。
-   对每个工具返回值做校验（非空、格式正确、URL/路径可用）。
-   若 MCP 报错或提示“需要 URL/需要上传”，立即使用 upload 工具获得 URL，再重试，不再尝试本地路径。
-   若 upload 工具返回 None/空值/非 URL：判定为工具异常，记录返回值并停止，向用户询问如何处理（如重启 MCP、换工具、跳过该步骤）。
-   若 lead sheet/分析工具返回 None/空值/非 URL：判定为工具异常，记录返回值并停止，向用户询问是否重试或跳过。
-   生成工具返回本地 HTTP URL（如 127.0.0.1）时，立刻下载落盘到素材目录，后续步骤只使用落盘文件。
-   其他失败时先记录原因；若错误信息不足以定位问题，停止并询问用户下一步。
-   生成/分析结果统一落盘：`struct.msa.txt`、`struct.json`、`lead_sheet_auto_analyze.mid`、`lead sheet.mid`、`lead_sheet.analysis.txt`。
-   导入 MIDI 时一律使用 `lead sheet.mid`（不要使用 `lead_sheet_auto_analyze.mid`）。
-   每一步完成后更新“关键产物清单”，方便断点续跑。
-   每一步完成后更新 {agent-name}-work.txt
