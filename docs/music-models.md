我们还需要考虑一个事情就是，要考虑到 流派 和 风格 对歌曲信息的影响

先有风格，风格下面再分流派

风格关键词：
流派/style：Classical 古典，类似管弦乐团, Pop , Country, jazz

Jazz，节奏型上没有那么 hard，用 wind 吹奏类乐器多，切分复节奏
Rock: 传统四大件，吉他 贝斯 键盘 鼓组
Blue: 有所谓蓝调音阶，
蓝调音阶（Blues Scale）是一种基于五声音阶（通常是小调五声音阶）并加入一个“蓝色音符”（Blues Note）的六音音阶，这个蓝色音符通常是减五度音（或增四度音），创造出一种独特、略带忧郁和“失调”的色彩

blues 和 Jazz 本身有区别，然后可以听 镲片，jazz 镲片

音色：温暖的，明亮的，破碎的，
BPM：120 etc
调式：A maj，C maj
拍号：4/4， 5/4， etc
演唱风格：可以忽略
情绪：悲伤的，快乐的，怀旧的，忧郁的

所以当一个用户来 request 一个歌曲的时候，我们一般是给他 rock 的类型，
对于 Jazz 和 Blues，我们需要专门的 agent 或者给 agent 配置专门的 prompt 来做。

