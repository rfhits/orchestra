# Orchestra

[理想中的音乐编辑模式](./docs/edit-music.md#设想中的最佳编辑方式)

> 最好的 prompt 应该是 音乐概念 + 上下文 并重的
> 用户可以对指定的时间区域给出自己的指令，如：
> “将选中的 vocal 区间加入 rubato 效果”
> “为选中的 vocal 区间加入 guitar 配乐，同时需要参考此时其他配器轨道，注意音区避让”

但是目前的音乐生成模型还没有办法做到这一点。
比如 Suno，也只是给一个 style、lyrics，然后，开 roll，没有办法做到细粒度的编辑。

现在的模型缺乏音乐概念上的 prompt。

## 软件架构

1. Reaper 宿主脚本模块（Lua 编写），通过文件系统与 Python MCP 通信
2. 各大音乐模型作为独立实体（Docker/Server/Process）暴露 MCP server，提供 `model.ability()` 作为调用
3. 添加 Skill，指引大模型（Claude/Gemini）进行工作流创作、辅助功能定义

## 文档

1. [设想](./docs/edit-music.md)
2. [各大模型能力](./docs/music-model-abilities.md)
3. [开发任务追踪](./tasks/tasks.md)
4. [接入 MCP 规范](./docs/mcp/)
