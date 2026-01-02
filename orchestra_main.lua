-- Orchestra Main Client
-- 主客户端逻辑，使用改进的循环机制

local M = {}
local modules = nil
local is_running = false
local stop_requested = false

-- 引入配置模块
local config = require("config")

-- 初始化主客户端
function M.start(loaded_modules)
    modules = loaded_modules
    is_running = true

    M.log("Starting Orchestra Client...")

    -- 验证必需的模块
    local required_modules = { "file_manager", "json_manager", "track", "media", "project", "dispatcher" }
    for _, module_name in ipairs(required_modules) do
        if not modules[module_name] then
            M.log("ERROR: Required module " .. module_name .. " not loaded", "error")
            return false
        end
    end

    -- 初始化各个模块
    if modules.logger then
        modules.logger.init()
    end

    if modules.file_manager then
        modules.file_manager.init_directories()
    end

    -- 初始化需要logger的模块
    if modules.project and modules.logger then
        modules.project.init(modules.logger)
    end

    if modules.media and modules.logger then
        modules.media.init(modules.logger)
    end

    if modules.track and modules.logger then
        modules.track.init(modules.logger)
    end

    if modules.dispatcher then
        modules.dispatcher.init(modules)
    end

    M.log("All modules initialized successfully")

    -- 开始处理循环
    M.start_processing_loop()

    return true
end

function M.log(message, level)
    level = level or "info"
    if modules and modules.logger then
        if level == "error" then
            modules.logger.error(message)
        elseif level == "warn" then
            modules.logger.warn(message)
        elseif level == "debug" then
            modules.logger.debug(message)
        else
            modules.logger.info(message)
        end
    else
        reaper.ShowConsoleMsg("[" .. level:upper() .. "] " .. message .. "\n")
    end
end

-- 使用reaper.defer的改进循环
function M.start_processing_loop()
    M.log("Starting processing loop with defer")

    local function process_loop()
        -- 检查是否应该停止
        if M.should_stop() then
            M.log("Processing loop stopped by user request")
            is_running = false
            stop_requested = false
            return
        end

        if not is_running then
            M.log("Processing loop stopped")
            return
        end

        -- 处理请求
        M.process_pending_requests()

        -- 使用defer在下一次GUI更新时再次调用
        reaper.defer(process_loop)
    end

    -- 立即开始第一次处理
    process_loop()
end

-- 停止处理循环
function M.stop()
    M.log("Stopping Orchestra Client")
    stop_requested = true
end

-- 请求停止
function M.request_stop()
    M.log("Stop requested by user")
    stop_requested = true
end

-- 检查是否应该停止
function M.should_stop()
    -- 检查停止信号文件
    local stop_signal_file = config.get_stop_signal_file_path()
    local file = io.open(stop_signal_file, "r")
    if file then
        file:close()
        -- 删除停止信号文件
        os.remove(stop_signal_file)
        return true
    end

    return stop_requested
end

-- 处理待处理的请求
function M.process_pending_requests()
    if not modules or not modules.file_manager then
        return
    end

    local files = modules.file_manager.list_pending_requests()

    if #files == 0 then
        return -- 没有待处理的请求
    end

    local success, error_msg = pcall(function()
        M.log("Found " .. #files .. " pending requests")

        for _, filename in ipairs(files) do
            M.handle_single_request(filename)
        end
    end)

    if not success then
        M.log("Error in process_pending_requests: " .. tostring(error_msg), "error")
    end
end

-- 处理单个请求
function M.handle_single_request(filename)
    local file_manager = modules.file_manager
    local json_manager = modules.json_manager
    local dispatcher = modules.dispatcher

    -- 1. 认领请求
    local file_path, job_id = file_manager.claim_request(filename)
    if not file_path then
        M.log("Failed to claim request: " .. filename, "warn")
        return
    end

    M.log("Processing request: " .. job_id)

    -- 2. 读取请求内容
    local content, read_err = file_manager.read_request(file_path)
    if not content then
        M.log("Failed to read request: " .. read_err, "error")
        M.create_error_response(job_id, "FILE_READ_ERROR", read_err)
        -- file_manager.cleanup_request(job_id)
        return
    end

    -- 3. 解析JSON
    M.log("content: " .. content, "debug")
    local request_data, parse_err = json_manager.parse(content)
    M.log("request_data: " .. tostring(request_data), "debug")
    if not request_data then
        M.log("JSON parse error: " .. parse_err, "error")
        M.create_error_response(job_id, "JSON_PARSE_ERROR", parse_err, request_data)
        -- file_manager.cleanup_request(job_id)
        return
    end

    -- 4. 分派处理
    local response_data = dispatcher.dispatch(request_data, job_id)
    M.log("Response data prepared for job: " .. job_id, "debug")

    -- 5. 生成响应JSON
    local response_json = json_manager.stringify(response_data)
    M.log("Response JSON for job " .. job_id .. ": " .. response_json, "debug")
    M.log("gonna write reply for job: " .. job_id)

    -- 6. 写入回复
    local write_success = file_manager.write_reply(job_id, response_json)
    if not write_success then
        M.log("Failed to write reply for job: " .. job_id, "error")
    end

    -- 7. 清理
    -- file_manager.cleanup_request(job_id)
    M.log("Completed request: " .. job_id)
end

-- 创建错误响应
function M.create_error_response(job_id, error_code, error_message, original_request)
    local response = {
        meta = {
            version = (original_request and original_request.meta and original_request.meta.version) or "1",
            id = job_id,
            ts_ms = (original_request and original_request.meta and original_request.meta.ts_ms) or 0,
            agent_id = (original_request and original_request.meta and original_request.meta.agent_id) or "unknown"
        },
        request = (original_request and original_request.request) or {},
        response = {
            ok = false,
            result = nil,
            error = {
                code = error_code,
                message = error_message
            }
        }
    }

    local response_json = modules.json_manager.stringify(response)
    modules.file_manager.write_reply(job_id, response_json)
end

-- 手动触发一次处理（用于测试）
function M.trigger_processing()
    M.log("Manual trigger processing")
    M.process_pending_requests()
end

-- 获取状态信息
function M.get_status()
    return {
        running = is_running,
        modules_loaded = modules and true or false,
        available_modules = modules and modules.dispatcher and modules.dispatcher.get_available_modules() or {}
    }
end

return M
