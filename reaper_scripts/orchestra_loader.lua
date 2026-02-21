-- Orchestra Module Loader
-- 动态加载和管理所有Orchestra模块

local MODULES_DIR = nil

-- 初始化模块路径
local function init_module_paths()
    local _, filename = reaper.get_action_context()
    if not filename then
        reaper.ShowMessageBox("Cannot determine script path", "Orchestra Error", 0)
        return false
    end

    MODULES_DIR = filename:match("(.*[/\\])")
    if not MODULES_DIR then
        reaper.ShowMessageBox("Cannot determine module directory", "Orchestra Error", 0)
        return false
    end

    -- 添加模块搜索路径
    package.path = package.path .. ";" .. MODULES_DIR .. "orchestra_?.lua"
    package.path = package.path .. ";" .. MODULES_DIR .. "?.lua"

    reaper.ShowConsoleMsg("Orchestra modules loaded from: " .. MODULES_DIR .. "\n")
    return true
end

-- 安全加载模块
local function safe_require(module_name)
    local status, result = pcall(require, module_name)
    if not status then
        reaper.ShowConsoleMsg("ERROR loading " .. module_name .. ": " .. tostring(result) .. "\n")
        return nil
    end
    return result
end

-- 加载所有Orchestra模块
local function load_orchestra_modules()
    if not init_module_paths() then
        return false
    end

    -- 加载核心模块
    local modules = {
        "file_manager",
        "json_manager",
        "logger",
        "config",
        "time_map",
        "item",
        "take",
        "marker",
        "track",
        "project",
        "audio",
        "midi",
        "dispatcher"
    }

    local loaded_modules = {}

    for _, module_name in ipairs(modules) do
        local module = safe_require(module_name)
        if module then
            loaded_modules[module_name] = module
            reaper.ShowConsoleMsg("Loaded module: " .. module_name .. "\n")
        else
            reaper.ShowConsoleMsg("Failed to load module: " .. module_name .. "\n")
        end
    end

    return loaded_modules
end

-- 启动Orchestra客户端
local function start_orchestra_client()
    local modules = load_orchestra_modules()
    if not modules then
        reaper.ShowMessageBox("Failed to load Orchestra modules", "Orchestra Error", 0)
        return
    end

    -- 检查关键模块是否加载成功
    local required_modules = { "file_manager", "json_manager", "track", "project", "dispatcher" }
    for _, module_name in ipairs(required_modules) do
        if not modules[module_name] then
            reaper.ShowMessageBox("Required module " .. module_name .. " failed to load", "Orchestra Error", 0)
            return
        end
    end

    -- 初始化日志
    if modules.logger then
        modules.logger.init()
    end

    -- 初始化时间映射模块（依赖 logger）
    if modules.time_map then
        modules.time_map.init(modules.logger)
    end

    -- 初始化文件系统
    if modules.file_manager then
        modules.file_manager.init_directories()
    end

    -- 加载主客户端逻辑
    local status, main_client = pcall(require, "orchestra_main")
    if status and main_client then
        main_client.start(modules)
    else
        reaper.ShowMessageBox("Failed to start Orchestra main client", "Orchestra Error", 0)
    end
end

-- 启动Orchestra
start_orchestra_client()
