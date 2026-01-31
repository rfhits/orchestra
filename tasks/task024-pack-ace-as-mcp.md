# 将 ACE-step 生成音乐功能封装为 MCP

这个服务没法在 Windows 上跑，只能在 wsl 跑。

[rfhits/ace_step_mcp: ACE-Step: A Step Towards Music Generation Foundation Model](https://github.com/rfhits/ace_step_mcp)

注意设置超时时间

```json
{
    "generate_music_by_ace":{
        "args": [
            "mcp-remote",
            "http://127.0.0.1:7865/gradio_api/mcp/"
        ],
        "command": "npx",
        "tool_timeout_sec": 300
    }
}
```
