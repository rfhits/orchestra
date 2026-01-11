"""
音频工具模块
提供音频渲染和媒体插入相关操作
"""

from typing import Any, Dict, List, Optional

from mcp_bridge import bridge


def render_seconds(
    tracks: Optional[List[str]] = None,
    begin: float = 0,
    length: float = 10,
    filename: Optional[str] = None
) -> Dict[str, Any]:
    """
    按秒渲染音频

    Args:
        tracks: 轨道 ID 列表（可以是索引、名称或 GUID）
        begin: 起始时间（秒）
        length: 渲染时长（秒）
        filename: 输出文件名

    Returns:
        渲染结果，包含文件路径
    """
    return bridge.call_reaper("audio.render_seconds", {
        "tracks": tracks or [],
        "begin": begin,
        "len": length,
        "filename": filename
    })


def render_measures(
    tracks: Optional[List[str]] = None,
    begin: float = 1,
    length: float = 1,
    filename: Optional[str] = None
) -> Dict[str, Any]:
    """
    按小节渲染音频

    Args:
        tracks: 轨道 ID 列表（可以是索引、名称或 GUID）
        begin: 起始小节（1-based），1.5 表示 第一小节和第二小节正中间
        length: 渲染小节数
        filename: 输出文件名

    Returns:
        渲染结果，包含文件路径
    """
    return bridge.call_reaper("audio.render_measures", {
        "tracks": tracks or [],
        "begin": begin,
        "len": length,
        "filename": filename
    })


def insert(
    file_path: str,
    track: Optional[str] = None,
    position: float = 0
) -> Dict[str, Any]:
    """
    插入媒体文件到轨道

    Args:
        file_path: 媒体文件路径
        track: 轨道 ID（可以是索引、名称或 GUID）
        position: 插入位置（秒）

    Returns:
        插入结果
    """
    return bridge.call_reaper("audio.insert", {
        "file_path": file_path,
        "track": track,
        "position": position
    })


def insert_at_second(
    file_path: str,
    track: Optional[str] = None,
    second: float = 0
) -> Dict[str, Any]:
    """
    在指定秒数位置插入媒体文件

    Args:
        file_path: 媒体文件路径
        track: 轨道 ID（可以是索引、名称或 GUID）
        second: 插入时间点（秒）

    Returns:
        插入结果
    """
    return bridge.call_reaper("audio.insert_at_second", {
        "file_path": file_path,
        "track": track,
        "second": second
    })


def insert_at_measure(
    file_path: str,
    track: Optional[str] = None,
    measure: float = 1
) -> Dict[str, Any]:
    """
    在指定小节位置插入媒体文件

    Args:
        file_path: 媒体文件路径
        track: 轨道 ID（可以是索引、名称或 GUID）
        measure: 插入小节（1-based），1.5 表示 第一小节和第二小节正中间

    Returns:
        插入结果
    """
    return bridge.call_reaper("audio.insert_at_measure", {
        "file_path": file_path,
        "track": track,
        "measure": measure
    })
