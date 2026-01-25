# HeartMuLa / heartlib 调研报告（面向 8GB 显卡场景）

## 1. 结论（TL;DR）

1) 能不能做 text→audio？

- **可以。**HeartMuLa-oss-3B 是一个多语言 **text-to-audio / text-to-music** 模型：输入“歌词 + 标签（tags）”，输出整段音乐音频（带强风格控制）。
- HuggingFace 标注：`pipeline_tag: text-to-audio`，语言覆盖：**中 / 英 / 日 / 韩 / 西班牙语**。
- 生成流程与 SongGeneration 类似，都是“歌词 + 条件 → 完整音乐”，但 HeartMuLa 的控制手段更偏“标签 + 风格”而不是强对齐歌词结构。

2) 8GB 显存（4060Ti）能不能跑？

- 模型权重大小（来自 HuggingFace metadata）：
  - `HeartMuLa/HeartMuLa-oss-3B` 参数总量约 **3.94 GB F32**；
    - 推理默认 dtype 为 `bf16` → 模型权重约 **2 GB**。
  - `HeartMuLa/HeartCodec-oss-20260123` 参数总量约 **1.66 GB F32**；
    - 推理默认 dtype 为 `fp32` → 模型权重约 **1.7 GB**。
  - 两者加起来，**权重本身 ~3.6 GB 显存**，再加上 KV cache +中间激活，大致在 **5–7 GB 量级**。
- README 的推荐做法：
  - 单卡（比如你现在的 4060Ti 8GB）：
    - 开启 `--lazy_load true`，让模块按需加载，推理结束后释放显存；
    - 可以适当缩短 `--max_audio_length_ms`（例如先试 60–90 秒）。
  - 多卡（例如 2×4090）：
    - `--mula_device cuda:0 --codec_device cuda:1` 把 LM 和 codec 分到不同 GPU。
- 结合参数规模和官方建议，**在 8GB 显存上只要打开 `--lazy_load` 并控制生成时长，有较大机会跑得动**；但生成 4 分钟长曲子时仍存在 OOM 风险，需要你实际测试调参。

3) License 情况

- 仓库和所有相关权重的 License 已在 2026-01-20 更新为 **Apache 2.0**（README 明确说明）。
- 与 SongGeneration 的“仅限研究/教育、不允许商业用途”不同，HeartMuLa **适合放进将来的商用产品链路**（前提是遵守 Apache-2.0 条款）。

4) 是否满足 Orchestra 的需求？

- 作为 **歌词/文本 → 音乐音频** 的主力引擎，HeartMuLa-oss-3B 是当前非常有竞争力的选择：
  - 可控性：通过 `tags` 精细控制风格/乐器/情绪；
  - 语言：支持多语言歌词；
  - 许可证：可商用；
  - 显存：在 8GB 上可通过 lazy-load 勉强跑通，远好于 SongGeneration 要求的 10–22GB。
- 不足：
  - 目前公开版本 **尚未支持“参考音频 conditioning / timbre clone”**（在 TODO 里）；
  - 不提供“audio→MIDI / chords / melody”能力，配乐分析部分仍需要依赖 basic-pitch 等其它模型。

---

## 2. HeartMuLa / heartlib 组件概览

根据 README，heartlib 包含四类主要组件：

1. **HeartMuLa**（音乐语言模型）
   - 职责：**条件音乐生成**，输入为歌词（lyrics）和风格标签（tags），输出为音乐 codec token 序列，经 HeartCodec 解码成音频。
   - 特点：
     - 支持多语言歌词：中/英/日/韩/西班牙语等；
     - 支持丰富标签：乐器、情绪、场景等（例如 `piano,happy,wedding,synthesizer,romantic`）。
2. **HeartCodec**（音乐 codec）
   - 12.5 Hz 时域 codec，强调高还原度；
   - 类似 Stable Audio 的 VAE，对音乐做编码/解码；
   - 推理默认 dtype 是 `fp32`，为了音质不建议改成 bf16。
3. **HeartTranscriptor**
   - whisper-based 的歌词转写模型；
   - 主要用在“歌词转录”场景：给一段已生成/已有音乐 → 输出歌词文本（适合作为 QA / 质量评估工具）。
4. **HeartCLAP**
   - Audio–Text 对齐模型，建立音乐描述与音频的共同 embedding 空间；
   - 可用作检索 / 排序 / 反馈模型（如 RLHF）。

对 Orchestra 来说，目前最 relevant 的是：

- **HeartMuLa + HeartCodec**：做 text→audio 生成；
- HeartTranscriptor/HeartCLAP 以后可以用在“自动评价生成结果”和“检索参考曲”等辅助任务。

---

## 3. HeartMuLa-oss-3B 能力与输入输出

### 3.1 模型能力

HuggingFace `HeartMuLa/HeartMuLa-oss-3B` metadata：