[CoComposer](https://www.doubao.com/pdf/36260033214386434/https%3A%2F%2Farxiv.org%2Fpdf%2F2509.00132?from_source=from_extention_read_pdf_arxiv&pdf_reading=1)
[[2509.00132] CoComposer: LLM Multi-agent Collaborative Music Composition](https://arxiv.org/abs/2509.00132)
一个用文字 agent 生成 简单旋律和伴奏的 agent 系统，用了 AutoGen
或许可以参考 prompt

我们的需求是给出一段 MIDI 旋律，然后生成另一段 MIDI 旋律，然后这个段 MIDI 它应该是有可以指定乐器的，这是最基础的功能，就是 reference 生成功能。然后第二个功能就是我可以在这个 reference 上面增加一些约束，比如说整个音乐色彩的约束，然后比如说调式的约束、拍号的约束、情绪的约束。对，就是这样，首先你要有那个 reference 生成的功能，然后后面是这种色彩的功能

公开了源代码和训练方法、模型权重吗？

1. 这个模型的输入输出是什么？请举例子说明
2. 能不能用一段指定好的主旋律（MIDI），然后去生成和弦进行（MIDI），
3. 能不能用和弦进行（MIDI），或者主旋律（MIDI）去生成一些指定乐器的配乐？
4. 能不能指定音乐的色彩、情绪、风格、拍号、BPM？
5. 模型生成的旋律的时间是多长？

|    model     | melody2chords | chords2instrument |          code          |
| :----------: | :-----------: | :---------------: | :--------------------: |
|   MoonBeam   |               |                   | 只有 GitHub 估计那麻烦 |
|   MIDI-GPT   |               |                   |   有 colab 但是报错    |
| Figaro(2023) |               |                   |         colab          |

来源 genmusic_demo_list

-   [ ] lyrics agent: we can use Any LLM with web search ability to write songs in given structure(V-C-V-C-B-C)

[手把手教你用最新的 AI 音乐模型，创造一首属于你自己的歌。](https://mp.weixin.qq.com/s/EIiRkscoQxVEYIOLb_RWsA)

## 架构

风格、情感、内容

-   [ ] melody agent: SongComposer from github, pjlab
-   [ ] arrangement agent: write piano/guitar/bass/drums for the melody,
        missing: chord progression agent?
-   [ ] mixing agent
-   [ ] mastering agent

non-functional agent:

-   [ ] revise agent: if some agent output ABC format, check it
        if there is some error/mistake in ABC format, feedback to the agent
-   [ ] review agent(optional): listen the song/track, give feedback

tool:

-   [ ] ABC2MIDI
-   [ ] MIDI2ABC
-   [ ] MIDIRender: render to wav, so we can use some audio model to give feedback

上面是构想，下面我找了一些模型，算备选：

参考 compose multi-track symbolic music 部分按照时间排列：

## Figaro melody/chords => instruments

GitHub stars: 164

甚至支持人描述去写一些东西指导生成，高优先级
还上了 soundcloud

[豆包 - 字节跳动旗下 AI 智能助手](https://www.doubao.com/pdf/36282382968269314/https%3A%2F%2Fopenreview.net%2Fpdf%3Fid%3DNyR8OZFHw6i?from_source=from_extention_read_pdf_pdfviewer&pdf_reading=1)

[dvruette/figaro: Source code for "FIGARO: Generating Symbolic Music with Fine-Grained Artistic Control"](https://github.com/dvruette/figaro)

## MoonBeam 可以做多轨，估计比较麻烦

-   [Moonbeam](https://arxiv.org/pdf/2505.15559) (transformer; guo25arxiv): https://aim-qmul.github.io/moonbeam-midi-foundation-model/

就是说他训练了一个基座模型，然后在这个基座模型上面微调，所以我们到时候会拿到两个文件，两个 checkpoint，第一个是基座模型的，然后是一个微调的，我看起来是蛮复杂的，因为你要自己下来，然后指定路径，而且它的那个使用说明书。不是很非常的详细，就是我估计得自己摸索一段时间，然后他用的是 touch，然后。常言之，我屏幕的这个东西的话，蛮久时间了，我评估就能消化很久时间的，然后能不能生成其他轨道的画？他没有说，很拍着胸脯的保证说，哦，我这个是在 pop 的数据集上去练的。所以说优先级要低一点。

[guozixunnicolas/Moonbeam-MIDI-Foundation-Model](https://github.com/guozixunnicolas/Moonbeam-MIDI-Foundation-Model)
[MoonBeam: MIDI Foundation Model](https://aim-qmul.github.io/moonbeam-midi-foundation-model/?idx=2#accompaniment-example)
[豆包 - 字节跳动旗下 AI 智能助手](https://www.doubao.com/pdf/36276905395618818/https%3A%2F%2Farxiv.org%2Fpdf%2F2505.15559?from_source=from_extention_read_pdf_pdfviewer&pdf_reading=1)

## NotaGen 古典音乐，暂时不看

-   [NotaGen](https://arxiv.org/abs/2502.18008) (transformer; wang25arxiv): https://electricalexis.github.io/notagen-demo/

## MIDI-GPT Colab 报错，暂时不看

-   [MIDI-GPT](https://arxiv.org/abs/2501.17011) (transformer; pasquier25aaai): https://www.metacreation.net/projects/midi-gpt

提供了一个页面，同时也做了 Colab 的 Demo，很好，值得试一下
https://www.metacreation.net/projects/mmm-multi-track-music-machine

但是我自己在实际测试跑这个 demo 的时候，在 colab 里面嘛，报错了，所以还是得研究一下，不是开箱即用的那种，
[MMM_LBD.ipynb - Colab](https://colab.research.google.com/drive/1gzM5Fw2pyWqTqlnkOKlUWO91WCg1m3LJ?usp=sharing#scrollTo=23rSUUkOI-Re)

## Cadenza 别用，没有 code

-   [Cadenza](https://arxiv.org/abs/2410.02060) (transformer; lenz24ismir): https://lemo123.notion.site/Cadenza-A-Generative-Framework-for-Expressive-Ideas-Variations-7028ad6ac0ed41ac814b44928261cb68

这篇文章本身没有提到自己的模型，但是在评估方法种，用了别人的开源模型。
所以可以看他使用的开源模型的权重。

n Part B, the same 25 human evaluators also rated 3 un-
conditional generations from Cadenza, Anticipatory Music Transformer (AMT) [14] 1 and Figaro [15] models, which broadly represent the state-of-the-art in symbolic polyphonic generation. We randomly sampled 3 generations from publicly-available checkpoints of each model,
all of which were trained on identical versions of the Lakh MIDI dataset [27], and present the results in Table 3.

## SymPac 别用，没有公开代码和权重

[SymPAC](https://arxiv.org/abs/2409.03055) (transformer; chen24ismir): n/a

## MMT-Bert 别用，没代码

-   [MMT-BERT](https://arxiv.org/abs/2409.00919) (transformer; zhu24ismir): n/a

## nmt 可以是可以，但是看起来麻烦，豆包说不清楚

-   [Nested Music Transformer](https://arxiv.org/abs/2408.01180) (transformer; ryu24ismir): https://github.com/JudeJiwoo/nmt

[JudeJiwoo/nmt](https://github.com/JudeJiwoo/nmt)
模型的权重在 GoogleDrive 上。
[豆包 - 字节跳动旗下 AI 智能助手](https://www.doubao.com/pdf/36311741618937346/https%3A%2F%2Farxiv.org%2Fpdf%2F2408.01180?from_source=from_extention_read_pdf_arxiv&pdf_reading=1)

## midi-model 黑盒，不要使用

[MET]() (transformer; ): https://github.com/SkyTNT/midi-model

## MuPT 基于 ABC，开源了，没法调流派

-   [MuPT](https://arxiv.org/abs/2404.06393) (transformer; qu25iclr): https://map-mupt.github.io/

[m-a-p (Multimodal Art Projection)](https://huggingface.co/m-a-p)

这是最有潜力的一个，因为我看到了 HuggingFace 上有个开源的组织，开了一堆 MuPT 的模型，高优先级
坏处就是 豆包说这个东西，好像没有针对多轨训练过，demo 页面全都是 piano

[豆包 - 字节跳动旗下 AI 智能助手](https://www.doubao.com/pdf/36263333425596674/https%3A%2F%2Farxiv.org%2Fpdf%2F2404.06393?from_source=from_extention_read_pdf_arxiv&pdf_reading=1)

## MMT-GI 不可用

[MMT-GI](https://arxiv.org/abs/2311.12257) (transformer; xu23arxiv): https://goatlazy.github.io/MUSICAI/

## Morpheus 不要用

-   [MorpheuS](https://arxiv.org/abs/1812.04832): https://dorienherremans.com/morpheus

## anticipation 可用

-   [Anticipatory Music Transformer](https://arxiv.org/abs/2306.08620) (; thickstun23arxiv): https://crfm.stanford.edu/2023/06/16/anticipatory-music-transformer.html

-   [SCHmUBERT](https://arxiv.org/abs/2305.09489) (diffusion; plasser23ijcai): https://github.com/plassma/symbolic-music-discrete-diffusion
-   [DiffuseRoll](https://arxiv.org/abs/2303.07794) (diffusion; wang23arxiv): n/a

## museformer

-   [Museformer](https://arxiv.org/abs/2210.10349) (Transformer; yu22neurips): https://ai-muzic.github.io/museformer/

微软出品，checkpoint 说在 OneDrive 上，没了，呵呵，草台班子倒闭算了

## MIDI-LLM 自然语言直接到 多轨 MIDI，意义不大

可以用它生成小片段，但是没法用于一首完整音乐的生成

[slSeanWU/MIDI-LLM: MIDI-LLM Official Transformers implementation (NeurIPS AI4Music '25)](https://github.com/slSeanWU/MIDI-LLM)

## 其他，都是 22 年的

-   [SymphonyNet](https://arxiv.org/pdf/2205.05448.pdf) (Transformer; liu22ismir): https://symphonynet.github.io/
-   [CMT](https://arxiv.org/abs/2111.08380) (Transformer; di21mm): https://wzk1015.github.io/cmt/
-   [CONLON](https://program.ismir2020.net/poster_6-14.html) (GAN; angioloni20ismir): https://paolo-f.github.io/CONLON/
-   [MMM](https://arxiv.org/pdf/2008.06048.pdf) (Transformer; ens20arxiv): https://jeffreyjohnens.github.io/MMM/
-   [MahlerNet](http://www.mahlernet.se/files/SMC2019.pdf) (RNN+VAE; lousseief19smc): https://github.com/fast-reflexes/MahlerNet
-   [Measure-by-Measure](https://openreview.net/forum?id=Hklk6xrYPB) (RNN): https://sites.google.com/view/pjgbjzom
-   [JazzRNN](http://mac.citi.sinica.edu.tw/~yang/pub/ailabs19ismirlbd_1.pdf) (RNN; yeh19ismir-lbd): https://soundcloud.com/yating_ai/sets/ismir-2019-submission/
-   [MIDI-Sandwich2](https://arxiv.org/pdf/1909.03522.pdf) (RNN+VAE; liang19arxiv): https://github.com/LiangHsia/MIDI-S2
-   [LakhNES](https://arxiv.org/abs/1907.04868) (Transformer; donahue19ismir): https://chrisdonahue.com/LakhNES/
-   [MuseNet](https://openai.com/blog/musenet/) (Transformer): https://openai.com/blog/musenet/
-   [MIDI-VAE](https://arxiv.org/abs/1809.07600) (GRU+VAE; brunner18ismir): https://www.youtube.com/channel/UCCkFzSvCae8ySmKCCWM5Mpg
-   [Multitrack MusicVAE](https://arxiv.org/abs/1806.00195) (LSTM+VAE; simon18ismir): https://magenta.tensorflow.org/multitrack
-   [MuseGAN](https://arxiv.org/abs/1709.06298) (CNN+GAN; dong18aaai): https://salu133445.github.io/musegan/

PopMag：南京大学的一个，也没有
