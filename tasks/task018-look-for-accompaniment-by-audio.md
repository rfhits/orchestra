# 寻找 从音频生成伴奏的模型

关注：

1. 模型运行所需显存大小
2. 模型能否用 text prompt 指定风格
3. 生成的音乐长度

### ACE Step

用的人最多。

```sh
uv add torch torchvision torchaudio \
  --index-url https://download.pytorch.org/whl/cu126 \
  --extra-index-url https://pypi.org/simple
```

但是主页说 coming soon，未来可能会发布。

### stream music gen

不支持 prompt，但是可以从配乐生成配乐。

论文说是支持 audio => 配乐，但是 demo 页面没放
说明可能支持的还不太好吧，应该是心虚了。

[[2510.22105] Streaming Generation for Music Accompaniment](https://arxiv.org/abs/2510.22105)
[Streaming Generation for Music Accompaniment](https://lukewys.github.io/stream-music-gen/)

### llambda

支持 text prompt
只是说在 10s 上得到了 audio，
GitHub 上还说，prepare for 20s audio，说明目前对 分钟级别长度还是不太行的。

[SongGen-AI/LLambada: Llambada: Simple Text Controllable for accompaniment generation](https://github.com/SongGen-AI/LLambada?tab=readme-ov-file)
[songgen/Llambada · Hugging Face](https://huggingface.co/songgen/Llambada)

### fastSAG

也是在 10s 的 audio 训练的，
不支持 prompt
[chenjianyi/fastsag: FastSAG: Towards Fast Non-Autoregressive Singing Accompaniment Generation](https://github.com/chenjianyi/fastsag)

### SingSong by Google Research

没有官方仓库，只有爱好者实现的版本，先不考虑

[[2301.12662] SingSong: Generating musical accompaniments from singing](https://arxiv.org/abs/2301.12662)
[jihoojung0106/open-singsong: Open SingSong - Implementation of 'SingSong: Generating Musical Accompaniments from Singing' by Google Research, with a few modifications](https://github.com/jihoojung0106/open-singsong)

### 无关仓库

InstructMusicGen: 文本要求编辑，比如加一个 配器，提取配器，有 failed case
