-- verify_load.lua

-- 1. 正确获取当前脚本路径的方法
-- _, filename = reaper.get_action_context() 会返回当前运行脚本的完整路径
local _, filename = reaper.get_action_context()
local script_dir = filename:match("(.*[/\\])") -- 兼容 Windows(\) 和 Unix(/) 的路径匹配

-- 2. 动态注入 package.path
if script_dir then
    -- 注意：Windows 下路径可能包含反斜杠，Lua require 需要处理好路径字符串
    package.path = package.path .. ";" .. script_dir .. "?.lua"
    reaper.ShowConsoleMsg("Successfully added to path: " .. script_dir .. "\n")
else
    reaper.ShowConsoleMsg("Error: Could not determine script directory.\n")
end

-- 3. 再次尝试加载 test_lib.lua
local status, my_lib = pcall(require, "test_lib")

if status then
    local message = my_lib.hello()
    reaper.ShowConsoleMsg("RESULT: " .. message .. "\n")
else
    -- 如果还是失败，打印出具体的搜索路径方便排查
    reaper.ShowConsoleMsg("ERROR: " .. tostring(my_lib) .. "\n")
end