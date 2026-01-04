"""
轨道工具模块
提供轨道相关的基础操作
"""

from typing import Any, Dict, List

from mcp_bridge import bridge


def create(name: str = "新轨道", index: int = -1) -> Dict[str, Any]:
    """
    在 REAPER 中创建新轨道

    Args:
        name: 轨道名称
        index: 轨道索引 (-1 表示添加到末尾)

    Returns:
        操作结果
    """
    return bridge.call_reaper("track.create", {"name": name, "index": index})


def rename(index: int, name: str) -> Dict[str, Any]:
    """
    重命名轨道

    Args:
        index: 轨道索引
        name: 新名称

    Returns:
        操作结果
    """
    return bridge.call_reaper("track.rename", {"index": index, "name": name})


def set_color(index: int, color: List[int]) -> Dict[str, Any]:
    """
    设置轨道颜色

    Args:
        index: 轨道索引
        color: 颜色值，rgb 数组格式，红色是 [255, 0, 0]

    Returns:
        操作结果
    """
    return bridge.call_reaper("track.set_color", {"index": index, "color": color})


def get_color(index: int) -> Dict[str, Any]:
    """
    获取轨道颜色

    Args:
        index: 轨道索引

    Returns:
        轨道颜色信息，包含一个 rgb 数组，红色是 [255, 0, 0]
    """
    return bridge.call_reaper("track.get_color", {"index": index})
