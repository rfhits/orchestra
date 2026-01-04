"""
项目工具模块
提供项目相关的基础操作
"""

from typing import Any, Dict

from mcp_bridge import bridge


def get_info() -> Dict[str, Any]:
    """
    获取项目信息

    Returns:
        项目信息
    """
    return bridge.call_reaper("project.get_info", {})


def get_track_count() -> Dict[str, Any]:
    """
    获取项目中轨道的数量

    Returns:
        轨道数量信息
    """
    return bridge.call_reaper("project.get_track_count", {})


def get_track_list() -> Dict[str, Any]:
    """
    获取项目中所有轨道的列表

    Returns:
        轨道列表信息
    """
    return bridge.call_reaper("project.get_track_list", {})