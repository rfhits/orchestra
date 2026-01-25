# BS-RoFormer 部署 & MCP 集成指南（独立 HTTP 服务版）

> 目标：把 **BS-ROFO-SW-Fixed（BS-RoFormer 6-stem）** 做成一个「可拔插的 HTTP 模型服务」，  
> 上层通过 MCP 能力 `model.ability = "bs_roformer.split_stems"` 调用。
>
> 要求：
> - 模型服务和 Orchestra/MCP 完全解耦，可单独升级 / 替换
> - 依赖版本锁定，便于复现
> - 不强依赖 Docker / Gradio，本地终端直接 debug 友好

模型本地跑法见：`docs/music-models/BS-RoFormer/bs-roformer-usage.md`。  
本文件只关心：服务架构、依赖锁定、HTTP API 设计、MCP 侧如何调用。

---

## 1. 总体架构：两仓两进程

分成两个完全独立的模块：

1. **BS-RoFormer-Service（新 fork 仓库）**
   - 基于：`ZFTurbo/Music-Source-Separation-Training` fork
   - 精简到只保留「推理 + BS-RoFormer 相关代码」
   - 对外提供 HTTP 接口：
     - `POST /v1/split-stems`
   - 输入：音频文件（二进制上传）
   - 输出：包含若干 stem 的 zip（`bass/drums/other/vocals/guitar/piano`）

2. **Orchestra MCP Server（当前 orchestra 仓库）**
   - 新增一个 MCP 工具：`bs_roformer.split_stems`
   - 工具内部只做 HTTP 调用，不直接 import 模型代码
   - 返回本机缓存中各 stem 的文件路径，供 Lua / REAPER 后续使用

好处：
- 模型服务可以换仓库、换实现、换机器，只要 HTTP 契约不变，上层不用改
- Orchestra 依赖面小很多，只需要 `requests` 之类的 HTTP 客户端

---

## 2. BS-RoFormer-Service：fork & 依赖锁定

### 2.1 从 ZFTurbo 仓库 fork

1. 在 GitHub 上 fork：`ZFTurbo/Music-Source-Separation-Training`
2. 本地 clone 你的 fork，例如：

```bash
git clone https://github.com/<you>/bs-roformer-service.git
cd bs-roformer-service
```

> 后文把这个仓库叫做 `SERVICE_ROOT`。

### 2.2 创建专用 Conda 环境（py310）

```bash
conda create -n bs-roformer-service-py310 python=3.10
conda activate bs-roformer-service-py310
```

### 2.3 最小依赖集合：`requirements.in`

我们不直接用原仓库的 `requirements.txt`，而是：

- 手写一个「最小推理依赖」清单：`requirements.in`
- 再用 `pip-tools` 生成一个锁定版本的 `requirements.lock`

在 `SERVICE_ROOT` 下新建 `requirements.in`，可以先按下面这个基础版写（后续按需增补）：

```text
torch==2.0.1
torchaudio
numpy
scipy
soundfile
librosa
ml_collections
omegaconf==2.2.3
einops
rotary_embedding_torch==0.3.5
tqdm

# 推理过程中会 import 到的一些 loss / metrics
auraloss
torchmetrics==0.11.4

# HTTP 服务
fastapi
uvicorn[standard]
```

刻意不包含的（原仓库里有，但这里不要）：

- `wxpython`（GUI）
- `keyboard`
- `wandb`、`accelerate`、`bitsandbytes` 等训练/实验相关包
- `pyaudio` 等输入设备相关包

如果后续运行报 `ImportError`，再把缺的包补到 `requirements.in` 里即可。

### 2.4 用 pip-tools 生成锁定文件

安装 pip-tools：

```bash
pip install pip-tools
```

在 `SERVICE_ROOT` 下执行：

```bash
pip-compile requirements.in -o requirements.lock
pip install -r requirements.lock
```

之后：

- 你只维护顶层的 `requirements.in`（想升级某依赖就改这一份）
- 每次改完跑一次 `pip-compile` 生成新的 `requirements.lock`
- 部署 / 同步环境统一用：
  ```bash
  pip install -r requirements.lock
  ```

---

## 3. HTTP 服务设计：`POST /v1/split-stems`

### 3.1 接口约定

路径：

- `POST /v1/split-stems`

请求（`multipart/form-data`）：

- 字段：
  - `audio_file`：必选，上传的混音文件（WAV/FLAC/MP3 等）
  - `stems`：可选，逗号分隔的 stem 列表，例如 `"piano,vocals"`；缺省则输出全部 6 个
  - `use_tta`：可选，`"true" / "false"`，默认 `"true"`

响应：

- 成功：`200 OK`，`Content-Type: application/zip`
  - zip 内部结构：
    ```text
    <basename>/
      bass.wav
      drums.wav
      other.wav
      vocals.wav
      guitar.wav
      piano.wav
    ```
    （如果只请求部分 stem，就只包含对应文件）

