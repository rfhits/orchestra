# 调研自动作曲大模型

用户输入如下信息，然后我们调用大模型得到歌词和旋律。

接入方式： MCP/agent?

先看下 SongComposer 的效果

从宣传主页上看，支持
1. lyrics => melody
2. melody => lyrics
3. ...

我们暂时先不管那么多，task013 已经有了歌词

SongComposer demo 只有 demo，没有 how to run, user inputs

SongComposer 从 HuggingFace 下载后，在我的机器上没法运行，因为显存太小，搁置
