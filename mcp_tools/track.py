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


def delete(track_guid: str) -> Dict[str, Any]:
    """
    删除轨道

    Args:
        track_guid: 轨道 GUID

    Returns:
        操作结果
    """
    return bridge.call_reaper("track.delete", {"track_guid": track_guid})


def set_color(
    index: int,
    color: List[int] | None = None,
    clear: bool = False,
) -> Dict[str, Any]:
    """
    设置轨道颜色

    Args:
        index: 轨道索引
        color: 颜色值，rgb 数组格式，红色是 [255, 0, 0]。clear=False 时必填
        clear: 是否清除轨道自定义颜色（恢复默认）

    Notes:
        - 传入 [0, 0, 0] 会设置“自定义黑色”，不是“恢复默认颜色”。
        - 这是 REAPER I_CUSTOMCOLOR 的语义：自定义颜色需要通过 clear=True（底层写 0）来清除。
        - 如需恢复主题默认轨道色，请使用 clear=True，而不是 color=[0, 0, 0]。

    Returns:
        操作结果
    """
    payload: Dict[str, Any] = {"index": index, "clear": clear}
    if color is not None:
        payload["color"] = color
    return bridge.call_reaper("track.set_color", payload)


def get_color(index: int) -> Dict[str, Any]:
    """
    获取轨道颜色

    Args:
        index: 轨道索引

    Returns:
        轨道颜色信息，包含一个 rgb 数组，红色是 [255, 0, 0]
    """
    return bridge.call_reaper("track.get_color", {"index": index})


def set_mute(
    index: int,
    mute: bool | None = None,
    action: str = "set",
) -> Dict[str, Any]:
    """
    设置轨道静音状态。

    Args:
        index: 轨道索引（0-based）
        mute: 目标静音状态（action 为 set 时必填）
        action: 操作类型，支持 "set" / "toggle"
    """
    payload: Dict[str, Any] = {"index": index, "action": action}
    if mute is not None:
        payload["mute"] = mute
    return bridge.call_reaper("track.set_mute", payload)


def get_mute(index: int) -> Dict[str, Any]:
    """
    获取轨道静音状态。
    """
    return bridge.call_reaper("track.get_mute", {"index": index})


def set_solo(
    index: int,
    solo: bool | None = None,
    action: str = "set",
    mode: str = "default",
) -> Dict[str, Any]:
    """
    设置轨道 Solo 状态。

    Args:
        index: 轨道索引（0-based）
        solo: 目标 Solo 状态（action 为 set 时必填）
        action: 操作类型，支持 "set" / "toggle"
        mode: solo 模式，支持 "default" / "non_sip" / "sip"
    """
    payload: Dict[str, Any] = {"index": index, "action": action, "mode": mode}
    if solo is not None:
        payload["solo"] = solo
    return bridge.call_reaper("track.set_solo", payload)


def get_solo(index: int) -> Dict[str, Any]:
    """
    获取轨道 Solo 状态。
    """
    return bridge.call_reaper("track.get_solo", {"index": index})


def set_parent_as(parent_track: Any, child_track: Any) -> Dict[str, Any]:
    """
    设置轨道父子层级关系

    Args:
        parent_track: 父轨道标识（GUID/名称/索引）
        child_track: 子轨道标识（GUID/名称/索引）

    Returns:
        操作结果
    """
    return bridge.call_reaper(
        "track.set_parent_as",
        {"parent_track": parent_track, "child_track": child_track},
    )
