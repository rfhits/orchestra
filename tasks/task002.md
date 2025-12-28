# task002 实现一个最小版本

实现一个 Lua，提供 track.create
实现一个 MCP server，暴露 track.create 的功能

参考

1. [task001](task001.md)
2. [track](../docs/track.md)

要求：

我们先写一个最简单的 lua 脚本，在 reaper 里面执行.

1. 检查目录 ：inbox="~/.orchestra/inbox" 有没有 .json
2. 有的话按照格式解析并调用 reaper 执行
3. 执行后得到到 outbox/id.reply.json

切记使用 .part 表示中间文件，.req 表示处理中，.reply 表示结束
