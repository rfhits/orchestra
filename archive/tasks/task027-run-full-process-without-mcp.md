# 不用 MCP 跑通流程

1. 使用 ACE-step 生成一首音乐： sea.wav
2. 使用 sheetsage 从音乐中获取 lead sheet, in wsl docker, 30s 左右
3. 使用 split stems 将 sea 的 vocal 分离，耗时 1min，
   而且报 warning SageAttention not found，如果 wsl 可能会更快
4. 得到音乐结构分段
    1. agent 得花 4:30 才行，估计是废了，
    2. SongFormer: 目前的 SOTA 模型，可以给出歌曲的 分段以及时长，如 verse 起止时间，chorus 起止时间
       但是还是不确定 BPM 是多少，虽然 lead sheet 给出的 bpm 是 120，但是谁知道自己搞了一个 BPM，然后以这个 BPM 为基准去算的呢？
       不知道 lead sheet sage 有没有做了 remap
    ```
    0.00 intro
    10.32 verse
    31.56 verse
    51.12 chorus
    82.08 inst
    101.28 verse
    122.88 chorus
    152.53 bridge
    168.01 bridge
    182.89 chorus
    198.13 chorus
    215.53 outro
    238.33 silence
    239.89 end
    ```
5. 计算 segmentation
   如上文，BPM120，也就是说 0.5s 一拍
   发现 lead sheet 是 4/16，太奇怪了，如果真的要用于实际的话，需要 remap。
   那么就是 2s 一小节
   由此计算出： i5A11A10B15D10A11B15C7C8B7B9O11S1
6. 使用 Structural Arrangement 为 sea 配器 midi
7. vocal 和 midi 导入到 reaper 中，听一下效果

完成，但是效果感觉不太好。
因为没有音区避让，然后因为配器不是根据人声出的，是从 钢琴里面推导出来的
所以混音效果不好
