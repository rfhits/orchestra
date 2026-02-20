"""
音频工具模块
提供音频渲染和媒体插入相关操作
"""

from typing import Any, Dict, List, Union

from mcp_bridge import bridge


def render_seconds(
    tracks: List[str | int],
    begin: float,
    length: float,
    filename: str,
) -> Dict[str, Any]:
    """
    按秒渲染音频文件

    从指定的时间范围内渲染轨道到音频文件。支持多轨同时渲染。

    Args:
        tracks: 轨道 ID 列表，支持以下格式混合使用：
                - 轨道索引（整数或字符串）: 0, 1, 2, "0", "1"
                - 轨道名称（字符串）: "Piano", "Violin", "Background Music"
                - GUID（字符串）: "{GUID...}"
                默认为空列表，将使用项目设置的渲染轨道
        begin: 起始时间（秒），必须 >= 0
               例如：0 表示从项目开始，10.5 表示从 10.5 秒处开始
        length: 渲染时长（秒），必须 > 0
                例如：10 表示渲染 10 秒，3.5 表示渲染 3.5 秒
        filename: 输出文件名（可选），支持格式：WAV, MP3, FLAC 等
                 如果为 None，将使用 REAPER 的默认设置
                 完整路径示例："/path/to/output.wav"

    Returns:
        dict: 渲染结果
        {
            "file_path": "/full/path/to/rendered_file.wav"  # 输出文件完整路径
        }

    Raises:
        Exception: 如果轨道不存在或渲染失败

    Examples:
        # 基本用法：渲染全部轨道的前 10 秒
        result = render_seconds()
        print(result["file_path"])  # /path/to/file.wav

        # 渲染特定轨道：从 5 秒处开始，渲染 8 秒
        result = render_seconds(
            tracks=["Piano", "Violin"],
            begin=5,
            length=8,
            filename="/tmp/duet.wav"
        )

        # 使用轨道索引混合渲染
        result = render_seconds(
            tracks=[0, 1, "Background"],  # 轨道 0、1 和名称为 "Background" 的轨道
            begin=0,
            length=20
        )

        # 渲染非整数秒数
        result = render_seconds(
            tracks=["Drums"],
            begin=0.5,  # 从 0.5 秒开始
            length=2.75  # 渲染 2.75 秒
        )
    """
    return bridge.call_reaper(
        "audio.render_seconds",
        {"tracks": tracks or [], "begin": begin, "len": length, "filename": filename},
    )


def render_measures(
    tracks: List[str | int],
    begin: float,
    length: float,
    filename: str,
) -> Dict[str, Any]:
    """
    按小节渲染音频文件

    从指定的小节范围内渲染轨道到音频文件。支持小数小节（如 1.5 表示第 1 小节的中点）。

    Args:
        tracks: 轨道 ID 列表，支持以下格式混合使用：
                - 轨道索引（整数或字符串）: 0, 1, 2, "0", "1"
                - 轨道名称（字符串）: "Piano", "Violin", "Background Music"
                - GUID（字符串）: "{GUID...}"
                默认为空列表，将使用项目设置的渲染轨道
        begin: 起始小节（1-based），必须 >= 1
               1 表示第 1 小节开始
               1.5 表示第 1 小节和第 2 小节的正中间
               2.75 表示第 2 小节过了 3/4 处
        length: 渲染小节数，必须 > 0
                1 表示渲染 1 小节
                2.5 表示渲染 2.5 小节
                0.5 表示渲染半小节
        filename: 输出文件名（可选），支持格式：WAV, MP3, FLAC 等
                 如果为 None，将使用 REAPER 的默认设置
                 完整路径示例："/path/to/output.wav"

    Returns:
        dict: 渲染结果
        {
            "file_path": "/full/path/to/rendered_file.wav"  # 输出文件完整路径
        }

    Raises:
        Exception: 如果轨道不存在或渲染失败

    Examples:
        # 基本用法：渲染第 1 小节
        result = render_measures()
        print(result["file_path"])

        # 渲染指定小节范围：第 2-5 小节
        result = render_measures(
            tracks=["Piano"],
            begin=2,
            length=4,  # 共 4 小节（第 2、3、4、5 小节）
            filename="/tmp/verse.wav"
        )

        # 使用小数小节：从第 1 小节中点开始，渲染 3 小节
        result = render_measures(
            tracks=["Strings"],
            begin=1.5,  # 从第 1 小节的中点开始
            length=3    # 渲染 3 小节
        )

        # 渲染半小节（用于上/下拍分离）
        result = render_measures(
            tracks=[0, 1, 2],
            begin=1,
            length=0.5  # 仅渲染半小节
        )

        # 渲染包含变拍的复杂段落
        result = render_measures(
            tracks=["Main Theme"],
            begin=8.25,  # 从第 8 小节的 1/4 处开始
            length=2.75  # 渲染约 2.75 小节
        )
    """
    return bridge.call_reaper(
        "audio.render_measures",
        {"tracks": tracks or [], "begin": begin, "len": length, "filename": filename},
    )


