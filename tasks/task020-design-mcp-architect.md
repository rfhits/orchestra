# 封装现有音乐模型为 MCP

将音乐大模型封装为 MCP 的难点在于：

1. 避免长连接，因为会超时，可以解放 agent 去做其他事情
2. 推理和通知分离

## 基于 Gradio 的方案设计

Gradio 自己支持一套简单的 MCP 通信方案，参考：[Building Mcp Server With Gradio](https://www.gradio.app/guides/building-mcp-server-with-gradio)

但是我目前没有看到基于 task - progress 的方案，因为如果做了这个，
要自己维护 task id，要自己实现 task id 的进度查询，就和原来 Gradio 的 UI 不兼容了
不过 Gradio 倒是有 gr.Progress 来做长连接下的进度通知

## 自己的方案设计

要想通的事情：
Q: 现在 AI 是怎么得知有一个 MCP 的？  
A: 不同的 app 有自己的 MCP server 配置文件路径，比如 Claude 在某一个路劲的 json 下，
Gemini 在另一个路径下，vscode 又有项目级别的 MCP servers 配置文件

Q: 开发者如果本地开发了一个模型和接入，要如何接入 MCP？
A: 当开发者修改 agent/app 的 json 文件时候，比如需要提供一个类似 uvx 或者 npx 的命令。
这个命令（bridge）会尝试发现一个后台的进程，后台的进程提供推理服务。
后台的进程可以位于自己的 local 电脑上，那就是开发者自己想办法部署了，然后接受这个 bridge 带来的
agent 的 tool call 和参数。

本地启动的时候需要有心跳模式，如果太久 bridge 不 call 自己就自己杀掉自己，防止占用后台资源。
如果打算做成一个服务部署发布出去收费，
比如部署在 `https://music-model.com/{model-id}/{tool}`，bridge 完全可以每次都像这个链接发送请求
同时携带用户的参数，如 prompt 等，但是如何处理 wav 文件还没有想好，本地的话可以直接携带一个 `path`，
而且本地的话路径也非常好被识别出来。

那么开发者只需要专注地处理如何把 推理脚本 `inference.py` 改造成一个支持端口监听 loop，然后生成返回的 server 进程就可以了。

设计：
纯 Python 实现。
包含两个部分：
messenger，worker

messenger 就是 MCP 服务器启动的一个进程，这个进程会从本地的 `$model_id_url` 里面拿到自己要向哪个服务器通信
并且它会自动生成那种 MCP 兼容的 json 格式。内部写死了 tool call list
每次 Claude 或者其他编程助手启动它，他都会告知 claude 有哪些 tool。

worker 侧是一个 web server 进程，兼具

1. 监听端口（上文的 messenger 会向 url 发 MCP request）
2. 模型加载
3. 推理
4. 卸载流程

worker 不要求 messenger 可以唤醒，只是要求 messenger 发送的时候，自己也在线，可以接收到。
worker 启动、接受到请求以后，就开始推理，并且告诉 messenger 推理开始了，并且给一个 task id
worker 可以提供一个接口，给定 task id 查询对应的返回路径。

返回路径可以是本地的，也可以是 host 到自己这个 web server 上的。
然后 Claude 再配置一个 download from http 的 MCP tool 就可以了。