- `pipeline_tag: "text-to-audio"`
- `tags: ["music","art","zh","en","ja","ko","es", ...]`
- `config.model_type: "heartmula"`

结合论文和 README：

- 支持 **多语言歌词到音乐** 的生成：
  - Lyrics 可以是中/英/日/韩/西语等；
  - 模型会根据语言和 tags 生成对应语种/风格的音乐。
- 控制方式：
  - 文本 lyrics 决定“结构 + 内容语义”；
  - tags 决定“风格 / 乐器 / 情绪 / 场景”；
  - 通过 RL（最新的 `HeartMuLa-RL-oss-3B-20260123`）加强对 tags 的可控性。
- 生成长度：
  - README 默认 `--max_audio_length_ms=240000`，即 **最长 4 分钟**；
  - 该参数可手动调小，比如 60,000（1 分钟）作为 8GB 显卡的安全起点。

### 3.2 输入格式示例

README 示例命令：

```bash
python ./examples/run_music_generation.py --model_path=./ckpt --version="3B"
```

默认行为：

- 从 `./assets/lyrics.txt` 读取歌词；
- 从 `./assets/tags.txt` 读取 tags；
- 生成音乐到 `./assets/output.mp3`。

歌词推荐格式（README 示例）：

```txt
[Intro]

[Verse]
The sun creeps in across the floor
...

[Chorus]
Every day the light returns
...

[Outro]
Just another day
Every single day
```

tags 示例：

```txt
piano,happy,wedding,synthesizer,romantic
```

注意：

- 标签逗号分隔，不带空格；
- 同一行 tags 控制一首歌的整体色彩，适合我们在 Orchestra 侧用工具自动拼 tag（如 style=rock, mood=happy, instruments=guitar,bass,drums）。

### 3.3 CLI 参数（与 Orchestra 工具集成相关）

`run_music_generation.py` 主要参数（摘自 README）：

- `--model_path`（必填）：ckpt 根目录，例如 `./ckpt`；
- `--lyrics`：歌词文件路径（默认 `./assets/lyrics.txt`）；
- `--tags`：tag 文件路径（默认 `./assets/tags.txt`）；
- `--save_path`：输出音频路径（默认 `./assets/output.mp3`）；
- `--max_audio_length_ms`：最大生成时长（默认 240000 ms）；
- `--topk` / `--temperature` / `--cfg_scale`：采样相关参数；
- `--version`：`3B` / `7B`（目前只有 3B 放出，7B 还未开源）；
- `--mula_device` / `--codec_device`：LM / codec 部署在哪个设备（默认都在 `cuda`，多卡可以分开）；
- `--mula_dtype` / `--codec_dtype`：
  - LM 默认 `bf16`；
  - codec 默认 `fp32`；
- `--lazy_load`：
  - 默认 `false`；
  - 如果设为 `true`，会按需加载模块并在用完后释放，以节省显存。

结合 Orchestra MCP 工具，未来可以封装一个：

- `audio.generate_with_heartmula`：
  - param 中包含 `lyrics`, `tags`, `max_length_ms`；
  - server 侧调用 `run_music_generation.py` 或直接 import heartlib；
  - 将生成的 `output.mp3` 导入 REAPER 对应轨道。

---

## 4. 显存与性能评估（4060Ti 8GB 场景）

### 4.1 模型参数量估算

从 HuggingFace 获取的参数大小：

- HeartMuLa-oss-3B：
  - `safetensors.parameters.F32 ≈ 3.94e9 bytes` → 约 **3.94 GB（float32）**；
  - 推理默认 dtype = `bf16`，权重显存约减半 → **约 2 GB**。
- HeartCodec-oss-20260123：
  - `safetensors.parameters.F32 ≈ 1.66e9 bytes` → 约 **1.66 GB（float32）**；
  - 推理默认 dtype = `fp32`，权重显存约 **1.7 GB**。

合计：

- 仅权重 ≈ **3.6 GB**；
- 再加上：
  - KV cache、激活；
  - PyTorch / CUDA 本身的显存开销；
  - Audio buffer / codec 中间张量；
- 实际推理时显存峰值大致会落在 **5–7 GB 区间**，视生成时长和 batch 大小而定。

### 4.2 README 对 OOM 的建议

FAQ 中直接给了 OOM 建议：

1. 多卡：
   - `--mula_device cuda:0 --codec_device cuda:1`；
2. 单卡：
   - 打开 `--lazy_load true`，模块按需加载 / 释放，减少峰值显存。

结合 8GB 显卡实际经验，可以给出一个较保守的运行建议：

- 起步配置：
  - `--max_audio_length_ms 60000`（先生成 60 秒，确认不 OOM 再加到 120k, 180k 等）；
  - `--lazy_load true`；
  - 保持默认 `--mula_dtype bf16`、`--codec_dtype fp32`。
