"""
Item 工具模块
提供 item 的创建、查询、定位与长度设置接口。
"""

from typing import Any, Dict, List

from mcp_bridge import bridge


def create_at_second(track: str | int, second: float, length: float) -> Dict[str, Any]:
    """
    在指定秒数创建 item。

    Args:
        track: 轨道标识（str|int），支持轨道名、索引或 GUID
        second: 起始时间（float，秒），必须 >= 0
        length: item 长度（float，秒），必须 > 0

    Returns:
        dict: REAPER 返回结果，成功时包含 item_guid/item_length/item_position

    Examples:
        result = create_at_second(track="Piano", second=12.0, length=4.0)
        print(result["result"]["item_guid"])
    """
    return bridge.call_reaper(
        "item.create_at_second",
        {
            "track": track,
            "second": second,
            "length": length,
        },
    )


def create_at_measure(track: str | int, measure: float, length: float) -> Dict[str, Any]:
    """
    在指定小节创建 item。

    Args:
        track: 轨道标识（str|int），支持轨道名、索引或 GUID
        measure: 小节位置（float，1-based），必须 >= 1
        length: item 长度（float，秒），必须 > 0

    Returns:
        dict: REAPER 返回结果，成功时包含 item_guid/item_length/item_position

    Examples:
        result = create_at_measure(track="Piano", measure=5.0, length=2.0)
        print(result["result"]["item_position"])
    """
    return bridge.call_reaper(
        "item.create_at_measure",
        {
            "track": track,
            "measure": measure,
            "length": length,
        },
    )


def find_by_guid(item_guid: str) -> Dict[str, Any]:
    """
    通过 item GUID 查询 item 详情。

    Args:
        item_guid: item GUID（str），如 "{...}"

    Returns:
        dict: REAPER 返回结果，成功时包含位置、长度、轨道信息等

    Examples:
        result = find_by_guid(item_guid="{ABC-123}")
        print(result["result"]["item_length"])
    """
    return bridge.call_reaper("item.find_by_guid", {"item_guid": item_guid})


def set_color(
    item_guid: str,
    color: List[int] | None = None,
    clear: bool = False,
) -> Dict[str, Any]:
    """
    设置 item 颜色。

    Args:
        item_guid: item GUID
        color: RGB 颜色数组 [r, g, b]，clear=False 时必填
        clear: 是否清除 item 自定义颜色

    Notes:
        - 传入 [0, 0, 0] 会设置“自定义黑色”，不是“恢复默认颜色”。
        - 这是 REAPER I_CUSTOMCOLOR 的语义：自定义颜色需要通过 clear=True（底层写 0）来清除。
        - 如需恢复主题默认 item 颜色，请使用 clear=True，而不是 color=[0, 0, 0]。
    """
    payload: Dict[str, Any] = {"item_guid": item_guid, "clear": clear}
    if color is not None:
        payload["color"] = color
    return bridge.call_reaper("item.set_color", payload)


def get_color(item_guid: str) -> Dict[str, Any]:
    """
    获取 item 颜色。
    """
    return bridge.call_reaper("item.get_color", {"item_guid": item_guid})


def list_by_track(
    track: str | int,
    begin_second: float | None = None,
    end_second: float | None = None,
    include_takes: bool = False,
) -> Dict[str, Any]:
    """
    列出指定轨道上的 items（可按时间范围过滤）。

    Args:
        track: 轨道标识（str|int），支持轨道名、索引或 GUID
        begin_second: 可选起始时间（float，秒），用于范围过滤
        end_second: 可选结束时间（float，秒），用于范围过滤
        include_takes: 是否内联返回 takes 详情（bool）

    Returns:
        dict: REAPER 返回结果，成功时包含 track/items/count

    Examples:
        result = list_by_track(track="Piano", begin_second=10.0, end_second=20.0)
        print(result["result"]["count"])
    """
    payload: Dict[str, Any] = {
        "track": track,
        "include_takes": include_takes,
    }
    if begin_second is not None:
        payload["begin_second"] = begin_second
    if end_second is not None:
        payload["end_second"] = end_second

    return bridge.call_reaper("item.list_by_track", payload)


