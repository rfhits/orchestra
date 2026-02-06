-- Orchestra Configuration Module
-- 集中管理所有路径配置和公共设置

local M = {}
-- 【核心函数】跨平台获取用户主目录（修正运算符优先级问题）
local function get_user_home_dir()
    local home_dir
    local is_windows = package.config:sub(1,1) == "\\"

    if is_windows then
        -- 1. 优先取最标准的 USERPROFILE（C:\Users\用户名）
        home_dir = os.getenv("USERPROFILE")
        
        -- 2. 兜底逻辑：先计算 "\\Users\\" .. (用户名 or 空)，必须加括号！
        if not home_dir then
            -- 第一步：单独计算用户目录的核心部分（加括号保证优先级）
            local user_dir = "\\Users\\" .. (os.getenv("USERNAME") or "")
            -- 第二步：拼接 HOMEDRIVE（默认C:）
            local home_drive = os.getenv("HOMEDRIVE") or "C:"
            home_dir = home_drive .. user_dir
        end

        -- 3. 最终兜底：APPDATA
        if not home_dir or home_dir == "C:\\Users\\" then  -- 避免空用户名导致的无效路径
            home_dir = os.getenv("APPDATA")
        end
    else
        -- macOS/Linux：优先取 HOME
        home_dir = os.getenv("HOME")
    end

    -- 终极兜底：当前工作目录
    if not home_dir or home_dir == "" then
        home_dir = os.getcwd()
        reaper.ShowConsoleMsg("[WARN] 获取用户目录失败，使用当前目录：" .. home_dir .. "\n")
    end

    return home_dir
end


-- 获取 REAPER 资源路径
local function get_reaper_resource_path()
    local user_home = get_user_home_dir()
    -- return reaper.GetResourcePath()
    return user_home
end

-- Orchestra 根目录
function M.get_orchestra_dir()
    return get_reaper_resource_path() .. "/.orchestra"
end

-- Inbox 目录（接收请求）
function M.get_inbox_dir()
    return M.get_orchestra_dir() .. "/inbox"
end

-- Outbox 目录（发送回复）
function M.get_outbox_dir()
    return M.get_orchestra_dir() .. "/outbox"
end

-- Archive 目录（归档文件）
function M.get_archive_dir()
    return M.get_orchestra_dir() .. "/archive"
end

-- Log 文件路径
function M.get_log_file_path()
    return M.get_orchestra_dir() .. "/orchestra.log"
end

-- 停止信号文件路径
function M.get_stop_signal_file_path()
    return M.get_orchestra_dir() .. "/STOP_REQUEST"
end

-- 获取所有目录配置
function M.get_directories()
    return {
        orchestra = M.get_orchestra_dir(),
        inbox = M.get_inbox_dir(),
        outbox = M.get_outbox_dir(),
        archive = M.get_archive_dir()
    }
end

-- 获取所有文件路径配置
function M.get_file_paths()
    return {
        log_file = M.get_log_file_path(),
        stop_signal = M.get_stop_signal_file_path()
    }
end

-- 初始化所有目录（创建不存在的目录）
function M.init_directories()
    local dirs = M.get_directories()
    for _, dir_path in pairs(dirs) do
        reaper.RecursiveCreateDirectory(dir_path, 0)
    end
end

return M