def insert(
    file_path: str, track: str | int, position: float
) -> Dict[str, Any]:
    """
    插入媒体文件到轨道（已弃用，推荐使用 insert_at_second 或 insert_at_measure）

    将音频、视频或 MIDI 文件插入到指定轨道的指定位置。

    Args:
        file_path: 媒体文件路径，必须存在且可读
                  支持格式：WAV, MP3, FLAC, OGG, MIDI, M4A 等
                  完整路径示例："/path/to/music.wav"
                  相对路径：支持（相对于 REAPER 项目）
        track: 目标轨道 ID，支持以下格式：
               - 轨道索引（整数或字符串）: 0, 1, "2"
               - 轨道名称（字符串）: "Piano", "Drums"
               - GUID（字符串）: "{GUID...}"
               如果为 None，将使用当前选中的轨道（推荐明确指定）
        position: 插入位置（秒），必须 >= 0
                 0 表示从项目开始
                 5.5 表示从 5.5 秒处插入

    Returns:
        dict: 插入结果
        {
            "success": true,
            "item": {...},  # 创建的 Media Item 对象
            "position": 5.5  # 实际插入位置
        }

    Raises:
        Exception: 如果文件不存在或轨道不存在

    Warning:
        此函数已弃用，推荐使用：
        - insert_at_second() - 按秒数插入
        - insert_at_measure() - 按小节插入

    Examples:
        # 插入音频文件（不推荐，使用 insert_at_second 代替）
        result = insert(
            file_path="/path/to/drum_loop.wav",
            track="Drums",
            position=2.0
        )
    """
    return bridge.call_reaper(
        "audio.insert", {"file_path": file_path, "track": track, "position": position}
    )


