"""
Marker 工具模块
提供项目 marker 的基础 CRUD 操作
"""

from typing import Any, Dict

from mcp_bridge import bridge


def create(time: float, desc: str) -> Dict[str, Any]:
    """
    在指定时间创建 marker

    Args:
        time: marker 时间（秒），必须 >= 0
        desc: marker 描述

    Returns:
        创建结果
    """
    return bridge.call_reaper("marker.create", {"time": time, "desc": desc})


def list() -> Dict[str, Any]:
    """
    获取项目中所有 marker

    Returns:
        marker 列表
    """
    return bridge.call_reaper("marker.list", {})


def update(marker_id: int, desc: str) -> Dict[str, Any]:
    """
    更新 marker 描述

    Args:
        marker_id: marker 编号
        desc: 新描述（可为空字符串，用于清空描述）

    Returns:
        更新结果
    """
    return bridge.call_reaper("marker.update", {"marker_id": marker_id, "desc": desc})


def delete(marker_id: int) -> Dict[str, Any]:
    """
    删除 marker

    Args:
        marker_id: marker 编号

    Returns:
        删除结果
    """
    return bridge.call_reaper("marker.delete", {"marker_id": marker_id})