- 如果仍 OOM：
  - 进一步降低 `max_audio_length_ms`；
  - 或考虑在 CPU / 第二块 GPU 上运行 codec（如果有的话）。

结论：

- **相对 SongGeneration（最低就要 10GB 显存），HeartMuLa-oss-3B 对 8GB 显卡友好得多**；
- 在你目前的 4060Ti 8GB 上，只要控制生成长度和使用 lazy_load，属于“可用但需小心调参”的级别，而不是直接无望。

---

## 5. 与 Orchestra 工作流的契合度

### 5.1 text→song 端

优点：

- 多语言歌词支持，与未来面向全球用户的需求契合；
- tags 控制可以与我们自己的“风格/情绪/乐器”语义空间对齐；
- License 允许商用，可以直接考虑进产品路线；
- 3B 规模 + codec 的总显存压力可以被 8GB 卡勉强承受。

不足：

- 目前公开版本还不支持：
  - 参考音频 conditioning；
  - 细粒度结构控制（例如：指定每个小节的 chord progression）；
- 输出仅为音频，不带 MIDI / chord 信息，需要我们自己做后续的 audio→MIDI / harmony 分析。

### 5.2 配乐 / 和声分析端

- heartlib 自带的 HeartTranscriptor / HeartCLAP 主要面向：
  - 歌词转录；
  - 文本–音乐检索与对齐；
  - 并不是专门做和弦/旋律提取。
- 所以，**在“audio → chord progression & melody”这一块，heartlib 本身并不能替代我们之前调研的 basic-pitch + 和弦拟合方案**。

在 Orchestra 整体架构里，一个比较清晰的定位是：

- **HeartMuLa**：负责“从零开始生成整首带风格的 demo（音频）”，用于灵感/草稿；
- **basic-pitch + 自研和声模块**：负责把 demo 转成 MIDI + chords，用于二次编曲和精细控制；
- **其它 MIDI 模型（如 TeleMelody 等）**：用于歌词→主旋律、旋律→伴奏的 symbolic 级别生成。

---

## 6. 下一步建议（如果要接入 heartlib）

1. 实机测试（在你这台 4060Ti 8GB 上）：
   - 按 README 安装 heartlib + 下载 3B + codec 权重；
   - 用如下配置试跑：
     ```bash
     python ./examples/run_music_generation.py \
       --model_path=./ckpt \
       --version 3B \
       --lazy_load true \
       --max_audio_length_ms 60000
     ```
   - 记录实际显存峰值和生成时长。
2. 如果测试通过，再考虑：
   - 在 Orchestra 的 MCP server 里封装一个 `audio.heartmula_generate` 工具；
   - 约定好 `lyrics/tags/max_length_ms` 的 JSON schema；
   - 输出的 `output.mp3` 自动导入 REAPER 为一个新轨道。
3. 和 SongGeneration 的对比决策：
   - 研究/benchmark 阶段可以两边都留着；
   - 一旦开始考虑对外服务，优先选择 License 友好的 HeartMuLa 作为 text→audio 主力模型。

如果你希望，我可以下一步帮你把 `audio.heartmula_generate` 的 MCP 接口设计稿写出来，或者直接起草一个 Python 伪实现，方便后面你在 `mcp_tools/` 里挂载。 

---

## 7. HeartMuLa 使用指南（面向 8GB 显卡 & Orchestra 场景）

这一节给一份“从零到出声”的实用说明，方便你在本机（4060Ti 8GB）或 MCP server 上跑通 HeartMuLa。

### 7.1 环境准备

1. 安装 Python 3.10（官方推荐 3.10）。
2. 克隆仓库并本地安装：
   ```bash
   git clone https://github.com/HeartMuLa/heartlib.git
   cd heartlib
   pip install -e .
   ```
3. 建议在虚拟环境里操作（`python -m venv .venv && .venv/Scripts/activate`）。

### 7.2 下载模型权重

官方推荐使用 HuggingFace `hf` CLI（也支持 ModelScope，这里只写 HF 版本）：

```bash
# 创建 ckpt 目录
mkdir -p ckpt

# 推荐使用 20260123 强化学习版本
hf download --local-dir './ckpt/HeartMuLa-oss-3B' 'HeartMuLa/HeartMuLa-RL-oss-3B-20260123'
hf download --local-dir './ckpt/HeartCodec-oss'   'HeartMuLa/HeartCodec-oss-20260123'
```

下载完成后，`ckpt/` 目录结构大致如下：

```text
ckpt/
├── HeartMuLa-oss-3B/
│   ├── config.json
│   ├── model-00001-of-00004.safetensors
│   ├── ...
├── HeartCodec-oss/
│   ├── config.json
│   ├── model-00001-of-00002.safetensors
│   ├── ...
└── gen_config.json / tokenizer.json （由 hf download HeartMuLa/HeartMuLaGen 时提供）
```

