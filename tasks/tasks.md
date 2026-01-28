# tasks

## 进行中

## TODO

-   [ ] 调研并挑选出一个优质的从 stem 提取 MIDI/melody 的模型
-   [ ] 调研并挑选出一个支持配器的模型（given melody，generate instruments like piano, ...）
        我忘记 anticipation 是不是支持了
-   [ ] 将 DiffRhythm2 作为一个独立的服务部署为 MCP，支持 lyrics2audio 调用。
-   [ ] 将 task017 提到的 SOME 和 transkun 部署为服务
-   [ ] 接入自动创作歌词的 Skill，参考 task013
-   [ ] text2midi: 直接从符号角度建模，prompt 到 midi，可以考虑先曲后词，实际很难，因为音乐是有结构的，
        只能说想要一段曲子可以参考这个模型
        [Text2midi - a Hugging Face Space by amaai-lab](https://huggingface.co/spaces/amaai-lab/text2midi)

## 遗留问题

1. 调用 logger 的接口不统一，未来要做成全部使用 logger 模块接口
2. log table 需要 json 打出的 string
3. logger 打印出来的行号总是 logger.lua 的行号
4. 给 clean up 绑定一个脚本快捷键
5. track.create 等 MCP 操作需要设置一个超时时间、以及返回值写到 docstring 中
6. bridge.call_reaper 目前是轮询，写死了超时时间，不知道会不会有性能问题
7. 渲染出文件以后，也要移动到 archive 里面
8. 将 BS-RoFormer 的 MCP 设计为一个支持 task-id, progress query 的形式，这样 agent 就可以去做别的事情了
   目前还是一个 http 长连接，在 kilo 中设置了一个较长的超时时间来实现不超时  
   需要设计一个更优雅的方式支持长连接 MCP tool call，同时保留模型驻留显存

## 已完成

<!-- 将 tasks 下完成的 task 列在这里 -->

12. [音乐制作流程调研](./task012-suvery-music-production.md)
13. [尝试使用 Gemini 等大模型生成音乐歌词](./task013-try-lyrics-generation-with-llm.md)
14. [寻找自动作曲大模型](./task014-look-for-lyrics-melody-model.md)
15. [调研配器分离的音乐模型](task015-look-for-split-stem-models.md)
    调研并挑选出一个优质的 split_stems 的模型: BS-RoFormer
16. [寻找 lyrics2audio 模型](task016-look-for-lyrics2audio-models.md)
    最终选用：DiffRhythm2，可以在 4060Ti 跑
17. [寻找主旋律抓取模型](./task017-look-for-melody-extract-models/task017-look-for-melody-extract-models.md)
    用 SOME 提取人声，用 transkun 提取钢琴
18. [寻找从音频生成伴奏的模型](./task018-look-for-accompaniment-by-audio.md)
    没找着，ACE-step 说 coming soon  
    阿里有一个 MelodyLM 又不发布  
    所以只能尝试 audio 到 symbolic 这条线
19. [当前（2026-01-27）可用的大模型](./task019-current-usable-models.md)
    罗列打算接入的模型:
    -   BS-RoFormer
    -   DiffRhythm2
    -   transkun
    -   SOME
    -   anticipation
20. [设计接入大模型的 mcp 架构](./task020-design-mcp-architect.md)
21. [将 BS-RoFormer 接入 MCP](./task021-pack-bs-rofomer-mcp.md)
