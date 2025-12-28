-- Logger Module
-- 统一的日志记录系统

local M = {}
local log_file = nil
local log_enabled = true

function M.init()
    local orchestra_dir = reaper.GetResourcePath() .. "/.orchestra"
    local log_path = orchestra_dir .. "/orchestra.log"

    -- 确保目录存在
    reaper.RecursiveCreateDirectory(orchestra_dir)

    -- 打开日志文件
    log_file = io.open(log_path, "a")
    if not log_file then
        log_enabled = false
        reaper.ShowConsoleMsg("WARNING: Cannot open log file: " .. log_path .. "\n")
        return
    end

    M.info("Logger initialized")
end

function M.get_timestamp()
    return os.date("%Y-%m-%d %H:%M:%S")
end

function M.log(level, message)
    if not log_enabled then
        return
    end

    local timestamp = M.get_timestamp()
    local log_entry = string.format("[%s] [%s] %s\n", timestamp, level, message)

    -- 写入文件
    if log_file then
        log_file:write(log_entry)
        log_file:flush() -- 立即写入磁盘
    end

    -- 输出到控制台
    reaper.ShowConsoleMsg(log_entry)
end

function M.debug(message)
    M.log("DEBUG", message)
end

function M.info(message)
    M.log("INFO", message)
end

function M.warn(message)
    M.log("WARN", message)
end

function M.error(message)
    M.log("ERROR", message)
end

function M.close()
    if log_file then
        log_file:close()
        log_file = nil
    end
end

return M