def insert_at_second(
    file_path: str, track: str | int, second: float
) -> Dict[str, Any]:
    """
    在指定秒数位置插入媒体文件到轨道

    将音频、视频或 MIDI 文件插入到指定轨道的指定时间点。

    Args:
        file_path: 媒体文件路径，必须存在且可读
                  支持格式：WAV, MP3, FLAC, OGG, M4A 等
                  完整路径示例："/path/to/music.wav"
                  相对路径：支持（相对于 REAPER 项目）
                  重要：MIDI 文件请使用 midi.insert_at_second()，此函数不支持 MIDI
        track: 目标轨道 ID，必须指定（不能为 None），支持以下格式：
               - 轨道索引（整数或字符串）: 0, 1, "2"
               - 轨道名称（字符串）: "Piano", "Vocal Track"
               - GUID（字符串）: "{GUID...}"
        second: 插入时间点（秒），必须 >= 0
               0 表示从项目开始
               10.5 表示从 10.5 秒处插入
               支持非整数秒数

    Returns:
        dict: 插入结果
        {
            "success": true,
            "message": "Media inserted successfully",
            "length": 3.5,  # 插入文件的时长（秒）
            "position": 10.5  # 实际插入位置（秒）
        }

    Raises:
        Exception: 如果文件不存在、轨道不存在或文件格式不支持

    Examples:
        # 在音乐轨道的 5 秒处插入背景音乐
        result = insert_at_second(
            file_path="/music/background.mp3",
            track="Background",
            second=5.0
        )
        print(f"插入了 {result['length']}s 的音频")

        # 在指定轨道索引插入音频
        result = insert_at_second(
            file_path="/samples/snare_roll.wav",
            track=1,  # 第 2 条轨道（0-based）
            second=2.75
        )

        # 在项目开始处插入
        result = insert_at_second(
            file_path="/intro.wav",
            track="Main"
        )

        # 在非整数秒数处插入
        result = insert_at_second(
            file_path="/path/to/sound.wav",
            track="SFX",
            second=15.333  # 15.333 秒处
        )
    """
    return bridge.call_reaper(
        "audio.insert_at_second",
        {"file_path": file_path, "track": track, "second": second},
    )


def insert_at_measure(
    file_path: str, track: str | int, measure: float
) -> Dict[str, Any]:
    """
    在指定小节位置插入媒体文件到轨道

    将音频、视频或 MIDI 文件插入到指定轨道的指定小节。支持小数小节。

    Args:
        file_path: 媒体文件路径，必须存在且可读
                  支持格式：WAV, MP3, FLAC, OGG, M4A 等
                  完整路径示例："/path/to/music.wav"
                  相对路径：支持（相对于 REAPER 项目）
                  重要：MIDI 文件请使用 midi.insert_at_measure()，此函数不支持 MIDI
        track: 目标轨道 ID，必须指定（不能为 None），支持以下格式：
               - 轨道索引（整数或字符串）: 0, 1, "2"
               - 轨道名称（字符串）: "Drums", "Synth Lead"
               - GUID（字符串）: "{GUID...}"
        measure: 插入小节（1-based），必须 >= 1
                1 表示从第 1 小节开始
                2 表示从第 2 小节开始
                1.5 表示从第 1 小节的中点开始
                2.75 表示从第 2 小节过了 3/4 处开始
                支持任意精度的小数小节

    Returns:
        dict: 插入结果
        {
            "success": true,
            "message": "Media inserted successfully",
            "length": 3.5,  # 插入文件的时长（秒）
            "measure": 2,   # 实际插入小节
            "position": 8.5  # 对应的秒数位置
        }

    Raises:
        Exception: 如果文件不存在、轨道不存在或文件格式不支持

    Examples:
        # 在第 2 小节开始处插入鼓声循环
        result = insert_at_measure(
            file_path="/samples/drum_loop.wav",
            track="Drums",
            measure=2
        )

        # 在第 1 小节的中点（上拍）插入音效
        result = insert_at_measure(
            file_path="/sfx/impact.wav",
            track="SFX",
            measure=1.5  # 第 1 小节的中点
        )

        # 在第 5 小节的最后四分之一处插入过渡音乐
        result = insert_at_measure(
            file_path="/transitions/rise.wav",
            track="Transition",
            measure=5.75  # 从第 5 小节的 75% 处开始
        )

        # 在复杂的拍号变化中插入（自动计算时间）
        result = insert_at_measure(
            file_path="/loops/bass_line.wav",
            track="Bass",
            measure=8.25  # 会自动根据 TimeMap 计算实际秒数
        )

        # 在项目开始处插入（第 1 小节）
        result = insert_at_measure(
            file_path="/intro.wav",
            track="Main"  # 使用默认 measure=1
        )
    """
    return bridge.call_reaper(
        "audio.insert_at_measure",
        {"file_path": file_path, "track": track, "measure": measure},
    )
