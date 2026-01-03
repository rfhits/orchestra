# /// script
# dependencies = [
#   "mcp[server]",
# ]
# ///

"""
Orchestra MCP Server 入口文件
"""
import sys
import pkgutil
import importlib
import inspect
from pathlib import Path
from mcp.server.fastmcp import FastMCP

# 1. 确保 mcp_tools 能被导入
# 将当前脚本所在目录加入 sys.path
CURRENT_DIR = Path(__file__).parent
if str(CURRENT_DIR) not in sys.path:
    sys.path.insert(0, str(CURRENT_DIR))

# 创建 FastMCP 实例
mcp = FastMCP("orchestra-reaper")

def register_all_tools():
    """
    自动扫描 mcp_tools 文件夹中的所有模块并注册为 MCP 工具
    """
    tools_path = CURRENT_DIR / "mcp_tools"
    
    if not tools_path.exists():
        print(f"Error: 找不到工具目录 {tools_path}", file=sys.stderr)
        return

    # 2. 动态加载模块
    # pkgutil.iter_modules 比 glob 更稳健，能处理包结构
    for module_info in pkgutil.iter_modules([str(tools_path)]):
        module_name = module_info.name
        try:
            # 导入 mcp_tools.xxx
            module = importlib.import_module(f"mcp_tools.{module_name}")
            
            # 3. 遍历函数
            for name, func in inspect.getmembers(module, inspect.isfunction):
                # 过滤私有函数
                if name.startswith("_"):
                    continue
                
                # 过滤掉不是在这个模块定义的函数 (比如 import 进来的辅助函数)
                if func.__module__ != module.__name__:
                    continue

                # 4. 生成工具名 (如 track_create)
                tool_name = f"{module_name}_{name}"
                
                # 5. 核心修正：直接注册原始函数
                # FastMCP 会自动读取 func 的 Type Hints 生成 Schema
                # 不要使用包装器！
                mcp.tool(name=tool_name)(func)
                
                print(f"[Registered] {tool_name}", file=sys.stderr)

        except Exception as e:
            print(f"[Error] 加载模块 {module_name} 失败: {e}", file=sys.stderr)

if __name__ == "__main__":
    register_all_tools()
    mcp.run()