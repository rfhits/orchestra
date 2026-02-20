"""
Take 工具模块
提供 take 的添加、列表和激活切换接口。
"""

from typing import Any, Dict, List

from mcp_bridge import bridge


def add_at_second(
    files: List[str],
    item_guid: str | None = None,
    track: str | int | None = None,
    second: float | None = None,
    item_match_mode: str | None = None,
    names: List[str] | None = None,
    set_active: int | None = None,
    length: float | None = None,
) -> Dict[str, Any]:
    """
    在指定秒数位置添加 takes。

    Args:
        files: 待添加文件路径列表（List[str]），至少 1 个
        item_guid: 可选目标 item GUID（str）
        track: 可选轨道标识（str|int），当不提供 item_guid 时必填
        second: 可选时间点（float，秒），当不提供 item_guid 时必填
        item_match_mode: 可选 item 匹配策略（str）
            - "cover_or_create"（默认）：复用覆盖该时间点的 item，否则新建
            - "exact_start"：仅复用起点精确一致的 item，否则新建
            - "always_new"：总是新建 item
        names: 可选 take 名称列表（List[str]）
        set_active: 可选激活 take 的索引（int）
        length: 可选 item 最小长度（float，秒）

    Returns:
        dict: REAPER 返回结果，成功时包含 item_guid/takes/active_take_guid/item_length/reused_item

    Examples:
        result = add_at_second(
            files=["C:/tmp/a.mid", "C:/tmp/b.mid"],
            track="Piano",
            second=12.0,
            item_match_mode="cover_or_create",
            set_active=0,
        )
        print(result["result"]["item_guid"])
    """
    payload: Dict[str, Any] = {"files": files}
    if item_guid is not None:
        payload["item_guid"] = item_guid
    if track is not None:
        payload["track"] = track
    if second is not None:
        payload["second"] = second
    if item_match_mode is not None:
        payload["item_match_mode"] = item_match_mode
    if names is not None:
        payload["names"] = names
    if set_active is not None:
        payload["set_active"] = set_active
    if length is not None:
        payload["length"] = length

    return bridge.call_reaper("take.add_at_second", payload)


def add_at_measure(
    files: List[str],
    item_guid: str | None = None,
    track: str | int | None = None,
    measure: float | None = None,
    item_match_mode: str | None = None,
    names: List[str] | None = None,
    set_active: int | None = None,
    length: float | None = None,
) -> Dict[str, Any]:
    """
    在指定小节位置添加 takes。

    Args:
        files: 待添加文件路径列表（List[str]），至少 1 个
        item_guid: 可选目标 item GUID（str）
        track: 可选轨道标识（str|int），当不提供 item_guid 时必填
        measure: 可选小节位置（float，1-based），当不提供 item_guid 时必填
        item_match_mode: 可选 item 匹配策略（str），同 add_at_second
        names: 可选 take 名称列表（List[str]）
        set_active: 可选激活 take 的索引（int）
        length: 可选 item 最小长度（float，秒）

    Returns:
        dict: REAPER 返回结果，成功时包含 item_guid/takes/active_take_guid/item_length/reused_item

    Examples:
        result = add_at_measure(
            files=["C:/tmp/a.mid"],
            track="Piano",
            measure=5.0,
            item_match_mode="always_new",
        )
        print(result["result"]["reused_item"])
    """
    payload: Dict[str, Any] = {"files": files}
    if item_guid is not None:
        payload["item_guid"] = item_guid
    if track is not None:
        payload["track"] = track
    if measure is not None:
        payload["measure"] = measure
    if item_match_mode is not None:
        payload["item_match_mode"] = item_match_mode
    if names is not None:
        payload["names"] = names
    if set_active is not None:
        payload["set_active"] = set_active
    if length is not None:
        payload["length"] = length

    return bridge.call_reaper("take.add_at_measure", payload)


def list(item_guid: str) -> Dict[str, Any]:
    """
    列出指定 item 的所有 takes。

    Args:
        item_guid: item GUID（str），如 "{...}"

    Returns:
        dict: REAPER 返回结果，成功时包含 takes/active_take_guid/count

    Examples:
        result = list(item_guid="{ABC-123}")
        print(result["result"]["count"])
    """
    return bridge.call_reaper("take.list", {"item_guid": item_guid})


def set_active(
    item_guid: str,
    take_index: int | None = None,
    take_guid: str | None = None,
) -> Dict[str, Any]:
    """
    切换指定 item 的激活 take（按索引或 GUID）。

    Args:
        item_guid: item GUID（str），如 "{...}"
        take_index: 可选 take 索引（int，0-based）
        take_guid: 可选 take GUID（str）

    Returns:
        dict: REAPER 返回结果，成功时包含 active_take_guid

    Examples:
        result = set_active(item_guid="{ABC-123}", take_index=1)
        print(result["result"]["active_take_guid"])
    """
    payload: Dict[str, Any] = {"item_guid": item_guid}
    if take_index is not None:
        payload["take_index"] = take_index
    if take_guid is not None:
        payload["take_guid"] = take_guid

    return bridge.call_reaper("take.set_active", payload)
