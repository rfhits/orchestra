# 将 BS-RoFormer 封装为 MCP 服务

BS-RoFormer 遇到的问题是：

1. 如何指定一个 `pyproject.toml` 使得可以在不同的电脑上复现
2. 将 `inference.py` 改造为支持 Gradio 的方法
3. 将 Gradio 暴露出 mcp 接口方便调用

以下是解决方案，并且实现到了 GitHub 仓库中： [split_stems_mcp](https://github.com/rfhits/split_stems_mcp)

1. 通过 extra 机制，为 uv 指定每种 extra 要去哪个 index 安装
2. Gradio 通过 cli wrapper 调用 inference.py 脚本，起了一个子进程，算是偷懒实现了
3. Gradio 本身就具有 MCP 机制，参考：[Building Mcp Server With Gradio](https://www.gradio.app/guides/building-mcp-server-with-gradio)
   同时要小心，Gradio 的 MCP 需要支持 http 机制，如果 client 没支持 url 机制，可以安装 `remote-mcp` 后用 `npx remote-mcp <url>` 调用
