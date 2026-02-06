-- Orchestra Stop Script
-- 用于停止Orchestra客户端的脚本

-- 获取当前运行的Orchestra实例并停止它
local _, filename = reaper.get_action_context()
local script_dir = filename:match("(.*[/\\])")

-- 设置包路径以便找到 config.lua
package.path = package.path .. ";" .. script_dir .. "?.lua"

-- 引入配置模块
local config = require("config")

-- 简单的停止方法：在orchestra目录中创建一个停止信号文件
local stop_signal_file = config.get_stop_signal_file_path()

-- 创建停止信号文件
local file = io.open(stop_signal_file, "w")
if file then
    file:write(tostring(os.time()) .. "\n")
    file:write("Orchestra stop requested at " .. os.date() .. "\n")
    file:close()
    reaper.ShowMessageBox("Orchestra stop signal created.\nThe running instance should stop shortly.", "Orchestra Stop", 0)
else
    reaper.ShowMessageBox("Failed to create stop signal file.", "Orchestra Stop Error", 0)
end
