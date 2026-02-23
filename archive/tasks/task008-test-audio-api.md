# test audio api

-   [x] audio.insert_at_second(track, second, file_path)
-   [x] audio.insert_at_measure(track, measure, file_path)

有个坑就是 track 要 only selected

-   [x] audio.render_measures(tracks, begin, len)
-   [x] audio.render_seconds(tracks, begin, len)

导出的 track 需要涵盖 midi 和 wav 两种，测试已通过