# 调研 split stems 模型

1. demucs

## demucs

demucs 是一类模型，有 v3 和 v4.

模型的 GitHub page 上写了一堆，啰嗦死了，但是 v4 不支持出 piano，出不了四大件，只能出：
1. bass
2. drums
3. vocal
4. other

所以我觉得不好用

## BS RoFormer

这是 字节的 paper，得到了一个超级好的效果 Band Split RoFormer,用了 ROPE。

https://github.com/ZFTurbo/Music-Source-Separation-Training/blob/main/README.md

这是一个地址，我看到开源了很多模型，像是在做统一的管理。

不错，就决定使用 BS-RoFormer 了，HuggingFace 上有一个更好的权重，可以分离出 Piano

[jarredou/BS-ROFO-SW-Fixed at main](https://huggingface.co/jarredou/BS-ROFO-SW-Fixed/tree/main)

我也 fork 了一份 GitHub 代码到自己的仓库

Music-Source-Separation-Training 这个仓库做的太臃肿了。
我觉得很难用一个包管理适配所有的模型，而且用的还是 pip + requirements 迟早得和 Microsoft 的 Musiz 项目一样。

形成文档到 [BS-RoFormer](../docs/music-models/BS-RoFormer/bs-roformer-usage.md)