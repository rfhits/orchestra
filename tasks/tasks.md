# tasks

## 进行中

[](task015-investigate-split-stem-models.md)

## TODO

- [ ] Task 020: Standardize packaging and distribution (Implement Task 019 roadmap)
    - [ ] Update pyproject.toml for PyPI publishing
    - [ ] Implement lazy loading for large models (BS-RoFormer, etc.)
    - [ ] Create Dockerfile and smithery.yaml
- [ ] 调研并挑选出一个优质的从 stem 提取 MIDI/melody 的模型
- [ ] 调研并挑选出一个支持配器的模型（given melody，generate instruments like piano, ...）
    我忘记 anticipation 是不是支持了
- [ ] 将 DiffRhythm2 作为一个独立的服务部署为 MCP，支持 lyrics2audio 调用。
- [ ] 将 BS-RoFormer 作为一个独立的服务部署为 MCP，需要：
    1. 锁定版本
    2. 独立成为仓库
    3. 对外暴露 HTTP 接口或其他方式，可以考虑使用 Gradio
- [ ] 将 task017 提到的 SOME 和 transkun 部署为服务
- [ ] 接入自动创作歌词的 Skill，参考 task013


## 遗留问题

1. 调用 logger 的接口不统一，未来要做成全部使用 logger 模块接口
2. log table 需要 json 打出的 string
3. logger 打印出来的行号总是 logger.lua 的行号
4. 给 clean up 绑定一个脚本快捷键
5. track.create 等 MCP 操作需要设置一个超时时间、以及返回值写到 docstring 中
6. bridge.call_reaper 目前是轮询，写死了超时时间，不知道会不会有性能问题
7. 渲染出文件以后，也要移动到 archive 里面

## 已完成

<!-- 将 tasks 下完成的 task 列在这里 -->

13. [尝试使用 Gemini 等大模型生成音乐歌词](./task013-try-lyrics-generation-with-llm.md)
14. [寻找自动作曲大模型](./task014-look-for-lyrics-melody-model.md)
15. [调研配器分离的音乐模型](task015-look-for-split-stem-models.md)
    调研并挑选出一个优质的 split_stems 的模型: BS-RoFormer
16. [寻找 lyrics2audio 模型](task016-look-for-lyrics2audio-models.md)
    最终选用：DiffRhythm2，可以在 4060Ti 跑
17. [寻找主旋律抓取模型](./task017-look-for-melody-extract-models/task017-look-for-melody-extract-models.md)
    用 SOME 提取人声，用 transkun 提取钢琴
19. [MCP Server 标准化分发调研](./task019-mcp-distribution-and-packaging.md)