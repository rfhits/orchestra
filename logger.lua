-- Logger Module
-- 统一的日志记录系统，支持按名称获取logger并包含文件和行号信息

local M = {}
local log_file = nil
local log_enabled = true

-- 引入配置模块
local config = require("config")

function M.init()
    local log_path = config.get_log_file_path()

    -- 确保目录存在
    config.init_directories()

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

-- 获取调用者的文件和行号信息
local function get_caller_info()
    local info = debug.getinfo(3, 'Sl') -- 3 levels up: log method -> logger method -> caller
    if info then
        local source = info.source or "unknown"
        local line = info.currentline or 0
        -- 移除@前缀（如果是文件）
        if source:sub(1, 1) == '@' then
            source = source:sub(2)
        end
        -- 只取文件名部分
        local filename = source:match("([^/\\]+)$") or source
        return filename, line
    end
    return "unknown", 0
end

function M.log(level, message, logger_name)
    if not log_enabled then
        return
    end

    local timestamp = M.get_timestamp()
    local source, line = get_caller_info()
    local level_with_name = logger_name and (logger_name .. " " .. level) or level
    local log_entry = string.format("[%s] [%s] %s:%d - %s\n", timestamp, level_with_name, source, line, message)

    -- 写入文件
    if log_file then
        log_file:write(log_entry)
        log_file:flush() -- 立即写入磁盘
    end

    -- 输出到控制台
    reaper.ShowConsoleMsg(log_entry)
end

-- 获取指定名称的logger
function M.get_logger(name)
    return {
        debug = function(message) M.log("DEBUG", message, name) end,
        info = function(message) M.log("INFO", message, name) end,
        warn = function(message) M.log("WARN", message, name) end,
        error = function(message) M.log("ERROR", message, name) end,
        log = function(level, message) M.log(level, message, name) end
    }
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
