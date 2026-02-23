# 打包发布到 PyPi

我们应该向用户暴露三个接口：

安装本 MCP 工具：

```sh
uv tool install reaper-orchestra
```

命令短名为 `orch`，同时保留长命令 `orchestra`。

将一个 MCP server 安装到本地

```sh
uvx orch launch
```

启动本地的 mcp server，然后用户可以直接复制配置到 agent 中

否则现在非常丑陋

```json
{
  "args": [
    "--directory",
    "C:\\Users\\rfntts\\AppData\\Roaming\\REAPER\\Scripts\\orchestra",
    "run",
    "server.py"
  ],
  "command": "uv"
}
```

将内置的 lua 脚本安装到指定的 reaper 路径，安装到 `scripts/rfhits/orchestra/*.lua`

```sh
uvx orch scripts <path-to-reaper-scripts>
```

---

## 迁移与实现方案（基于当前仓库，最小改动）

### 目标

- 继续使用 stdio MCP（不做 HTTP）。
- 用户侧启动体验：`orch launch`（不需要 `--directory`），同时保留 `orchestra launch` 作为长命令。
- 开发侧即时生效：`uv run --directory <repo> python -m cli launch`。

### 1) 目录迁移（一步步执行）

保持顶层扁平结构（不再嵌套 `orchestra/` 目录）：

```
server.py        # MCP 入口
mcp_bridge.py    # IPC
mcp_tools/       # MCP tools（包）
cli.py           # CLI
reaper_scripts/  # Lua + test
```

具体移动顺序（避免导入路径出错）：

1. 保持 `server.py`、`mcp_bridge.py`、`cli.py` 在根目录
2. 保持 `mcp_tools/` 为包目录（确保 `mcp_tools/__init__.py`）
3. 新增 `reaper_scripts/`，把所有 `.lua` 放进去，同时把 `test/` 整个目录移入 `reaper_scripts/test/`
4. 给 `reaper_scripts/` 加 `__init__.py` 以便用 `importlib.resources`
7. 更新根目录引用（文档/README）

### 2) 代码改动点

- `server.py`：
  - `tools_path = CURRENT_DIR / "mcp_tools"`
  - 动态 import 改为 `importlib.import_module("mcp_tools.xxx")`
  - 暴露 `main()` 供 CLI 调用
- `mcp_tools/*.py`：
  - 统一 `from mcp_bridge import bridge`
- `cli.py`：
  - `launch`：启动 FastMCP（stdio）
  - `scripts <path>`：复制 `reaper_scripts/*` 到 `<path>/rfhits/orchestra`
  - 用 `importlib.resources.files("reaper_scripts")`

### 3) pyproject.toml 必改项

```
[project]
name = "reaper-orchestra"
version = "0.1.0"
requires-python = ">=3.10"
dependencies = ["mcp[server]"]

[project.scripts]
orch = "cli:main"
orchestra = "cli:main"
```

并确保 `reaper_scripts/` 被打包：

- 使用 `tool.setuptools.package-data` 包含 `reaper_scripts = ["**/*"]`
- `mcp_tools` 与 `reaper_scripts` 作为包被包含（`packages.find`）

### 4) 用户侧接入（Claude Desktop 示例）

```json
{
  "mcpServers": {
    "orchestra": {
      "command": "orch",
      "args": ["launch"]
    }
  }
}
```

### 5) 开发侧接入（源码即时生效）

```json
{
  "mcpServers": {
    "orchestra": {
      "command": "uv",
      "args": [
        "run",
        "--directory",
        "C:\\path\\to\\orchestra",
        "python",
        "-m",
        "cli",
        "launch"
      ]
    }
  }
}
```

### 6) 常见坑（必须注意）

- **uv tool 是隔离环境**：`orch launch` / `orchestra launch` 都不会跟随源码自动更新。
- **导入路径**：移动到包内后，所有 `from mcp_bridge import ...` 必须改为包内导入。
- **包资源**：Lua 文件若不显式打包，`scripts` 命令会找不到（注意路径为 `reaper_scripts/`）。
- **路径含空格**：`scripts <path>` 需要正确处理空格路径（Windows 常见）。
- **mcp_tools 扫描**：动态 import 时使用包路径，避免扫描失败。

### 7) 最小验证清单

- `uv tool install .` 后 `orch launch` 可启动 MCP
- `uv run --directory <repo> python -m cli launch` 可启动 MCP
- `orch scripts <path>` 能复制 `.lua` 到 `<path>/rfhits/orchestra`

---

## 开发与部署指导（本地开发 / 用户部署）

### A. 本地开发（源码即时生效）

1. 在仓库根目录运行：

```sh
uv run --directory <repo> python -m cli launch
```

2. 将 MCP 配置指向本地源码（示例）：

```json
{
  "mcpServers": {
    "orchestra": {
      "command": "uv",
      "args": [
        "run",
        "--directory",
        "C:\\path\\to\\orchestra",
        "python",
        "-m",
        "cli",
        "launch"
      ]
    }
  }
}
```

### B. 用户部署（发布后使用）

1. 安装：

```sh
uv tool install reaper-orchestra
```

2. 启动：

```sh
orch launch
```

3. 安装 REAPER 脚本（会复制 `reaper_scripts/` 与 `test/`）：

```sh
orch scripts <path-to-reaper-scripts>
```

### C. 发布前自检（建议按顺序）

1. 确认 Lua/test 文件没有内容变化（仅移动）：

```powershell
$root = "C:\Users\rfntts\AppData\Roaming\REAPER\Scripts\orchestra"
$lua = git ls-tree -r --name-only HEAD -- "*.lua"
$test = git ls-tree -r --name-only HEAD -- "test/*"
$files = @($lua + $test) | Where-Object { $_ -ne "" } | Sort-Object -Unique
$errors = @()
foreach ($f in $files) {
  $newRel = Join-Path "reaper_scripts" $f
  $newPath = Join-Path $root $newRel
  if (-not (Test-Path $newPath)) { $errors += "MISSING $f -> $newRel"; continue }
  $oldHash = (git show "HEAD:$f" | git hash-object --stdin).Trim()
  $newHash = (git hash-object $newPath).Trim()
  if ($oldHash -ne $newHash) { $errors += "CHANGED $f -> $newRel" }
}
if ($errors.Count -eq 0) { "OK: lua/test files match HEAD content" } else { $errors }
```

2. 运行基本启动：

```sh
uv run --directory C:\Users\rfntts\AppData\Roaming\REAPER\Scripts\orchestra python -m cli launch
```

3. 打 tag 便于回滚：

```sh
git tag -a pre-pack-YYYYMMDD -m "before packaging"
```
