# 音乐编辑

这应该被设计成一个 SKILL，供 agent 调用。

## 设想中的最佳编辑方式

在一个项目里面，我们选中一个轨道，轨道上有音频也好，没有音频也罢
轨道上是 midi 也好，是 audio 也好
我们可以 selection 一段区间，然后说 prompt。

prompt 可以是指令 + 引导，比如：

1. 我希望将这一段选区内的钢琴 MIDI 重新编曲，我希望用小调，悲伤一些。
2. 加入一轨道的 drums，摇滚风格
3. 这里 vocal 应该有 rubato，我唱一段给你听，你参考着修改
4. 我希望为这段音乐加入一个淡入的效果

为了得到这样的大模型，我们反向思考，我们要如何训练，才能得到这样一个大模型呢？

音乐不能是简单的 MIDI 格式了，我们必须有文本来辅助大模型来理解旋律走向和情感
大模型需要输入一些音乐的概念、知识，并且将其和 MIDI、audio 联系起来。
换而言之，user prompt 都是文本（音乐的概念）、midi 和 audio
但是现在大模型的训练，侧重的是 lyrics 、 audio 和 MIDI，而非在音乐知识上和音乐作品联系起来。

但是经过目前的调研，没有开源的大模型能够做到这一点。

## 必要模块

音频从 MIDI 这一步，
主旋律不一定来自 vocal，因为vocal 有时候会空白
我们需要一个可以从 audio 中提取 melody 的模型，这个 melody 类似于歌曲中能量的概念，比如一首歌每个时间，总是有几个音高是最强的，人可以跟着哼
就是 melody，不一定从 vocal 轨道中提取
再不济我们也需要一个模型来从 wav 提取 pitch


## 音频方式

有如下流程：

1. 输入歌词（Suno 格式的），同时可以附带风格、audio reference，然后得到音频文件
  音频文件中，有各种轨道
2. 将音频拆分出 vocal、instruments 等 stem track
3. 从 stem track 中提取主旋律/和弦 whatever 你叫他什么，总之可以从 audio 得到很多 midi 轨道
    - vocal ：一般是主旋律
    - piano: chords/melody，这个一般不太好变化
    - bass/guitar/drums: 可以基于这些轨道进行二次创作，比如局部修改、续写……
4. 基于多个 MIDI 轨道进行进一步编辑。可提供的任务包括 [[music-model-abilities]](./music-model-abilities.md)
5. 加 effects、混音等操作

## 符号方式

流程如下：

1. 输入歌词，自动作曲（SongComposer、TeleMelody）等，得到 melody MIDI 轨道
2. 依据 melody 轨道进行 AI involved 开发
3. 和弦进行（chord progression）生成
4. 配器 MIDI 轨道生成
5. 基于配器 MIDI 轨道进行进一步编辑
6. 添加 effects、混音等操作