def find_at_second(
    track: str | int,
    second: float,
    match_mode: str = "cover",
    include_takes: bool = False,
) -> Dict[str, Any]:
    """
    在指定轨道的秒数位置查找 item。

    Args:
        track: 轨道标识（str|int），支持轨道名、索引或 GUID
        second: 查找时间点（float，秒），必须 >= 0
        match_mode: 匹配模式（str）
            - "cover": 命中覆盖该时间点的 item
            - "exact_start": 仅命中起点精确一致的 item
            - "always_new"/"cover_or_create": 与 Lua 侧兼容的额外模式（查询时通常用 cover 或 exact_start）
        include_takes: 是否内联返回 takes 详情（bool）

    Returns:
        dict: REAPER 返回结果，成功时包含 found 与 item（若命中）

    Examples:
        result = find_at_second(track="Piano", second=12.0, match_mode="cover")
        print(result["result"]["found"])
    """
    return bridge.call_reaper(
        "item.find_at_second",
        {
            "track": track,
            "second": second,
            "match_mode": match_mode,
            "include_takes": include_takes,
        },
    )


def find_at_measure(
    track: str | int,
    measure: float,
    match_mode: str = "cover",
    include_takes: bool = False,
) -> Dict[str, Any]:
    """
    在指定轨道的小节位置查找 item。

    Args:
        track: 轨道标识（str|int），支持轨道名、索引或 GUID
        measure: 查找小节（float，1-based），必须 >= 1
        match_mode: 匹配模式（str），同 find_at_second
        include_takes: 是否内联返回 takes 详情（bool）

    Returns:
        dict: REAPER 返回结果，成功时包含 found 与 item（若命中）

    Examples:
        result = find_at_measure(track="Piano", measure=5.0, match_mode="cover")
        print(result["result"]["found"])
    """
    return bridge.call_reaper(
        "item.find_at_measure",
        {
            "track": track,
            "measure": measure,
            "match_mode": match_mode,
            "include_takes": include_takes,
        },
    )


def set_length(item_guid: str, length: float) -> Dict[str, Any]:
    """
    设置 item 长度（秒）。

    Args:
        item_guid: item GUID（str），如 "{...}"
        length: 目标长度（float，秒），必须 > 0

    Returns:
        dict: REAPER 返回结果，成功时包含 item_guid/item_length

    Examples:
        result = set_length(item_guid="{ABC-123}", length=8.0)
        print(result["result"]["item_length"])
    """
    return bridge.call_reaper(
        "item.set_length",
        {
            "item_guid": item_guid,
            "length": length,
        },
    )


def split(item_guid: str, times: List[float]) -> Dict[str, Any]:
    """
    在指定绝对时间点将 item 切分为多段。

    Args:
        item_guid: 目标 item GUID
        times: 切分时间点（秒，项目绝对时间）

    Returns:
        dict: REAPER 返回结果，成功时包含切分后的 item 列表
    """
    return bridge.call_reaper(
        "item.split",
        {
            "item_guid": item_guid,
            "times": times,
        },
    )


def merge(item_guids: List[str]) -> Dict[str, Any]:
    """
    将多个 item 合并为一个新 item。

    Args:
        item_guids: 待合并 item GUID 列表

    Returns:
        dict: REAPER 返回结果，成功时包含合并后的新 item 信息
    """
    return bridge.call_reaper(
        "item.merge",
        {
            "item_guids": item_guids,
        },
    )


def delete(item_guid: str) -> Dict[str, Any]:
    """
    删除指定 item。

    Args:
        item_guid: 目标 item GUID

    Returns:
        dict: REAPER 返回结果，成功时包含 deleted 标记
    """
    return bridge.call_reaper(
        "item.delete",
        {
            "item_guid": item_guid,
        },
    )