- 出错：`4xx/5xx`，`Content-Type: application/json`
  ```json
  { "ok": false, "error": "message..." }
  ```

### 3.2 服务实现骨架（FastAPI 示例）

在 `SERVICE_ROOT` 里新建模块，例如 `bs_roformer_service/app.py`：

```python
from __future__ import annotations

import io
import shutil
import tempfile
import zipfile
from pathlib import Path
from typing import List, Optional

from fastapi import FastAPI, File, Form, HTTPException, UploadFile
from fastapi.responses import JSONResponse, StreamingResponse

from inference import proc_folder  # ZFTurbo 仓库里的入口

app = FastAPI(title="BS-RoFormer 6-stem Service")

REPO_ROOT = Path(__file__).resolve().parent.parent
DEFAULT_CONFIG = REPO_ROOT / "configs" / "custom" / "BS-Rofo-SW-Fixed.yaml"
DEFAULT_CKPT = REPO_ROOT / "checkpoints" / "BS-Rofo-SW-Fixed.ckpt"

ALL_STEMS = ["bass", "drums", "other", "vocals", "guitar", "piano"]


@app.post("/v1/split-stems")
async def split_stems_endpoint(
    audio_file: UploadFile = File(...),
    stems: Optional[str] = Form(None),
    use_tta: bool = Form(True),
):
    if not DEFAULT_CONFIG.is_file() or not DEFAULT_CKPT.is_file():
        raise HTTPException(
            status_code=500,
            detail="Model config or checkpoint not found on server",
        )

    try:
        selected_stems: List[str]
        if stems:
            selected_stems = [s.strip() for s in stems.split(",") if s.strip()]
        else:
            selected_stems = ALL_STEMS[:]

        with tempfile.TemporaryDirectory() as tmp_dir_str:
            tmp_dir = Path(tmp_dir_str)

            # 保存上传的音频
            input_path = tmp_dir / audio_file.filename
            with open(input_path, "wb") as f:
                shutil.copyfileobj(audio_file.file, f)

            out_dir = tmp_dir / "out"
            out_dir.mkdir(parents=True, exist_ok=True)

            # 调用 ZFTurbo inference 逻辑
            dict_args = {
                "model_type": "bs_roformer",
                "config_path": str(DEFAULT_CONFIG),
                "start_check_point": str(DEFAULT_CKPT),
                "input_folder": str(tmp_dir),
                "store_dir": str(out_dir),
                "use_tta": use_tta,
                "device_ids": [0],
                "force_cpu": False,  # 如需要可以加参数
            }
            proc_folder(dict_args)

            file_stem = input_path.stem
            stem_dir = out_dir / file_stem
            if not stem_dir.is_dir():
                raise HTTPException(
                    status_code=500, detail=f"Output directory not found: {stem_dir}"
                )

            # 打包结果到 zip（在内存中）
            mem_zip = io.BytesIO()
            with zipfile.ZipFile(mem_zip, "w", zipfile.ZIP_DEFLATED) as zf:
                for stem_name in selected_stems:
                    found = False
                    for ext in ("wav", "flac"):
                        p = stem_dir / f"{stem_name}.{ext}"
                        if p.is_file():
                            arcname = f"{file_stem}/{stem_name}.{ext}"
                            zf.write(p, arcname=arcname)
                            found = True
                            break
                    if not found:
                        # 没有这个 stem 就跳过，不算错误
                        continue

            mem_zip.seek(0)
            return StreamingResponse(
                mem_zip,
                media_type="application/zip",
                headers={
                    "Content-Disposition": f'attachment; filename="{file_stem}_stems.zip"'
                },
            )

    except HTTPException:
        raise
    except Exception as e:
        return JSONResponse(
            status_code=500,
            content={"ok": False, "error": str(e)},
        )
```

启动服务（在 `SERVICE_ROOT`）：

```bash
conda activate bs-roformer-service-py310
uvicorn bs_roformer_service.app:app --host 0.0.0.0 --port 8000
```

本地 quick test：

```bash
curl -X POST "http://127.0.0.1:8000/v1/split-stems" \
  -F "audio_file=@/path/to/song1.wav" \
  -F "stems=piano,vocals" \
  --output song1_stems.zip
```

---

## 4. Orchestra 侧：MCP 工具 `bs_roformer.split_stems`（HTTP 客户端）

Orchestra 不直接 import BS-RoFormer，而是把 HTTP 服务当黑盒。

### 4.1 MCP 工具接口（建议）

在 Orchestra 仓库里新增一个 MCP 工具模块，例如：

- 路径：`mcp_tools/bs_roformer_client.py`

函数签名：

```python
def split_stems(
    input_path: str,
    stems: list[str] | None = None,
    service_url: str | None = None,
) -> dict:
    ...
```

约定：

- `input_path`：REAPER 渲染出的混音绝对路径
- `stems`：需要的 stem 列表，例如 `["piano", "vocals"]`；`None` 表示全部
- `service_url`：BS-RoFormer HTTP 服务地址，默认可以是 `http://127.0.0.1:8000/v1/split-stems`，实际值从配置读更好

