"""
MIDI 工具模块
提供 MIDI 导出和导入相关操作

MIDI 导出采用多文件夹结构，每个导出会生成一个独立文件夹，包含多个轨道的 MIDI 文件。
MIDI 导入使用静默模式（无弹窗），自动处理 TimeMap 信息。
"""

from typing import Any, Dict, List, Union

from mcp_bridge import bridge


def render_seconds(
    tracks: List[str | int],
    begin: float,
    length: float,
    session_id: str,
) -> Dict[str, Any]:
    """
    按秒导出 MIDI 文件到目录

    从指定的时间范围内导出轨道的 MIDI 数据到文件夹。
    每条轨道生成一个独立的 .mid 文件，文件夹会自动创建。

    Args:
        tracks: 轨道 ID 列表，支持以下格式混合使用：
                - 轨道索引（整数或字符串）: 0, 1, 2, "0", "1"
                - 轨道名称（字符串）: "Piano", "Violin", "MIDI Track"
                - GUID（字符串）: "{GUID...}"
                必须指定至少一条轨道（不能为空列表）
                重要：只有包含 MIDI 数据的轨道会被导出
        begin: 起始时间（秒），必须 >= 0
               0 表示从项目开始
               5.5 表示从 5.5 秒处开始
               支持非整数秒数
        length: 导出时长（秒），必须 > 0
               10 表示导出 10 秒
               3.5 表示导出 3.5 秒
               支持非整数秒数
        session_id: 会话 ID，用于区分不同导出任务，默认 "sec"
                   文件夹名格式：{YYYYMMDD_HHMMSS}_{session_id}
                   示例："my_export" -> "20260118_104412_my_export"
                   用途：便于管理多个导出任务的结果
                   建议使用有意义的名称，如 "intro", "chorus", "ending"

    Returns:
        dict: 导出结果
        {
            "path": "/full/path/to/20260118_104412_sec",  # 输出文件夹完整路径
            "folder_name": "20260118_104412_sec",  # 文件夹名称
            "session_id": "sec"  # 会话 ID
        }

        文件夹内的文件结构：
        {
            "01_Piano.mid",
            "02_Violin.mid",
            "03_Cello.mid"
        }

    Raises:
        Exception: 如果轨道不存在、无 MIDI 数据或导出失败

    Examples:
        # 基本用法：导出前 10 秒
        result = render_seconds(
            tracks=["Piano"],
            begin=0,
            length=10
        )
        print(result["path"])  # /path/to/outbox/20260118_104412_sec

        # 导出多条轨道，使用自定义会话 ID
        result = render_seconds(
            tracks=["Piano", "Violin", "Cello"],
            begin=0,
            length=32,  # 导出 32 秒
            session_id="string_quartet_take1"
        )
        folder = result["path"]
        # 文件：01_Piano.mid, 02_Violin.mid, 03_Cello.mid

        # 从中间时间开始导出
        result = render_seconds(
            tracks=[0, 1, 2],  # 使用轨道索引
            begin=5.5,  # 从 5.5 秒开始
            length=15.75,  # 导出 15.75 秒
            session_id="chorus_take2"
        )

        # 导出非整数秒数段落
        result = render_seconds(
            tracks=["Synth Lead"],
            begin=0.333,
            length=2.667,
            session_id="short_solo"
        )
    """
    return bridge.call_reaper(
        "midi.render_seconds",
        {
            "tracks": tracks or [],
            "begin": begin,
            "len": length,
            "session_id": session_id,
        },
    )


def render_measures(
    tracks: List[str | int],
    begin: float,
    length: float,
    session_id: str,
) -> Dict[str, Any]:
    """
    按小节导出 MIDI 文件到目录

    从指定的小节范围内导出轨道的 MIDI 数据到文件夹。
    支持小数小节，自动处理变拍和变速。

    Args:
        tracks: 轨道 ID 列表，支持以下格式混合使用：
                - 轨道索引（整数或字符串）: 0, 1, 2, "0", "1"
                - 轨道名称（字符串）: "Piano", "Strings", "Percussion"
                - GUID（字符串）: "{GUID...}"
                必须指定至少一条轨道（不能为空列表）
                重要：只有包含 MIDI 数据的轨道会被导出
        begin: 起始小节（1-based），必须 >= 1
               1 表示从第 1 小节开始
               2 表示从第 2 小节开始
               1.5 表示从第 1 小节的中点开始
               2.75 表示从第 2 小节过了 3/4 处开始
               支持任意精度的小数小节
        length: 导出小节数，必须 > 0
               1 表示导出 1 小节
               4 表示导出 4 小节
               2.5 表示导出 2.5 小节
               0.5 表示导出半小节
        session_id: 会话 ID，用于区分不同导出任务，默认 "meas"
                   文件夹名格式：{YYYYMMDD_HHMMSS}_{session_id}
                   示例："verse" -> "20260118_104412_verse"
                   建议使用有意义的名称，如 "intro", "verse", "chorus", "bridge"

    Returns:
        dict: 导出结果
        {
            "path": "/full/path/to/20260118_104412_meas",  # 输出文件夹完整路径
            "folder_name": "20260118_104412_meas",  # 文件夹名称
            "session_id": "meas"  # 会话 ID
        }

        文件夹内的文件结构：
        {
            "01_Piano.mid",
            "02_Violin.mid",
            "03_Viola.mid",
            "04_Cello.mid"
        }

    Raises:
        Exception: 如果轨道不存在、无 MIDI 数据或导出失败

    Examples:
        # 导出第 1-4 小节
        result = render_measures(
            tracks=["Piano"],
            begin=1,
            length=4,
            session_id="intro"
        )

        # 导出复杂的部分：第 5 小节到第 12 小节（8 小节）
        result = render_measures(
            tracks=["Piano", "Strings", "Brass"],
            begin=5,
            length=8,
            session_id="main_theme"
        )

        # 从中间小节开始导出
        result = render_measures(
            tracks=[0, 1, 2, 3],
            begin=9,  # 从第 9 小节开始
            length=16,  # 导出 16 小节
            session_id="chorus"
        )

        # 导出小数小节范围（上/下拍分离）
        result = render_measures(
            tracks=["Lead", "Harmony"],
            begin=1.5,  # 从第 1 小节的中点开始
            length=3.5,  # 导出 3.5 小节
            session_id="bridge"
        )

        # 导出变拍段落（自动计算）
        result = render_measures(
            tracks=["Melodic"],
            begin=20.75,  # 从第 20 小节的 3/4 处开始
            length=2,  # 导出 2 小节
            session_id="transition"
        )

        # 导出单个半小节
        result = render_measures(
            tracks=["SFX"],
            begin=5,
            length=0.5,  # 仅导出半小节
            session_id="fill"
        )
    """
    return bridge.call_reaper(
        "midi.render_measures",
        {
            "tracks": tracks or [],
            "begin": begin,
            "len": length,
            "session_id": session_id,
        },
    )


def insert_at_second(
    file_path: str, track: str | int, second: float
) -> Dict[str, Any]:
    """
    在指定秒数位置导入 MIDI 文件到轨道（静默导入，无弹窗）

    将 MIDI 文件导入到指定轨道的指定时间点。
    完全静默执行，自动处理 TimeMap 信息，即使 MIDI 包含变速变拍也无需确认。

    Args:
        file_path: MIDI 文件路径，必须存在且以 .mid 结尾
                  完整路径示例："/path/to/music.mid"
                  相对路径：支持（相对于 REAPER 项目）
                  重要：必须是 MIDI 文件（.mid 扩展名），不支持其他格式
                  常见路径：
                  - Windows: "C:\\Users\\Music\\piece.mid"
                  - Linux/Mac: "/home/user/music/piece.mid"
        track: 目标轨道 ID，必须指定（不能为 None），支持以下格式：
               - 轨道索引（整数或字符串）: 0, 1, "2"
               - 轨道名称（字符串）: "Piano", "Synth Lead"
               - GUID（字符串）: "{GUID...}"
               轨道必须存在且是 MIDI 轨道
        second: 导入时间点（秒），必须 >= 0
               0 表示从项目开始
               10.5 表示从 10.5 秒处导入
               支持非整数秒数
               精度：可精确到千分之一秒

    Returns:
        dict: 导入结果
        {
            "success": true,
            "message": "MIDI imported successfully",
            "length": 3.5,  # 导入的 MIDI 文件时长（秒）
            "item": {...}  # 创建的 Media Item 对象
        }

    Raises:
        Exception: 如果文件不存在、不是 MIDI 文件或轨道不存在

    Important:
        - ✓ 自动处理 TimeMap：包含 BPM 变化、拍号变化的 MIDI 自动导入
        - ✓ 无弹窗：即使 MIDI 有 TimeMap 也不会弹窗确认
        - ✓ 完全静默：整个操作在后台完成
        - ⚠ 不支持 WAV、MP3 等音频格式，请使用 audio.insert_at_second()

    Examples:
        # 基本用法：在 0 秒处导入 MIDI
        result = insert_at_second(
            file_path="/path/to/melody.mid",
            track="Piano"
        )
        print(f"导入的 MIDI 长度：{result['length']}秒")

        # 在指定秒数处导入
        result = insert_at_second(
            file_path="/samples/solo.mid",
            track="Synth Lead",
            second=5.0
        )

        # 使用轨道索引
        result = insert_at_second(
            file_path="/midi/bass_line.mid",
            track=2,  # 第 3 条轨道
            second=8.5
        )

        # 导入带 TimeMap 的 MIDI（自动处理，无弹窗）
        result = insert_at_second(
            file_path="/exports/complex_piece.mid",
            track="Melodic",
            second=0
        )

        # 在非整数秒数处导入
        result = insert_at_second(
            file_path="/riff.mid",
            track=0,
            second=12.333
        )

        # 连续导入多个 MIDI 片段
        clips = ["intro.mid", "verse.mid", "chorus.mid"]
        position = 0
        for clip in clips:
            result = insert_at_second(
                file_path=f"/parts/{clip}",
                track="Main",
                second=position
            )
            position += result["length"]
    """
    return bridge.call_reaper(
        "midi.insert_at_second",
        {"file_path": file_path, "track": track, "second": second},
    )


def insert_at_measure(
    file_path: str, track: str | int, measure: float
) -> Dict[str, Any]:
    """
    在指定小节位置导入 MIDI 文件到轨道（静默导入，无弹窗）

    将 MIDI 文件导入到指定轨道的指定小节。支持小数小节。
    完全静默执行，自动处理 TimeMap 信息和变拍。

    Args:
        file_path: MIDI 文件路径，必须存在且以 .mid 结尾
                  完整路径示例："/path/to/music.mid"
                  相对路径：支持（相对于 REAPER 项目）
                  重要：必须是 MIDI 文件（.mid 扩展名），不支持其他格式
        track: 目标轨道 ID，必须指定（不能为 None），支持以下格式：
               - 轨道索引（整数或字符串）: 0, 1, "2"
               - 轨道名称（字符串）: "Piano", "Strings", "Drums"
               - GUID（字符串）: "{GUID...}"
               轨道必须存在且是 MIDI 轨道
        measure: 导入小节（1-based），必须 >= 1
                1 表示从第 1 小节开始
                2 表示从第 2 小节开始
                1.5 表示从第 1 小节的中点开始
                2.75 表示从第 2 小节过了 3/4 处开始
                支持任意精度的小数小节

    Returns:
        dict: 导入结果
        {
            "success": true,
            "message": "MIDI imported successfully",
            "length": 4.0,  # 导入的 MIDI 文件时长（秒）
            "measure": 1,  # 导入的小节号
            "position": 0.0  # 对应的秒数位置
        }

    Raises:
        Exception: 如果文件不存在、不是 MIDI 文件、小节号无效或轨道不存在

    Important:
        - ✓ 自动处理 TimeMap：根据项目的变速变拍自动计算实际时间位置
        - ✓ 无弹窗：即使 MIDI 包含 BPM/拍号变化也不会弹窗确认
        - ✓ 完全静默：整个操作在后台完成
        - ⚠ 不支持 WAV、MP3 等音频格式，请使用 audio.insert_at_measure()

    Examples:
        # 基本用法：在第 1 小节开始处导入
        result = insert_at_measure(
            file_path="/path/to/theme.mid",
            track="Piano"
        )

        # 在第 2 小节处导入
        result = insert_at_measure(
            file_path="/samples/verse.mid",
            track="Main",
            measure=2
        )

        # 在第 1 小节的中点导入（上拍）
        result = insert_at_measure(
            file_path="/riff.mid",
            track="Lead",
            measure=1.5
        )

        # 在复杂位置导入（第 5 小节的 3/4 处）
        result = insert_at_measure(
            file_path="/ending.mid",
            track="Strings",
            measure=5.75
        )

        # 使用轨道索引
        result = insert_at_measure(
            file_path="/bass.mid",
            track=1,  # 第 2 条轨道
            measure=3
        )

        # 导入带 TimeMap 的复杂 MIDI（自动处理变拍）
        result = insert_at_measure(
            file_path="/exports/progressive_piece.mid",
            track="Melodic",
            measure=8.5  # 第 8 小节的中点
        )

        # 组装多个 MIDI 片段成完整乐曲
        sections = [
            ("intro.mid", 1),
            ("verse.mid", 5),
            ("chorus.mid", 13),
            ("bridge.mid", 21),
            ("outro.mid", 29)
        ]
        for clip, measure_pos in sections:
            result = insert_at_measure(
                file_path=f"/parts/{clip}",
                track="Composition",
                measure=measure_pos
            )
            print(f"导入 {clip} 到第 {measure_pos} 小节 ({result['position']}s)")
    """
    return bridge.call_reaper(
        "midi.insert_at_measure",
        {"file_path": file_path, "track": track, "measure": measure},
    )
