# BS-RoFormer / BS-ROFO-SW-Fixed 使用手册

> 目标：在本地用 **BS-RoFormer** 的 6-stem 模型 **BS-ROFO-SW-Fixed** 做乐器分离（包含 piano），基于 ZFTurbo 的 Music-Source-Separation-Training 仓库。

参考上游代码仓库（后文简称 MSS）：  
https://github.com/ZFTurbo/Music-Source-Separation-Training

BS-ROFO-SW-Fixed 的 HuggingFace 页面：  
https://huggingface.co/jarredou/BS-ROFO-SW-Fixed

核心信息：
- 模型架构：Band Split RoFormer（`model_type = bs_roformer`）
- 采样率：44.1kHz，STFT `n_fft=2048`
- 输出 6 个 stem（顺序固定）：`bass / drums / other / vocals / guitar / piano`

---

## 1. 准备 MSS 仓库与 Conda py310 环境

这里只讲「本机怎么跑起来」，不讨论服务器部署 / Docker 等场景。

如果你还没有下 MSS 仓库，推荐放到 Orchestra 的 `models` 目录下：

```powershell
cd "C:\Users\rfntts\AppData\Roaming\REAPER\Scripts\orchestra\models"
git clone https://github.com/ZFTurbo/Music-Source-Separation-Training.git
```

记这个路径为：

```text
MSS_ROOT = C:\Users\rfntts\AppData\Roaming\REAPER\Scripts\orchestra\models\Music-Source-Separation-Training
```

### 1.1 创建 Conda Python 3.10 环境

在任意终端（PowerShell / WSL）中：

```powershell
conda create -n bs-roformer-py310 python=3.10
conda activate bs-roformer-py310
```

之后每次想用 BS-RoFormer，只要先：

```powershell
conda activate bs-roformer-py310
cd "$env:APPDATA\REAPER\Scripts\orchestra\models\Music-Source-Separation-Training"
```

### 1.2 安装依赖（去掉 wxpython / pyaudio）

官方 `requirements.txt` 里包含一些 GUI / 音频输入相关包，在很多环境下会因为缺系统库而安装失败，但**对命令行推理不重要**。  
我们这里显式删掉它们，只保留分离模型所需依赖。

需要从 `requirements.txt` 中删除的行：

- 一行以 `wxpython==4.2.2` 开头的依赖
- 一行 `pyaudio`（不一定有版本号）

推荐做法：

1. 在编辑器里打开 `requirements.txt`
2. 另存为 `requirements-nogui.txt`
3. 在 `requirements-nogui.txt` 中删除以下两行依赖：
   - `wxpython==4.2.2`
   - `pyaudio`

然后在 Conda 环境中安装：

```powershell
cd "$env:APPDATA\REAPER\Scripts\orchestra\models\Music-Source-Separation-Training"
conda activate bs-roformer-py310

pip install -r requirements-nogui.txt
```

这样可以避免 wxpython / pyaudio 的编译问题，同时保证 BS-RoFormer 推理所需的依赖都装好。

---

## 2. 从 HuggingFace 下载 BS-ROFO-SW-Fixed

在浏览器打开：  
https://huggingface.co/jarredou/BS-ROFO-SW-Fixed/tree/main

下载以下两个文件（右侧 Download 按钮）：

- `BS-Rofo-SW-Fixed.yaml`
- `BS-Rofo-SW-Fixed.ckpt`

推荐在 MSS_ROOT 中的放置路径：

```text
MSS_ROOT/
  configs/
    custom/
      BS-Rofo-SW-Fixed.yaml
  checkpoints/
    BS-Rofo-SW-Fixed.ckpt
```

其中 YAML 内容里最关键的是：

```yaml
model:
  num_stems: 6

training:
  instruments: ['bass', 'drums', 'other', 'vocals', 'guitar', 'piano']
  target_instrument: null
```

这意味着推理时会输出 6 个独立 stem，其中就包括 `piano`。

