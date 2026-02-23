# 当前（2026-01-27）可用的大模型

我们先约定一下术语：

1. song：完整的歌曲，包括配器、vocal
2. audio: 强调 wav 作为输入输出、模型计算空间

最重要的是 lyrics2song models，直接从歌词到一整首歌

代表模型是：

1. DiffRhythm2
2. ACE-Step

这个是一定要集成进去的。

然后是 split_stems 模型，可以把一首歌分出各种轨道，
拆出鼓组、人声、钢琴等。

这个的好处是方便开发者进行二次创作，比如想要替换某一个轨道，自己写一个轨道。
觉得原来的 demo 某个地方不好。
这个很重要是因为 SUNO 也集成了这个功能。
最好的模型是 BS-RoFormer，字节的模型。

在此基础上，我们可以提供一些替换配乐的模型，目前社区里做的有 drums 的。
也就是说我们可以替换鼓组。

还有实时配器的，但是我觉得效果不好。

为了打通符号领域。我们有必要提供一些符号领域的模型。
比如 piano 旋律提取，人声旋律提取。
这能够方便创作者把歌曲扒下来。

最后是符号域最强的模型：
SongComposer 和 MIDI-LLM

SongComposer 太大了，有 12GB，我电脑上没法跑，可以直接依据歌词来作曲
MIDI-LLM 我觉得还是不够好，没法控制长度，对音乐的粒度控制不够。

有个模型叫做 anticipation，这个比较好，用于辅助作曲。

## 没有特别好的 lyrics2midi 模型？

数据太少了。
我让 Gemini 做了 research，得到了如下模型：

-   SongComposer：pjlab 的，太大
-   MidiLLM：太大，没法控制长度
-   MuseCoCo：微软的，太大
-   SymPAC：字节的，不开源
-   XMusic：腾讯的，不开源

[Google Gemini](https://gemini.google.com/app/20fa6050efa1f3b4)

## 总结部署计划

总结起来，我可以快速用于部署的模型有：

|    model     |       usage        | 备注       |
| :----------: | :----------------: | ---------- |
| DiffRhythm2  |    lyrics2audio    | 快速，小巧 |
| BS-RoFormer  |    split_stems     |            |
|   transkun   | extra piano melody |
|     SOME     | extra vocal melody |
| anticipation |      continue      |

如果我非常有时间和精力，可以部署和尝试如下模型（按照优先级排序）：

|     model     |     usage     |                     备注                      |
| :-----------: | :-----------: | :-------------------------------------------: |
|   ACE-step    | lyrics2audio  |   提供量化版本和 Gradio 部署，要费一番功夫    |
| SongComposer  | lyrics2melody |          12GB，可以试试自己量化了跑           |
|   HeartMuLa   | lyrics2audio  | 16GB，据说可以按需加载（3B 模型怎么这么大？） |
| drums compose |               |           自己找一个生成鼓点的模型            |

对于过大的模型，都可以尝试去 GitHub 上找一找有没有量化的版本，比如 Wan2GP，以及 B 站的一键整合包，
然后找到别人的代码魔改一下。

其他基于符号的模型：

-   MuseCoco
-   PopMAG
-   Amadeus
-   Music Transformer (REMI)

但是做的时候，你要思考，为什么要做一个这个东西，

-   对毕业设计有帮助吗？
-   能起到加速工作流的效果吗？
-   真的有人会使用吗？
-   是为了增加毕业设计的工作量而作，还是真的打通了某种痛点？

## 对 agent system 的思考

目前还是停留在工具级别，
不同的工具难以组合形成复合工作流，甚至主导一首歌的完成。

但是结合 agent + reaper，已经可以做一些重复的工作了。

比如，为我生产 50 首歌曲，写好歌词然后，分轨……
帮我把这首歌的谱子扒出来。

为我写一首鬼畜的歌曲：

1. 自动作词
2. 调用 lyrics2song 生成歌曲
3. 导出到本地

帮我把一首歌扒出来：

1. 分离音频轨道
2. 提取 piano 轨道，并得到旋律
3. 提取 vocal 轨道，并得到旋律

为这首歌曲生成鼓点伴奏：

1. 调用 鼓点生成 MCP 即可
2. 插入 REAPER

最好是 audio 为主，因为 midi 不好处理有变奏等

## tool-platform 级别的构建

这个时候就可以利用一些远程的服务器，结合 marketplace 的想法。
我们直接在小窗口里面和 agent 聊天，他会自动 install MCP tool，依据 skills 来进行修改。
