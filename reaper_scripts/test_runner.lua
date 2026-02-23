-- Test Runner
-- 用于测试Orchestra客户端的简单测试脚本

local M = {}

-- 获取脚本目录并设置包路径
local _, filename = reaper.get_action_context()
local script_dir = filename:match("(.*[/\\])")
package.path = package.path .. ";" .. script_dir .. "?.lua"

local test_dir = script_dir .. "test"

-- 引入配置模块
local config = require("config")
local inbox_dir = config.get_inbox_dir()

function M.info(message)
    reaper.ShowConsoleMsg("[TestRunner] " .. message .. "\n")
end

function M.error(message)
    reaper.ShowConsoleMsg("[TestRunner ERROR] " .. message .. "\n")
end

-- 复制测试文件到inbox
function M.copy_test_file(test_subdir, test_filename)
    local timestamp = os.date("%Y%m%d_%H%M%S")
    local source_path = test_dir .. "/" .. test_subdir .. "/" .. test_filename
    local target_path = inbox_dir .. "/" .. timestamp .. "_" .. test_filename

    M.info("Copying test file: " .. test_subdir .. "/" .. test_filename)

    -- 读取源文件
    local source_file = io.open(source_path, "r")
    if not source_file then
        M.error("Cannot read test file: " .. source_path)
        return false
    end

    local content = source_file:read("*a")
    source_file:close()

    -- 写入目标文件（作为.part文件）
    local part_path = target_path .. ".part"
    local target_file = io.open(part_path, "w")
    if not target_file then
        M.error("Cannot write to inbox: " .. part_path)
        return false
    end

    target_file:write(content)
    target_file:close()

    -- 原子重命名
    local success = os.rename(part_path, target_path)
    if success then
        M.info("Test file ready: " .. test_subdir .. "/" .. test_filename)
        return true
    else
        M.error("Failed to finalize test file: " .. test_subdir .. "/" .. test_filename)
        return false
    end
end

-- 运行单个测试
function M.run_test(test_subdir, test_filename)
    M.info("Running test: " .. test_subdir .. "/" .. test_filename)

    -- 复制测试文件
    if not M.copy_test_file(test_subdir, test_filename) then
        return false
    end

    M.info("Test file copied. Check the results in outbox directory.")
    return true
end

