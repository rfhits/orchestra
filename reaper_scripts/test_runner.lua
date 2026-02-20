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
        { subdir = "track",   filename = "track_get_color_test.json" },
        { subdir = "track",   filename = "track_set_parent_as_test.json" },
        { subdir = "item",    filename = "item_create_at_second_test.json" },
        { subdir = "item",    filename = "item_create_at_measure_test.json" },
        { subdir = "item",    filename = "item_list_by_track_test.json" },
        { subdir = "item",    filename = "item_list_by_track_range_test.json" },
        { subdir = "item",    filename = "item_find_at_second_test.json" },
        { subdir = "item",    filename = "item_find_at_measure_test.json" },
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
        { subdir = "project", filename = "project_set_tempo_timesig_at_second_test.json" },
        { subdir = "project", filename = "project_set_project_timesig_test.json" },
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

function M.test_track_get_color()
    M.run_test("track", "track_get_color_test.json")
end

function M.test_track_set_parent_as()
    M.run_test("track", "track_set_parent_as_test.json")
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

function M.test_project_set_tempo_timesig_at_second()
    M.run_test("project", "project_set_tempo_timesig_at_second_test.json")
end

function M.test_project_set_project_timesig()
    M.run_test("project", "project_set_project_timesig_test.json")
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
7.  Test Item Create at Second
8.  Test Item Create at Measure
9.  Test Item List by Track
10. Test Item List by Track (Range)
11. Test Item Find at Second
12. Test Item Find at Measure
13. Test Take Add at Second (cover_or_create)
14. Test Take Add at Second (always_new)
15. Test Take Add at Measure (cover_or_create)
16. Test Audio Insert
17. Test Audio Insert at Second
18. Test Audio Insert at Measure
19. Test Audio Render Seconds
20. Test Audio Render Measures
21. Test MIDI Render Seconds
22. Test MIDI Render Measures
23. Test MIDI Insert at Second
24. Test MIDI Insert at Measure
25. Test MIDI Insert Named Track
26. Test Project Info
27. Test Project Get Track Count
28. Test Project Get Track List
29. Test Project Set Tempo/TimeSig at Second
30. Test Project Set Project TimeSig
31. Test Error Handling
32. Run All Tests
33. Exit
===========================
]]

    -- 2. 核心改进：先在控制台显示菜单，防止用户看不见选项
    reaper.ShowConsoleMsg(menu_text)

    -- 3. 弹出简洁的输入框
    -- 注意：这里的提示语极短，确保它能显示出来
    local user_ok, input_str = reaper.GetUserInputs(
        "Orchestra Test (Check Console for Menu)", -- 标题提醒看控制台
        1,
        "Enter Choice (1-33):",                    -- 左侧提示保持简短
        ""
    )

    if not user_ok then
        M.info("操作已取消。")
        return
    end

    local choice = tonumber(input_str)

    -- 4. 校验逻辑 (保持你的原有逻辑)
    if not choice or choice < 1 or choice > 33 then
        reaper.ShowMessageBox("输入无效！请输入1-33之间的数字。", "错误", 0)
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
        M.test_item_create_at_second()
    elseif choice == 8 then
        M.test_item_create_at_measure()
    elseif choice == 9 then
        M.test_item_list_by_track()
    elseif choice == 10 then
        M.test_item_list_by_track_range()
    elseif choice == 11 then
        M.test_item_find_at_second()
    elseif choice == 12 then
        M.test_item_find_at_measure()
    elseif choice == 13 then
        M.test_take_add_at_second_cover_or_create()
    elseif choice == 14 then
        M.test_take_add_at_second_always_new()
    elseif choice == 15 then
        M.test_take_add_at_measure_cover_or_create()
    elseif choice == 16 then
        M.test_audio_insert()
    elseif choice == 17 then
        M.test_audio_insert_at_second()
    elseif choice == 18 then
        M.test_audio_insert_at_measure()
    elseif choice == 19 then
        M.test_audio_render_seconds()
    elseif choice == 20 then
        M.test_audio_render_measures()
    elseif choice == 21 then
        M.test_midi_render_seconds()
    elseif choice == 22 then
        M.test_midi_render_measures()
    elseif choice == 23 then
        M.test_midi_insert_at_second()
    elseif choice == 24 then
        M.test_midi_insert_at_measure()
    elseif choice == 25 then
        M.test_midi_insert_named_track()
    elseif choice == 26 then
        M.test_project_info()
    elseif choice == 27 then
        M.test_project_get_track_count()
    elseif choice == 28 then
        M.test_project_get_track_list()
    elseif choice == 29 then
        M.test_project_set_tempo_timesig_at_second()
    elseif choice == 30 then
        M.test_project_set_project_timesig()
    elseif choice == 31 then
        M.test_error_handling()
    elseif choice == 32 then
        M.run_all_tests()
    elseif choice == 33 then
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
