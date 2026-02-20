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


def get_selection_info() -> Dict[str, Any]:
    """
    获取当前选择信息（item/track/上下文）

    返回当前工程里的选择状态，适合 agent 在执行编辑操作前先读取。
    即使当前没有选中 item 或 track，也会返回空列表（ok=true）。

    Returns:
        dict: 选择信息，包含：
            - selection.context（cursor context、time selection 等）
            - selection.items（选中的 item 列表）
            - selection.tracks（选中的 track 列表）
            - selection.item_count / selection.track_count

    Examples:
        result = get_selection_info()
        info = result["result"]["selection"]
        print(info["item_count"], info["track_count"])
    """
    return bridge.call_reaper("project.get_selection_info", {})


def set_tempo_timesig_at_second(
    sec: float,
    bpm: float,
    ts_num: int,
    ts_den: int,
) -> Dict[str, Any]:
    """
    设置指定秒数的速度/拍号标记

    Args:
        sec: 目标时间点（秒），必须 >= 0
        bpm: BPM，必须 > 0
        ts_num: 拍号分子，必须为正整数
        ts_den: 拍号分母，必须为正整数

    Returns:
        dict: 设置结果
    """
    return bridge.call_reaper(
        "project.set_tempo_timesig_at_second",
        {"sec": sec, "bpm": bpm, "ts_num": ts_num, "ts_den": ts_den},
    )


def set_project_timesig(bpm: float, ts_num: int, ts_den: int) -> Dict[str, Any]:
    """
    设置项目默认拍号/速度（内部固定在 0 秒处设置 Tempo/TimeSig marker）

    Args:
        bpm: BPM，必须 > 0
        ts_num: 拍号分子，必须为正整数
        ts_den: 拍号分母，必须为正整数

    Returns:
        dict: 设置结果
    """
    return bridge.call_reaper(
        "project.set_project_timesig",
        {"bpm": bpm, "ts_num": ts_num, "ts_den": ts_den},
    )