返回建议：

```jsonc
{
  "ok": true,
  "input_path": "C:/.../song1.wav",
  "service_url": "http://127.0.0.1:8000/v1/split-stems",
  "stems": {
    "piano": "C:/.../.orchestra/cache/bs-roformer/song1/piano.wav",
    "vocals": "C:/.../.orchestra/cache/bs-roformer/song1/vocals.wav"
  }
}
```

### 4.2 工具内部逻辑（设计）

大致步骤：

1. 校验 `input_path` 是否存在
2. 用 `requests` 调用 HTTP 服务，上传文件 + stems 参数
3. 检查响应：
   - 如果是 JSON → 视为错误，直接返回 `{ok: false, error: ...}`
   - 如果是 zip → 解压到本地缓存目录
4. 返回各 stem 的本地路径，方便后续 Lua 侧调用 `audio.insert_at_second` 等工具

缓存目录可以约定在：

```text
~/.orchestra/bs-roformer-cache/<basename>/
```

这样，不会污染项目目录。

伪代码示意（不直接写入工程，只作为设计）：

```python
import io
import zipfile
from pathlib import Path
from typing import Any, Dict, List, Optional

import requests


DEFAULT_SERVICE_URL = "http://127.0.0.1:8000/v1/split-stems"
CACHE_ROOT = Path("~/.orchestra/bs-roformer-cache").expanduser()


def split_stems(
    input_path: str,
    stems: Optional[List[str]] = None,
    service_url: Optional[str] = None,
) -> Dict[str, Any]:
    input_p = Path(input_path).expanduser().absolute()
    if not input_p.is_file():
        return {"ok": False, "error": f"input_path not found: {input_p}"}

    url = service_url or DEFAULT_SERVICE_URL
    stem_str = ",".join(stems) if stems else ""

    with open(input_p, "rb") as f:
        files = {"audio_file": (input_p.name, f, "application/octet-stream")}
        data = {"stems": stem_str, "use_tta": "true"}
        resp = requests.post(url, files=files, data=data, timeout=600)

    # 错误：JSON 形式的报错
    if resp.headers.get("content-type", "").startswith("application/json"):
        try:
            err = resp.json()
        except Exception:
            err = resp.text
        return {"ok": False, "error": err}

    if resp.status_code != 200:
        return {"ok": False, "error": f"HTTP {resp.status_code}"}

    # 解压 zip 到缓存目录
    basename = input_p.stem
    out_dir = CACHE_ROOT / basename
    out_dir.mkdir(parents=True, exist_ok=True)

    buf = io.BytesIO(resp.content)
    with zipfile.ZipFile(buf, "r") as zf:
        zf.extractall(out_dir)

    # 构造 stems 路径
    stems_dir = out_dir / basename
    result_stems: Dict[str, str] = {}
    for p in stems_dir.glob("*.*"):
        stem_name = p.stem  # bass/drums/...
        result_stems[stem_name] = str(p.resolve())

    return {
        "ok": True,
        "input_path": str(input_p),
        "service_url": url,
        "stems": result_stems,
    }
```

`server.py` 会自动把这个函数注册为 MCP 工具，工具名是：

- `bs_roformer_client.split_stems`

在你自己的「能力」层，可以把它映射为：

- `model.ability = "bs_roformer.split_stems"`

---

## 5. Debug 步骤建议

1. **先验证 HTTP 服务本身**
   - 在 fork 仓库启动服务：
     ```bash
     conda activate bs-roformer-service-py310
     uvicorn bs_roformer_service.app:app --host 0.0.0.0 --port 8000
     ```
   - 用 `curl` 或 `httpie` 直接上传一个 wav，看能否拿到 zip：
     ```bash
     curl -X POST "http://127.0.0.1:8000/v1/split-stems" \
       -F "audio_file=@/path/to/song1.wav" \
       -F "stems=piano" \
       --output song1_piano.zip
     ```

2. **再验证 MCP 客户端模块**
   - 在 Orchestra 仓库里，用同一个 Conda 环境（只需 `requests`）：
     ```python
     from mcp_tools.bs_roformer_client import split_stems
     split_stems(r"C:\tmp\song1.wav", stems=["piano"])
     ```
   - 确认本地 `~/.orchestra/bs-roformer-cache/song1/piano.wav` 正常生成。

3. **最后接入 MCP 客户端（Claude 等）**
   - 按现有的 `server.py` 启动 Orchestra MCP 服务
   - 让客户端列出工具，确认有 `bs_roformer_client.split_stems`
   - 在你自己的能力系统里，把它声明为：  
     `model.ability = "bs_roformer.split_stems"`

整个方案里：

- BS-RoFormer 作为一个独立 HTTP 模块，依赖通过 `requirements.lock` 锁死；
- Orchestra 只依赖 HTTP 契约，方便你后续随时更换实现（换模型、换框架、甚至换成 gRPC）而不影响上层逻辑。
