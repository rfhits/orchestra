-- JSON Manager Module
-- 简化的JSON处理，使用专业的json.lua库

local M = {}

-- 加载json.lua库
local json = require("json")

function M.info(message)
    reaper.ShowConsoleMsg("[JSONManager] " .. message .. "\n")
end

-- 解析JSON字符串
function M.parse(json_str)
    if not json_str or json_str == "" then
        return nil, "Empty JSON string"
    end
    
    local success, result = pcall(json.decode, json_str)
    if success then
        return result
    else
        return nil, "JSON decode failed: " .. tostring(result)
    end
end

-- 生成JSON字符串
function M.stringify(obj)
    local success, result = pcall(json.encode, obj)
    if success then
        return result
    else
        return nil, "JSON encode failed: " .. tostring(result)
    end
end

return M