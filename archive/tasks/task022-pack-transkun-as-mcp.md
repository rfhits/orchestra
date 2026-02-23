# 将 transkun 封装为 mcp

已经 clone 好仓库了
预计像 split_stems 那样，直接做成脚本调用的方式就好了

transkun 的安装和使用非常简单：`pip install transkun`
但是我们选择使用 Windows + uv，所以有一些坑，

`uv add transkun` 时候，注意，linux 下会从 pytorch 上拉取，但是 windows 会从 pypi 上拉取。
导致会用 CPU 推理

```toml
[project]
name = "transkun-mcp"
version = "0.1.0"
description = "Add your description here"
readme = "README.md"
requires-python = ">=3.10"
dependencies = [
    "transkun>=2.0.1",
]
```

要如何通过 extra 机制，指定 torch source 呢？
这样就可以

-   `uv sync --extra torch-cuda12`
-   `uv sync --extra torch-cpu`
