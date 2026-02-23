# MCP 端口约定

codex 暂时不支持 url 格式的 http mcp，所以必须用 npx mcp-remote 包装一下
需要为一些 MCP 配置超时时间，codex 的参数叫做： "tool_timeout_sec": 300

Gemini 默认 timeout 是 10min，完全够用

> timeout (number): Request timeout in milliseconds (default: 600,000ms = 10 minutes)
> [MCP servers with the Gemini CLI | Gemini CLI](https://geminicli.com/docs/tools/mcp-server/)

Gradio 每次启动会分配 7860 端口
为了方便配置，这里统一约定端口：

DiffRhythm2: 7860
留空: 7862-7864
ACE-step: 7865，他自己在代码里面指定了
sheetsage: 7866
split_stems: 7867
song-former: 7868
basic-Analyzer: 7869
Structural-arrangement: 7870
anticipation: 7871
music2music: 7872
transkun: 7873
SOME: 7874

## ACE-step

```sh
uv run acestep --torch_compile true --cpu_offload true --overlapped_decode true
```

```json
{
  "args": [
    "mcp-remote",
    "http://127.0.0.1:7865/gradio_api/mcp/"
  ],
  "command": "npx",
  "tool_timeout_sec": 300
}
```

## sheetsage

```sh
uv run gradio_cli_wrapper.py
```

因为跑在 wsl 里面，所以需要一个额外的文件上传 MCP

```json
{
  "command": "npx",
  "args": [ "mcp-remote", "http://127.0.0.1:7866/gradio_api/mcp/" ]
}
```

```json
{
    "command": "uvx",
    "args": [
        "--from",
        "gradio[mcp]",
        "gradio",
        "upload-mcp",
        "http://127.0.0.1:7866/",
        "C:\\Users\\rfntts\\AppData\\Roaming\\REAPER\\Scripts\\orchestra"
    ]
}
```

## bs-RoFormer to split stems

```sh
uv run .\gui\gradio_cli_wrapper.py
```

```json
{
    "command": "npx",
    "args":[
        "mcp-remote",
        "http://127.0.0.1:7867/gradio_api/mcp/"
    ]
}
```

## SongFormer 分析歌曲结构

```sh
uv run app.py
```

这个也是跑在 wsl 里面

```json
{
    "command": "npx",
    "args": ["mcp-remote", "http://127.0.0.1:7868/gradio_api/mcp/sse"],
    "tool_timeout_sec": 300
}
```

```json
{
      "command": "uvx",
      "args": [
        "--from",
        "gradio[mcp]",
        "gradio",
        "upload-mcp",
        "http://127.0.0.1:7868/",
        "C:\\Users\\rfntts\\AppData\\Roaming\\REAPER\\Scripts\\orchestra"
    ]
}
```

## basic song Analyzer

及其小巧的分析 midi 和 segmentation MCP

```json
{
    "command": "npx",
    "args": [
        "mcp-remote",
        "http://127.0.0.1:7869/gradio_api/mcp/"
    ]
}
```

## Structural Arrangement 给 lead sheet 编曲

Structural Arrangement 需要两个额外输入：

1. segmentation: 乐曲结构，如 i4A8B8，通过 Basic Song Analyzer MCP 获得
2. note shift：编曲开始时间，不知道的话直接用 0 就好，这个是因为有 弱起

这个 warning 要解决

```bash
Mismatch warning: Detect 116 bars in the lead sheet (MIDI) and 120 bars in the provided phrase annotation. The lead sheet is padded to 120 bars.
```

```json
{
    "command": "npx",
    "args": [
        "mcp-remote",
        "http://127.0.0.1:7870/gradio_api/mcp/"
    ],
    "tool_timeout_sec": 300
}
```

这个因为输入比较复杂，prompt 就比较麻烦

I need arrangement for a midi, Piano, Bass, Guitar is ok.
midi and segmentation is located at:
