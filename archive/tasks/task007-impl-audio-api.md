# implement audio api

如 [](./task006-design-media-api.md) 中所述，实现 Audio API。

具体流程应该是创造一个 Audio 点 rule 的文件，然后在里面实现一下什么 render：

audio.render_measures(tracks, begin, len)
audio.render_seconds(tracks, begin, len)
audio.insert_at_measure(track, measure, file_path)
audio.insert_at_second(track, second, file_path)

tracks 是一个 track 列表，每个 track 可以是如下三种:

1. track_index: 轨道索引，从 0 开始，int 类型
2. track_guid: 轨道 GUID， string 类型
3. track_name: 轨道名称，string 类型

已经有 track.lua 实现了