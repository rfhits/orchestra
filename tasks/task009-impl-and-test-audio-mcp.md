# impl and test audio mcp

现在需要编写 audio 的 MCP server
因为是 audio 的 API，所以对外暴露的是 插入 wav/mp3 到 track

以及导出 对应的 track 为 wav

因为 reaper 软件如果失去焦点，素材会 offline，导致后台渲染不出来
修复了一个需要保持 素材 online 的 bug