如果你之后打算在 MCP server 里调用，可以在 server 的配置中把这个 `ckpt` 路径固定下来。

### 7.3 准备歌词与标签（tags）

HeartMuLa 的输入分两部分：歌词（lyrics）和标签（tags）。

1. 歌词文件（默认路径：`./assets/lyrics.txt`）：
   - 推荐按段落加标签的格式编写，例如：
     ```txt
     [Intro]

     [Verse]
     The sun creeps in across the floor
     I hear the traffic outside the door
     ...

     [Chorus]
     Every day the light returns
     Every day the fire burns
     ...

     [Outro]
     Just another day
     Every single day
     ```
   - 中文歌词同理，只要换成中文句子即可。

2. 标签文件（默认路径：`./assets/tags.txt`）：
   - 一行文本，逗号分隔、**没有空格**，例如：
     ```txt
     piano,happy,wedding,synthesizer,romantic
     ```
   - 标签可以用来控制：
     - 乐器：`piano`, `guitar`, `bass`, `drums`, `synthesizer`...
     - 情绪：`happy`, `sad`, `romantic`, `melancholic`...
     - 场景：`wedding`, `club`, `cinematic`...
   - 在 Orchestra 里，完全可以由上层 agent 按“流派 + 情绪 + 编制”自动拼这个字符串。

### 7.4 基础生成命令（推荐给 8GB 显卡）

在 `heartlib` 仓库根目录下运行：

```bash
python ./examples/run_music_generation.py \
  --model_path ./ckpt \
  --version 3B \
  --lazy_load true \
  --max_audio_length_ms 60000 \
  --save_path ./assets/output.mp3
```

说明：

- `--model_path ./ckpt`：指向上面下载权重的根目录；
- `--version 3B`：使用开源的 3B 版本（7B 版本暂未开源）；
- `--lazy_load true`：
  - 单卡（如 4060Ti 8GB）强烈推荐；
  - HeartMuLa / HeartCodec 在需要时才加载，推理结束后释放显存；
- `--max_audio_length_ms 60000`：
  - 先以 60 秒做 smoke test，确认不会 OOM，再逐步提高到 120000/180000 等；
- `--save_path`：
  - 指定输出 mp3 文件路径，默认是 `./assets/output.mp3`。

如果你有多卡，例如 2×4090，可以进一步降低单卡压力：

```bash
python ./examples/run_music_generation.py \
  --model_path ./ckpt \
  --version 3B \
  --mula_device cuda:0 \
  --codec_device cuda:1 \
  --max_audio_length_ms 240000
```

### 7.5 推荐参数组合（工程实践版）

根据 README 和显存估算，建议的几组“可参考 preset”：

1. **4060Ti 8GB，测试用**：
   ```bash
   --version 3B \
   --max_audio_length_ms 60000 \
   --lazy_load true \
   --mula_dtype bf16 \
   --codec_dtype fp32
   ```
2. **4060Ti 8GB，短曲 demo（约 90–120 秒）**：
   ```bash
   --max_audio_length_ms 120000 \
   --lazy_load true
   ```
   如果 OOM，则退回 90000 或降低到 60000。

3. **多卡（2×24GB），长曲 demo（4 分钟）**：
   ```bash
   --max_audio_length_ms 240000 \
   --mula_device cuda:0 \
   --codec_device cuda:1
   ```

采样相关参数可以保持默认：

- `--topk 50`，`--temperature 1.0`，`--cfg_scale 1.5`。

### 7.6 与 Orchestra 工程的集成思路（草案）

在 Orchestra 的 Python MCP server 里，可以封装一个简单的工具，例如：

- 工具名：`audio.heartmula_generate`
- 入参（示例）：
  ```json
  {
    "lyrics": "...\n完整歌词文本\n...",
    "tags": "rock,happy,guitar,bass,drums",
    "max_length_ms": 90000
  }
  ```
- 实际实现步骤：
  1. 将 `lyrics` 写入临时 `lyrics.txt`，`tags` 写入临时 `tags.txt`；
  2. 调用 `run_music_generation.py`（或直接 import heartlib 内部 API）：
     - 传入 `--lyrics` / `--tags` 指向临时文件；
     - 传入 `--save_path` 指向 MCP server 的一个输出路径；
     - 默认 `--lazy_load true`，`--max_audio_length_ms` 使用参数值；
  3. 完成后返回：
     - `audio_path`：生成 mp3 的路径；
     - 元信息：实际生成时长、使用的 tags 等。
  4. Orchestra 侧再调用 REAPER 插件，把这个 mp3 导入到指定轨道。

这样，前端 agent 或用户只需要给出“歌词 + 风格标签 + 时长”，其余逻辑都由工具链自动完成。