-- 运行所有测试
function M.run_all_tests()
    M.info("Running all tests...")

    local test_files = {
        { subdir = "track",   filename = "track_create_test.json" },
        { subdir = "track",   filename = "track_delete_test.json" },
        { subdir = "track",   filename = "track_rename_test.json" },
        { subdir = "track",   filename = "track_set_color_test.json" },
        { subdir = "track",   filename = "track_clear_color_test.json" },
        { subdir = "track",   filename = "track_get_color_test.json" },
        { subdir = "track",   filename = "track_set_parent_as_test.json" },
        { subdir = "track",   filename = "track_set_mute_test.json" },
        { subdir = "track",   filename = "track_get_mute_test.json" },
        { subdir = "track",   filename = "track_set_solo_test.json" },
        { subdir = "track",   filename = "track_get_solo_test.json" },
        { subdir = "item",    filename = "item_create_at_second_test.json" },
        { subdir = "item",    filename = "item_create_at_measure_test.json" },
        { subdir = "item",    filename = "item_list_by_track_test.json" },
        { subdir = "item",    filename = "item_list_by_track_range_test.json" },
        { subdir = "item",    filename = "item_find_at_second_test.json" },
        { subdir = "item",    filename = "item_find_at_measure_test.json" },
        { subdir = "item",    filename = "item_set_color_test.json" },
        { subdir = "item",    filename = "item_get_color_test.json" },
        { subdir = "item",    filename = "item_clear_color_test.json" },
        { subdir = "take",    filename = "take_add_at_second_cover_or_create_test.json" },
        { subdir = "take",    filename = "take_add_at_second_always_new_test.json" },
        { subdir = "take",    filename = "take_add_at_measure_cover_or_create_test.json" },
        { subdir = "audio",   filename = "audio_insert_test.json" },
        { subdir = "audio",   filename = "audio_insert_at_second_test.json" },
        { subdir = "audio",   filename = "audio_insert_at_measure_test.json" },
        { subdir = "audio",   filename = "audio_render_seconds_test.json" },
        { subdir = "audio",   filename = "audio_render_measures_test.json" },
        { subdir = "midi",    filename = "midi_render_seconds_test.json" },
        { subdir = "midi",    filename = "midi_render_measures_test.json" },
        { subdir = "midi",    filename = "midi_insert_at_second_test.json" },
        { subdir = "midi",    filename = "midi_insert_at_measure_test.json" },
        { subdir = "midi",    filename = "midi_insert_named_track_test.json" },
        { subdir = "project", filename = "project_get_info_test.json" },
        { subdir = "project", filename = "project_get_track_count_test.json" },
        { subdir = "project", filename = "project_get_track_list_test.json" },
        { subdir = "project", filename = "project_get_selection_info_test.json" },
        { subdir = "project", filename = "project_get_selection_info_empty_test.json" },
        { subdir = "project", filename = "project_get_selection_info_multi_item_test.json" },
        { subdir = "project", filename = "project_get_selection_info_multi_track_test.json" },
        { subdir = "project", filename = "project_set_tempo_timesig_at_second_test.json" },
        { subdir = "project", filename = "project_set_project_timesig_test.json" },
        { subdir = "marker",  filename = "marker_create_test.json" },
        { subdir = "marker",  filename = "marker_list_test.json" },
        { subdir = "marker",  filename = "marker_update_test.json" },
        { subdir = "marker",  filename = "marker_delete_test.json" },
        { subdir = "common",  filename = "error_test_invalid_function.json" }
    }

    local success_count = 0
    for _, test_info in ipairs(test_files) do
        if M.run_test(test_info.subdir, test_info.filename) then
            success_count = success_count + 1
        end
        reaper.Sleep(500) -- 短暂延迟
    end

    M.info("Test run completed. " .. success_count .. "/" .. #test_files .. " tests prepared.")
end

-- 手动测试函数
function M.test_track_create()
    M.run_test("track", "track_create_test.json")
end

function M.test_track_delete()
    M.run_test("track", "track_delete_test.json")
end

function M.test_track_rename()
    M.run_test("track", "track_rename_test.json")
end

function M.test_track_set_color()
    M.run_test("track", "track_set_color_test.json")
end

function M.test_track_clear_color()
    M.run_test("track", "track_clear_color_test.json")
end

function M.test_track_get_color()
    M.run_test("track", "track_get_color_test.json")
end

function M.test_track_set_parent_as()
    M.run_test("track", "track_set_parent_as_test.json")
end

function M.test_track_set_mute()
    M.run_test("track", "track_set_mute_test.json")
end

function M.test_track_get_mute()
    M.run_test("track", "track_get_mute_test.json")
end

function M.test_track_set_solo()
    M.run_test("track", "track_set_solo_test.json")
end

function M.test_track_get_solo()
    M.run_test("track", "track_get_solo_test.json")
end

function M.test_item_create_at_second()
    M.run_test("item", "item_create_at_second_test.json")
end

function M.test_item_create_at_measure()
    M.run_test("item", "item_create_at_measure_test.json")
end

function M.test_item_list_by_track()
    M.run_test("item", "item_list_by_track_test.json")
end

function M.test_item_list_by_track_range()
    M.run_test("item", "item_list_by_track_range_test.json")
end

function M.test_item_find_at_second()
    M.run_test("item", "item_find_at_second_test.json")
end

function M.test_item_find_at_measure()
    M.run_test("item", "item_find_at_measure_test.json")
end

function M.test_item_set_color()
    M.run_test("item", "item_set_color_test.json")
end

function M.test_item_get_color()
    M.run_test("item", "item_get_color_test.json")
end

function M.test_item_clear_color()
    M.run_test("item", "item_clear_color_test.json")
end

function M.test_take_add_at_second_cover_or_create()
    M.run_test("take", "take_add_at_second_cover_or_create_test.json")
end

function M.test_take_add_at_second_always_new()
    M.run_test("take", "take_add_at_second_always_new_test.json")
end

function M.test_take_add_at_measure_cover_or_create()
    M.run_test("take", "take_add_at_measure_cover_or_create_test.json")
end

function M.test_project_info()
    M.run_test("project", "project_get_info_test.json")
end

function M.test_project_get_track_count()
    M.run_test("project", "project_get_track_count_test.json")
end

function M.test_project_get_track_list()
    M.run_test("project", "project_get_track_list_test.json")
end

function M.test_project_get_selection_info()
    M.run_test("project", "project_get_selection_info_test.json")
end

function M.test_project_get_selection_info_empty()
    M.run_test("project", "project_get_selection_info_empty_test.json")
end

function M.test_project_get_selection_info_multi_item()
    M.run_test("project", "project_get_selection_info_multi_item_test.json")
end

function M.test_project_get_selection_info_multi_track()
    M.run_test("project", "project_get_selection_info_multi_track_test.json")
end

function M.test_project_set_tempo_timesig_at_second()
    M.run_test("project", "project_set_tempo_timesig_at_second_test.json")
end

function M.test_project_set_project_timesig()
    M.run_test("project", "project_set_project_timesig_test.json")
end

function M.test_marker_create()
    M.run_test("marker", "marker_create_test.json")
end

function M.test_marker_list()
    M.run_test("marker", "marker_list_test.json")
end

function M.test_marker_update()
    M.run_test("marker", "marker_update_test.json")
end

function M.test_marker_delete()
    M.run_test("marker", "marker_delete_test.json")
end

function M.test_error_handling()
    M.run_test("common", "error_test_invalid_function.json")
end

-- Audio Test Functions
function M.test_audio_insert()
    M.run_test("audio", "audio_insert_test.json")
end

function M.test_audio_insert_at_second()
    M.run_test("audio", "audio_insert_at_second_test.json")
end

function M.test_audio_insert_at_measure()
    M.run_test("audio", "audio_insert_at_measure_test.json")
end

function M.test_audio_render_seconds()
    M.run_test("audio", "audio_render_seconds_test.json")
end

function M.test_audio_render_measures()
    M.run_test("audio", "audio_render_measures_test.json")
end

-- MIDI Test Functions
function M.test_midi_render_seconds()
    M.run_test("midi", "midi_render_seconds_test.json")
end

function M.test_midi_render_measures()
    M.run_test("midi", "midi_render_measures_test.json")
end

function M.test_midi_insert_at_second()
    M.run_test("midi", "midi_insert_at_second_test.json")
end

function M.test_midi_insert_at_measure()
    M.run_test("midi", "midi_insert_at_measure_test.json")
end

function M.test_midi_insert_named_track()
    M.run_test("midi", "midi_insert_named_track_test.json")
end

function M.show_menu()
    -- 1. 将菜单内容定义为一个清晰的字符串
    local menu_text = [[
==== Orchestra Test Menu ====
1.  Test Track Create
2.  Test Track Delete
3.  Test Track Rename
4.  Test Track Set Color
5.  Test Track Get Color
6.  Test Track Set Parent
7.  Test Track Set Mute
8.  Test Track Get Mute
9.  Test Track Set Solo
10. Test Track Get Solo
11. Test Item Create at Second
12. Test Item Create at Measure
13. Test Item List by Track
14. Test Item List by Track (Range)
15. Test Item Find at Second
16. Test Item Find at Measure
17. Test Item Set Color
18. Test Item Get Color
19. Test Item Clear Color
20. Test Take Add at Second (cover_or_create)
21. Test Take Add at Second (always_new)
22. Test Take Add at Measure (cover_or_create)
23. Test Audio Insert
24. Test Audio Insert at Second
25. Test Audio Insert at Measure
26. Test Audio Render Seconds
27. Test Audio Render Measures
28. Test MIDI Render Seconds
29. Test MIDI Render Measures
30. Test MIDI Insert at Second
31. Test MIDI Insert at Measure
32. Test MIDI Insert Named Track
33. Test Project Info
34. Test Project Get Track Count
35. Test Project Get Track List
36. Test Project Get Selection Info
37. Test Project Get Selection Info (Empty)
38. Test Project Get Selection Info (Multi Item)
39. Test Project Get Selection Info (Multi Track)
40. Test Project Set Tempo/TimeSig at Second
41. Test Project Set Project TimeSig
42. Test Marker Create
43. Test Marker List
44. Test Marker Update
45. Test Marker Delete
46. Test Error Handling
47. Run All Tests
48. Exit
===========================
]]

    -- 2. 核心改进：先在控制台显示菜单，防止用户看不见选项
    reaper.ShowConsoleMsg(menu_text)

    -- 3. 弹出简洁的输入框
    -- 注意：这里的提示语极短，确保它能显示出来
    local user_ok, input_str = reaper.GetUserInputs(
        "Orchestra Test (Check Console for Menu)", -- 标题提醒看控制台
        1,
        "Enter Choice (1-48):",                    -- 左侧提示保持简短
        ""
    )

    if not user_ok then
        M.info("操作已取消。")
        return
    end

    local choice = tonumber(input_str)

    -- 4. 校验逻辑 (保持你的原有逻辑)
    if not choice or choice < 1 or choice > 48 then
        reaper.ShowMessageBox("输入无效！请输入1-48之间的数字。", "错误", 0)
        return M.show_menu() -- 递归重新显示
    end

    -- 5. 执行对应操作
    if choice == 1 then
        M.test_track_create()
    elseif choice == 2 then
        M.test_track_delete()
    elseif choice == 3 then
        M.test_track_rename()
    elseif choice == 4 then
        M.test_track_set_color()
    elseif choice == 5 then
        M.test_track_get_color()
    elseif choice == 6 then
        M.test_track_set_parent_as()
    elseif choice == 7 then
        M.test_track_set_mute()
    elseif choice == 8 then
        M.test_track_get_mute()
    elseif choice == 9 then
        M.test_track_set_solo()
    elseif choice == 10 then
        M.test_track_get_solo()
    elseif choice == 11 then
        M.test_item_create_at_second()
    elseif choice == 12 then
        M.test_item_create_at_measure()
    elseif choice == 13 then
        M.test_item_list_by_track()
    elseif choice == 14 then
        M.test_item_list_by_track_range()
    elseif choice == 15 then
        M.test_item_find_at_second()
    elseif choice == 16 then
        M.test_item_find_at_measure()
    elseif choice == 17 then
        M.test_item_set_color()
    elseif choice == 18 then
        M.test_item_get_color()
    elseif choice == 19 then
        M.test_item_clear_color()
    elseif choice == 20 then
        M.test_take_add_at_second_cover_or_create()
    elseif choice == 21 then
        M.test_take_add_at_second_always_new()
    elseif choice == 22 then
        M.test_take_add_at_measure_cover_or_create()
    elseif choice == 23 then
        M.test_audio_insert()
    elseif choice == 24 then
        M.test_audio_insert_at_second()
    elseif choice == 25 then
        M.test_audio_insert_at_measure()
    elseif choice == 26 then
        M.test_audio_render_seconds()
    elseif choice == 27 then
        M.test_audio_render_measures()
    elseif choice == 28 then
        M.test_midi_render_seconds()
    elseif choice == 29 then
        M.test_midi_render_measures()
    elseif choice == 30 then
        M.test_midi_insert_at_second()
    elseif choice == 31 then
        M.test_midi_insert_at_measure()
    elseif choice == 32 then
        M.test_midi_insert_named_track()
    elseif choice == 33 then
        M.test_project_info()
    elseif choice == 34 then
        M.test_project_get_track_count()
    elseif choice == 35 then
        M.test_project_get_track_list()
    elseif choice == 36 then
        M.test_project_get_selection_info()
    elseif choice == 37 then
        M.test_project_get_selection_info_empty()
    elseif choice == 38 then
        M.test_project_get_selection_info_multi_item()
    elseif choice == 39 then
        M.test_project_get_selection_info_multi_track()
    elseif choice == 40 then
        M.test_project_set_tempo_timesig_at_second()
    elseif choice == 41 then
        M.test_project_set_project_timesig()
    elseif choice == 42 then
        M.test_marker_create()
    elseif choice == 43 then
        M.test_marker_list()
    elseif choice == 44 then
        M.test_marker_update()
    elseif choice == 45 then
        M.test_marker_delete()
    elseif choice == 46 then
        M.test_error_handling()
    elseif choice == 47 then
        M.run_all_tests()
    elseif choice == 48 then
        M.info("Test completed.")
    end
end

-- 启动测试
function M.start()
    M.info("Orchestra Test Runner Started")
    M.show_menu()
end

-- 运行测试
M.start()
