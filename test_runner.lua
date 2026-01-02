-- Test Runner
-- 用于测试Orchestra客户端的简单测试脚本

local M = {}

-- 获取脚本目录
local _, filename = reaper.get_action_context()
local script_dir = filename:match("(.*[/\\])")
local test_dir = script_dir .. "test"
local cases_dir = test_dir .. "/cases"
local inbox_dir = reaper.GetResourcePath() .. "/.orchestra/inbox"

function M.info(message)
    reaper.ShowConsoleMsg("[TestRunner] " .. message .. "\n")
end

function M.error(message)
    reaper.ShowConsoleMsg("[TestRunner ERROR] " .. message .. "\n")
end

-- 复制测试文件到inbox
function M.copy_test_file(test_filename)
    local timestamp = os.date("%Y%m%d_%H%M%S")
    local source_path = cases_dir .. "/" .. test_filename
    local target_path = inbox_dir .. "/" .. timestamp .. "_" .. test_filename

    M.info("Copying test file: " .. test_filename)

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
        M.info("Test file ready: " .. test_filename)
        return true
    else
        M.error("Failed to finalize test file: " .. test_filename)
        return false
    end
end

-- 运行单个测试
function M.run_test(test_filename)
    M.info("Running test: " .. test_filename)

    -- 复制测试文件
    if not M.copy_test_file(test_filename) then
        return false
    end

    M.info("Test file copied. Check the results in outbox directory.")
    return true
end

-- 运行所有测试
function M.run_all_tests()
    M.info("Running all tests...")

    local test_files = {
        "track_create_test.json",
        "track_delete_test.json",
        "media_insert_test.json",
        "project_get_info_test.json",
        "error_test_invalid_function.json"
    }

    local success_count = 0
    for _, test_file in ipairs(test_files) do
        if M.run_test(test_file) then
            success_count = success_count + 1
        end
        reaper.Sleep(500) -- 短暂延迟
    end

    M.info("Test run completed. " .. success_count .. "/" .. #test_files .. " tests prepared.")
end

-- 手动测试函数
function M.test_track_create()
    M.run_test("track_create_test.json")
end

function M.test_track_delete()
    M.run_test("track_delete_test.json")
end

function M.test_media_insert()
    M.run_test("media_insert_test.json")
end

function M.test_project_info()
    M.run_test("project_get_info_test.json")
end

function M.test_error_handling()
    M.run_test("error_test_invalid_function.json")
end

-- 主测试菜单
function M.show_menu()
    -- 菜单文本（精简为提示信息）
    local menu_prompt = [[Orchestra Test Menu:
1. Test Track Create
2. Test Track Delete
3. Test Media Insert
4. Test Project Info
5. Test Error Handling
6. Run All Tests
7. Exit

请输入选择（1-7）：]]

    -- 弹出输入框，获取用户选择
    local user_ok, input_str = reaper.GetUserInputs(
        "Orchestra Test", -- 弹窗标题
        1,                -- 1个输入框
        menu_prompt,      -- 输入提示
        ""                -- 输入框默认值为空
    )

    -- 处理用户取消操作（点了Cancel）
    if not user_ok then
        M.info("操作已取消。")
        return
    end

    -- 将输入的字符串转为数字，并验证合法性
    local choice = tonumber(input_str) -- 字符串转数字（非数字返回nil）
    if not choice then
        reaper.ShowMessageBox("输入无效！请输入1-7之间的数字。", "错误", 0)
        M.show_menu() -- 重新显示菜单
        return
    end

    -- 验证数字范围
    if choice < 1 or choice > 7 then
        reaper.ShowMessageBox("输入超出范围！请输入1-7之间的数字。", "错误", 0)
        M.show_menu() -- 重新显示菜单
        return
    end

    -- 执行对应操作（保留原逻辑）
    if choice == 1 then
        M.test_track_create()
    elseif choice == 2 then
        M.test_track_delete()
    elseif choice == 3 then
        M.test_media_insert()
    elseif choice == 4 then
        M.test_project_info()
    elseif choice == 5 then
        M.test_error_handling()
    elseif choice == 6 then
        M.run_all_tests()
    elseif choice == 7 then
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
