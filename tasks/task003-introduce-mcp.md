# task003-MCP 接入

参考 [task001](./task001.md)，实现 Python MCP Server

触发：用户在 agent 中发起指令（如 “创建一个 track，命名为 XXX”）；
工具调用：MCP Server 对外暴露 “创建 track” 工具，接收指令后在 inbox 生成 json 文件；
后续操作：等待 outbox 生成对应 json 文件，文件生成后将其回收至 archive 文件夹。
核心重点：明确 MCP 的具体实现方式（为基础关键任务）。

要小心：

1. MCP 规范
2. 文件夹是 REAPER script

你的思考非常到位，这已经触及了**复杂 MCP 插件的架构设计**核心。

为了实现“优雅暴露”、“自动匹配”和“统一通信”，我们需要一套**基于装饰器的映射机制**，结合**动态文件系统监听**。

### 1. 架构设计：两层封装

我们可以把 Python 侧分为：

-   **通信层 (OrchestraBridge)**: 纯逻辑层。负责生成 UUID、写 `inbox`、轮询 `outbox`。它不关心业务，只负责“投递任务”和“拿回回执”。
-   **业务层 (Tools)**: 文件夹结构。如 `tools/track.py`。

### 2. 优雅暴露：自动映射 (Decorator Pattern)

我们不需要在 `server.py` 里手动写几百个函数。我们可以定义一个装饰器，直接将 Python 函数名映射到 `request.func` 的字符串。

**目录结构示例：**

```
orchestra/
├── server.py         # MCP 入口，加载 tools 文件夹
├── mcp_bridge.py         # 通信底层（处理 JSON 和文件操作）
└── tools/            # 插件文件夹
    ├── track.py      # 定义 track.create
    └── media.py      # 定义 media.insert
```

## prompt

我们现在要以非常快速的方式实现一个非常小又极简而可用的 MCP Server。然后我的规划已经写在这里了。我的想法是，首先我们有一个 Server 点 PY，然后这是所有的入口。然后这个东西的难点有两个，第一个是我们要怎么把这么多的工具暴露给他？我们不可能在一个 Python 文件里面把所有的函数都写，所以我们要把这些提供给他，函数暴露在很多个 Python 模块当中，所以我们就做了一个 tools 文件夹，用来放这些东西，比如说 check，点 media、点 PY project，点 PY 这种东西。然后每一个 POI 就是一个模块，它自己的函数通过 bridge 来暴露出来，有一个 bridge 点 POI Mcp bridge 点 POI，文件通过它来暴露出所有的，我们要给这个的接口，the agent 的接口。这是第一个，就是我们通过拆分模块，然后加上一个 bridge 自动扫描暴露所有工具出来。第二个就是我们要实现一些简单的函数，先实现一些简单的功能，这个越简单越好，比如说这个插入轨道，他其实做的就是在用到一个 json 文件，然后在 allbox 里面找那个 json 文件，对吧？然后找到就给他放到那个 allbox 文件夹下面。就这么简单的事情，所以说我们要是想办法封装好这些对文件的操作，对这个 json 文件的操作，比如说它这个怎么创建文件？然后它那创建一个 json 文件，它前面是有一个 Meta 数据头的，对吧？就是很多都是一样的，很多个对外暴露的方法，这个 Meta 数据头都是一样，这个操作完全是可以封装关起来，比如说你可以做一个 fire manager 什么之类的。所以说总结来说就这两点，你快速的实现一个简单的，我们看一下效果。
不要，千万不要自作主张的创建多余的文件夹，就在我给你安排好的文件里面写就好了。你不要欠他人太深，因为现在整个项目里面已经有了一个 UV，因为 UV 来管理依赖，所以我们不要再做特别深。@/pyproject.toml

### 3. 代码实现构想

#### A. 通信底层 (`bridge.py`)

定义一个统一的“发单”逻辑。

```python
import json, time, uuid
from pathlib import Path

class Bridge:
    def __init__(self):
        self.root = Path.home() / ".orchestra"
        self.inbox = self.root / "inbox"
        self.outbox = self.root / "outbox"

    def call_lua(self, func_name, params):
        job_id = f"{int(time.time()*1000)}_agent_{uuid.uuid4().hex[:8]}"

        # 1. 构造标准 Envelope
        envelope = {
            "meta": {"version": 1, "id": job_id, "ts_ms": int(time.time()*1000)},
            "request": {"func": func_name, "param": params},
            "response": None
        }

        # 2. 写入 (.part -> .json)
        req_file = self.inbox / f"{job_id}.json"
        part_file = self.inbox / f"{job_id}.json.part"
        with open(part_file, 'w') as f:
            json.dump(envelope, f)
        part_file.rename(req_file)

        # 3. 轮询等待 (.reply.json)
        reply_file = self.outbox / f"{job_id}.reply.json"
        start_time = time.time()
        while time.time() - start_time < 10: # 10秒超时
            if reply_file.exists():
                with open(reply_file, 'r') as f:
                    res = json.load(f)
                reply_file.unlink() # 消费后删除
                return res["response"]
            time.sleep(0.1)
        return {"ok": False, "error": {"code": "TIMEOUT", "message": "Lua no response"}}

```

#### B. 业务工具类 (`tools/track.py`)

我们定义一个统一的命名规范，让 Python 的函数名直接对应 Lua 侧的 `func`。

```python
# tools/track.py
from bridge import Bridge

bridge = Bridge()

def create(name: str, index: int = -1):
    """在 Reaper 中创建轨道。"""
    # 这里我们约定：模块名.函数名 = track.create
    return bridge.call_lua("track.create", {"name": name, "index": index})

def delete(track_guid: str):
    """根据 GUID 删除轨道。"""
    return bridge.call_lua("track.delete", {"track_guid": track_guid})

```

#### C. MCP 入口 (`server.py`)：自动注册

这是最关键的一步。我们利用 FastMCP 的能力，批量扫描 `tools` 文件夹。

```python
from mcp.server.fastmcp import FastMCP
import importlib
import pkgutil
import tools # 导入 tools 包

mcp = FastMCP("Orchestra")

def register_tools():
    # 动态遍历 tools 文件夹下的所有模块
    for _, name, _ in pkgutil.iter_modules(tools.__path__):
        module = importlib.import_module(f"tools.{name}")

        # 遍历模块里的函数
        for func_name in dir(module):
            func = getattr(module, func_name)
            # 过滤掉私有函数和非可执行函数
            if not func_name.startswith("_") and callable(func):
                # 构造 MCP Tool 注册
                # 这里的 tool_name 就是 "track_create" 或 "media_insert"
                tool_name = f"{name}_{func_name}"
                mcp.tool(name=tool_name)(func)

register_tools()

```

---

### 4. 这种设计的关键优势

1. **Lua/Python 名称强绑定**：

-   Python 的文件叫 `track.py`，函数叫 `create`。
-   自动生成的 `tool_name` 是 `track_create`。
-   发给 Lua 的 `func` 是 `track.create`。
-   **结果**：三端统一，Lua 侧只需要一个简单的 `if func == "track.create" then` 就能分发。

2. **解耦与扩展性**：

-   如果你想加一个 `midi` 模块，只需要在 `tools/` 下新建一个 `midi.py`。
-   `server.py` **一行代码都不用改**，它会自动扫描到新工具并暴露给 Claude。

3. **JSON 模板化**：

-   所有的元数据（meta）、文件操作（.part 逻辑）、超时等待全部封死在 `bridge.py` 里。
-   开发者写新工具时，只需要关心 `bridge.call_lua("名字", {参数})`。