---

## 3. 准备输入音频

在 MSS_ROOT 下建一个输入目录，例如：

```powershell
cd "$env:APPDATA\REAPER\Scripts\orchestra\models\Music-Source-Separation-Training"
mkdir input\wavs
```

把你要分离的混音（`*.wav` / `*.flac` / `*.mp3` 等）放到：

```text
MSS_ROOT\input\wavs\
```

脚本会递归处理这个目录中的所有音频文件。

---

## 4. 使用 BS-ROFO-SW-Fixed 做 6-stem 分离

在 MSS_ROOT 中、激活 Conda 环境后运行：

```powershell
cd "$env:APPDATA\REAPER\Scripts\orchestra\models\Music-Source-Separation-Training"
conda activate bs-roformer-py310

python inference.py `
  --model_type bs_roformer `
  --config_path configs\custom\BS-Rofo-SW-Fixed.yaml `
  --start_check_point checkpoints\BS-Rofo-SW-Fixed.ckpt `
  --input_folder input\wavs `
  --store_dir separation_results\bs_rofo_sw_fixed `
  --device_ids 0 `
  --use_tta
```

参数解释（与本模型相关的）：

- `--model_type bs_roformer`：告诉 MSS 使用 Band Split RoFormer 架构
- `--config_path`：指向你刚下载的 `BS-Rofo-SW-Fixed.yaml`
- `--start_check_point`：指向 `BS-Rofo-SW-Fixed.ckpt`
- `--input_folder`：输入混音目录
- `--store_dir`：输出结果根目录
- `--device_ids 0`：使用第 0 块 GPU；如果没有 GPU，可以改用 `--force_cpu`（会非常慢）
- `--use_tta`：启用 Test-Time Augmentation，质量略好，速度 ~3x

运行结束后，目录结构类似：

```text
MSS_ROOT/
  separation_results/
    bs_rofo_sw_fixed/
      song1/
        bass.wav
        drums.wav
        other.wav
        vocals.wav
        guitar.wav
        piano.wav
      song2/
        ...
```

默认文件名是由 `inference.py` 里的模板 `{file_name}/{instr}` 决定的：

- 文件夹名：原音频文件名（不含扩展名）
- 文件名：`instr` 就是上面 `training.instruments` 列表里的名字

---

## 5. 钢琴（piano）stem 的使用要点

根据 YAML 配置：

```yaml
training.instruments: ['bass', 'drums', 'other', 'vocals', 'guitar', 'piano']
```

所以：

- 模型内部的输出顺序就是：`bass → drums → other → vocals → guitar → piano`
- `inference.py` 会按这个顺序将结果写成 `bass.wav`、`drums.wav`、…、`piano.wav`
- 你要的钢琴轨道就是 `piano.wav`

在 Orchestra / REAPER 里，你可以：

1. 用 REAPER 导出混音到 `MSS_ROOT\input\wavs\song1.wav`
2. 跑上面的推理命令
3. 把 `separation_results\bs_rofo_sw_fixed\song1\piano.wav` 再导回 REAPER 到一个新的轨道

这样就获得了一个「从混音分离出的 piano stem」。

---

## 6. 与 Orchestra 集成的方向（草案）

当前这份文档只覆盖命令行用法。未来如果要做 Orchestra 一键调用，可以考虑：

- 在 MCP Server 里封装一个 `audio.split_stems_bs_rofo_sw` 工具：
  - 输入：混音 wav 路径、想要的 stem 列表（比如 `["piano", "vocals"]`）
  - 内部：调用上面的 `inference.py` 命令
  - 输出：各 stem wav 的路径
- 再配合 Lua 侧的 `audio.insert_at_second` / `audio.insert_at_measure`，自动把这些 stem 插回 REAPER 工程。

等你确定具体 workflow，我们可以在此基础上再写一份「Orchestra 集成指南」，但就模型本身而言，上面这套命令行流程已经足够覆盖日常使用。 
