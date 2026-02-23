# 封装歌曲结构识别 MCP

这部分我试了一些模型，效果都不是很好，最终使用了 [rfhits/songformer_mcp](https://github.com/rfhits/songformer_mcp)。

两条路：

1. 基于歌词指定的结构识别
2. 基于歌曲直接分析的段落分析（采用）

## 歌词匹配段落结构

### whisperX 构想

whisperX，这个是从音频里面得到文字（transcribe）以及语句的时间范围，

然后再从大致的时间范围里面去做 force alignment

坏处：识别不精准，字会听错
好处：非常快，格式友好

### chasiu

chasiu：一个支持 text alignment 的模型，但是非常慢，估计要 3 min，出来的也不是 标准的格式，而是 textgrid
好处就是比较准

还有一个挂羊头卖狗肉的模型，叫做 ctc-forced-aligner
说起这个我就烦，每个模型都要配环境，配好了效果还不一定好。
浪费时间

### 测评总结：太慢了放弃

目前的想法是，让 whisperX 去先跑一遍，快速得到一份转录的文件，1min 内搞定
然后启动一个 subagent，subagent 会给 标准的 suno 文件的格式，然后再把 whisperX 快速听一遍的结果给 sub agent。

```
[verse]
...

[chorus]
```

sub agent 自动猜测出每个 `[verse]` `[chorus]` 对应的时间是什么时候了。
这样，我们就可以得到乐曲的段落结构，比如 i4A4B4A4B4C5
划分出每个 structure segment

whisperX 命令：

```sh
TORCH_FORCE_NO_WEIGHTS_ONLY_LOAD=1 uvx whisperx vocals.wav --language zh --device cuda
```

## 基于整首歌分析结构

其实还有一个模型，本身就是做这个 segment 识别的，但是我觉得那个可能效果不好，
[mir-aidj/all-in-one: All-In-One Music Structure Analyzer](https://github.com/mir-aidj/all-in-one/blob/main/pyproject.toml)

但是又发现一个更强的模型：SongFormer，原生 Gradio
[ASLP-lab/SongFormer](https://github.com/ASLP-lab/SongFormer/tree/main)
