# 封装 Structural Arrangement 为 MCP

这个其实比较复杂
虽然说这是一个可以从一首歌生成编曲的模型
但是，它需要两个前置输入：

1. Note Shift：找到整首歌的第一个 downbeat，也就是起拍的地方。
2. Segmentation：乐曲的结构，如 i4A2B2 这种

所以不能光看模型的效果，还要看约束。

关于 note shift，如果我们有 midi 文件，大概是可以判断出来的，
实在不行，你就填 0。反正音乐开头会有 intro。

为了让这个东西在 Windows 上跑起来，改了一些 torch 相关代码。
尤其是那个 tensor int32 不能作为 index，因为 windows 上 tensor 默认是 int32，linux 上是 64 bit。

我怀疑是 long 这个数据类型 windows 和 linux 不一样导致的。

[rfhits/structured_arrangement_mcp: Code and demo for paper: Zhao et al., Structured Multi-Track Accompaniment Arrangement via Style Prior Modelling, in NeurIPS 2024.](https://github.com/rfhits/structured_arrangement_mcp)
