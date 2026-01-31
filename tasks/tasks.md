# tasks

## 进行中

mureka API 太贵了，只是做一个 demo，但是他们说可以 talk to sales

## TODO

-   [ ] 将 ACE-step 作为一个独立的服务部署为 MCP，支持 lyrics2audio 调用。
-   [ ] 调研并挑选出一个支持配器的模型（given melody，generate instruments like piano, ...）
        我忘记 anticipation 是不是支持了
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
9. BS-RoFormer 可以写一个 Installation.md 作为文档
10. 目前以下的 MCP 都是以本地文件系统的方式返回任务完成，需要考虑改进成 http 格式
11.

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
22. [将 transkun 封装为 MCP 并接入](./task022-pack-transkun-as-mcp.md)
23. [将 SOME 封装为 MCP 并接入](./task023-pack-some-as-mcp.md)
24. [将 Ace-Step 封装为 MCP 并接入](./task024-pack-ace-as-mcp.md)

## 思考

我觉得我们应该做符号主义得路线
因为就算 AI 可以直出 audio form 的音乐
对于创作者而言，也需要 的是符号主义的助手。
只有符号主义才能精确表达一首歌曲

而且 audio 有一个问题，就是它省略了所有音乐编辑过程的细节
导致音乐不再精细了，变成了一种没有人情感混合的、流水线一样的工具。
高级的创作者没有被激发灵感，创作者是需要思考编曲的样式、乐器的排布的
而不是通过调整 prompt，来生成一首歌曲，给大众聆听。

音乐创作的过程是需要思考、不断从人的反馈中调整，然后打磨的
这个和写代码是不一样的。写代码，只需要 pass 所有的 test case 就好了
但是音乐不一样，一个效果出来以后，人要听一下。

优秀的音乐作品是需要人的思考和构思的，不是从 一个 latent space 里面 diffusion 出来的

## sudo 调研

首先是有一个分轨的功能，这个我们也有

Suno 做了一个录制一段旋律自动转对应乐器的功能，底层是通过生成一首新的歌曲，然后 extract 对应的 track 实现
这个比较好，但是 up 没有复现该功能

[Suno Studio 上线，AI 音乐的岔路口\_哔哩哔哩\_bilibili](https://www.bilibili.com/video/BV1kCHsz1Eyf/?spm_id_from=333.337.search-card.all.click&vd_source=43fe2cf82e1bf165ed419caae476ee51)

需要快速地在一个指定的时间区间内，生成素材，比如某一个乐器，可以提供 prompt。
有 风格、BPM，就会生成一小段、多个版本的，供创作者使用

有杂音，区间内的和区间周围的乐器的音色不一致
不干净，新轨道生成本质还是走分离路线，有杂音

midi 的提取也做的不好，是从 音频得到的

> 至于大家为什么会执着于 GetMIDI 功能，本质原因其实很明确：很多用户需要把 Suno 生成的内容导入其他 DAW，去做更精细的二次编辑 —— 比如调整音符细节、更换音色、优化编曲层次等等。而目前的 Suno Studio，还没办法单靠自己达成这种 “全流程自主制作” 的期待。对于一个以 “DAW” 为定位的工具来说，这种 “需要依赖其他软件补全流程” 的状态，确实还有不小的提升空间。

目前 Suno 的定位是 灵感提供，而非专业的精细化的编辑。

如果真的想要没有杂音，那你得上 符号表达。

## 定位

既然决定走符号化的路线，就和 Suno 不一样了。
符号化的路线可以做的就多了，符号化目前最好的是歌词作曲。

第二个定位是编曲，因为编曲符号化可以没有杂音。
然后编曲出来的音乐，他需要一个效果
