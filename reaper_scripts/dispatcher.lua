-- Dispatcher Module
-- 简化的动态函数分派系统

local M = {}
local loaded_modules = {}

function M.info(message)
    reaper.ShowConsoleMsg("[Dispatcher] " .. message .. "\n")
end

-- 初始化分派器
function M.init(modules)
    loaded_modules = modules
    M.info("Dispatcher initialized with dynamic dispatch")
end

-- 分派请求到对应的模块和函数
function M.dispatch(request_data, job_id)
    local func_name = request_data.request and request_data.request.func
    local param = request_data.request and request_data.request.param or {}

    if not func_name then
        return M.create_error_response("MISSING_FUNCTION", "Request missing 'func' field", job_id)
    end

    M.info("Dispatching request: " .. func_name)

    -- 按"."分割函数名：模块名.函数名
    local module_name, method_name = func_name:match("^([^.]+)%.([^.]+)$")

    if not module_name or not method_name then
        return M.create_error_response("INVALID_FUNCTION_FORMAT",
            "Function name must be in format 'module.function': " .. func_name, job_id)
    end

    M.info("Looking for module: " .. module_name .. ", method: " .. method_name)

    -- 查找并加载模块
    local module = loaded_modules[module_name]
    if not module then
        return M.create_error_response("MODULE_NOT_FOUND",
            "Module not found: " .. module_name, job_id)
    end

    -- 检查模块是否有这个方法
    local method = module[method_name]
    if not method then
        return M.create_error_response("METHOD_NOT_FOUND",
            "Method not found in module " .. module_name .. ": " .. method_name, job_id)
    end

    -- 调用方法
    M.info("parameters: " .. tostring(param))
    local success, method_ok, response_data = pcall(method, param)

    if not success then
        M.error("Method call failed for " .. func_name .. ": " .. tostring(method_ok))
        return M.create_error_response("METHOD_CALL_ERROR",
            "Method call failed: " .. tostring(method_ok), job_id)
    end

    -- 处理返回结果（method_ok 是方法返回的第一个值，response_data 是第二个值）
    M.info("Method call succeeded for " .. func_name)

    if method_ok then
        return M.create_success_response(response_data, job_id, request_data)
    else
        return M.create_error_response(response_data.code or "METHOD_ERROR",
            response_data.message or "Unknown method error", job_id, request_data)
    end
end

-- 创建成功响应
function M.create_success_response(result, job_id, request_data)
    return {
        meta = {
            version = (request_data and request_data.meta and request_data.meta.version) or "1",
            id = job_id,
            ts_ms = (request_data and request_data.meta and request_data.meta.ts_ms) or 0,
            agent_id = (request_data and request_data.meta and request_data.meta.agent_id) or "unknown"
        },
        request = request_data and request_data.request or {},
        response = {
            ok = true,
            result = result,
            error = nil
        }
    }
end

-- 创建错误响应
function M.create_error_response(code, message, job_id, request_data)
    return {
        meta = {
            version = (request_data and request_data.meta and request_data.meta.version) or "1",
            id = job_id,
            ts_ms = (request_data and request_data.meta and request_data.meta.ts_ms) or 0,
            agent_id = (request_data and request_data.meta and request_data.meta.agent_id) or "unknown"
        },
        request = request_data and request_data.request or {},
        response = {
            ok = false,
            result = nil,
            error = {
                code = code,
                message = message
            }
        }
    }
end

function M.error(message)
    reaper.ShowConsoleMsg("[Dispatcher ERROR] " .. message .. "\n")
end

-- 获取可用的模块列表
function M.get_available_modules()
    local modules = {}
    for name, _ in pairs(loaded_modules) do
        table.insert(modules, name)
    end
    return modules
end

return M
