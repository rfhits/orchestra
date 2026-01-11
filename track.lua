-- Track Module
-- Track相关操作封装

local M = {}
local logger = nil

function M.init(log_module)
    logger = log_module.get_logger("Track")
end

function M.create(param)
    -- 提取参数并兜底
    local track_name = param.name or ""
    local track_index = param.index or -1 -- 默认-1（插入到最后）

    -- 1. 校验入参
    if track_name == nil or track_name == "" then
        logger.error("轨道名称不能为空")
        return false, { code = "INVALID_PARAM", message = "Track name is empty" }
    end

    -- 2. 处理track_index=-1：转为“最后位置”的索引
    local current_track_count = reaper.CountTracks(0) -- 0=当前项目，获取现有轨道总数
    if track_index == -1 then
        track_index = current_track_count             -- 总数=最后一个位置的下一个索引
    end

    -- 3. 插入轨道（注意：该函数无返回值，不能用返回值判断成功）
    reaper.InsertTrackAtIndex(track_index, true)
    -- 关键：插入后刷新界面，确保轨道数据同步
    reaper.UpdateArrange()

    -- 4. 校验轨道是否真的创建成功（替代返回值判断）
    local new_track_count = reaper.CountTracks(0)
    if new_track_count <= current_track_count then
        logger.error("插入轨道失败，索引：" .. tostring(track_index))
        return false, { code = "INTERNAL_ERROR", message = "Failed to insert track" }
    end

    -- 5. 获取新创建的轨道对象
    local track
    -- 插入到最后时，索引是new_track_count - 1；否则是track_index
    if param.index == -1 then
        track = reaper.GetTrack(0, new_track_count - 1)
    else
        track = reaper.GetTrack(0, track_index)
    end

    if not track then
        M.error("获取轨道对象失败，索引：" .. tostring(track_index))
        return false, { code = "INTERNAL_ERROR", message = "Failed to get track object" }
    end

    -- 6. 设置轨道名称（正确接收GetSetMediaTrackInfo_String的两个返回值）
    local name_ok, _ = reaper.GetSetMediaTrackInfo_String(track, "P_NAME", track_name, true)
    if not name_ok then
        logger.warn("设置轨道名称失败：" .. track_name)
    end

    -- 7. 获取轨道GUID（正确接收两个返回值）
    local guid_ok, track_guid = reaper.GetSetMediaTrackInfo_String(track, "GUID", "", false)
    if not guid_ok or track_guid == "" then
        track_guid = "UNKNOWN_GUID"
        logger.error("获取轨道GUID失败")
    end

    -- 8. 日志输出
    logger.info("轨道创建成功：" .. track_name .. " (索引：" .. track_index .. ", GUID：" .. track_guid .. ")")

    return true, {
        track_guid = track_guid,
        created = true,
        track_index = track_index,
        track_name = track_name
    }
end

function M.delete(permit)
    local track_guid = permit.track_guid
    logger.info("Deleting track: " .. track_guid)

    -- 通过GUID查找轨道
    local track = M.find_track_by_guid(track_guid)
    if not track then
        return false, { code = "NOT_FOUND", message = "Track not found: " .. track_guid }
    end

    -- 删除轨道
    reaper.DeleteTrack(track)
    logger.info("Successfully deleted track: " .. track_guid)

    return true, { deleted = true }
end

function M.get_info(permit)
    local track_guid = permit.track_guid
    logger.info("Getting track info: " .. track_guid)

    local track = M.find_track_by_guid(track_guid)
    if not track then
        return false, { code = "NOT_FOUND", message = "Track not found: " .. track_guid }
    end

    local _, track_name = reaper.GetSetMediaTrackInfo_Value(track, "P_NAME", "")
    local _, track_guid_str = reaper.GetSetMediaTrackInfo_Value(track, "P_GUID", "")
    local track_index = reaper.GetSetMediaTrackInfo_Value(track, "IP_TRACKNUMBER", 0)

    return true, {
        track_guid = track_guid_str,
        track_name = track_name,
        track_index = track_index
    }
end

function M.find_track_by_guid(track_guid)
    if not track_guid or track_guid == "" then return nil end
    local num_tracks = reaper.CountTracks(0)
    for i = 0, num_tracks - 1 do
        local track = reaper.GetTrack(0, i)
        local guid = reaper.GetTrackGUID(track) -- 使用更高效的专用 API
        if guid == track_guid then
            return track
        end
    end
    return nil
end

function M.find_track_by_index(track_index)
    local num_tracks = reaper.CountTracks(0)
    if track_index < 0 or track_index >= num_tracks then
        return nil
    end
    return reaper.GetTrack(0, track_index)
end

function M.find_track_by_name(track_name)
    local num_tracks = reaper.CountTracks(0)
    for i = 0, num_tracks - 1 do
        local track = reaper.GetTrack(0, i)
        local _, name = reaper.GetSetMediaTrackInfo_String(track, "P_NAME", "", false)
        if name == track_name then
            return track
        end
    end
    return nil
end

--- 统一查找轨道函数
-- @param track_identifier string|number 轨道标识符，可以是 GUID、名称或索引
-- @return MediaTrack|nil 找到的轨道对象
function M.find_track(track_identifier)
    if type(track_identifier) == "number" then
        return M.find_track_by_index(track_identifier)
    elseif type(track_identifier) == "string" then
        -- 优先匹配 GUID 格式 {GUID...}
        if track_identifier:match("^{.-}$") then
            return M.find_track_by_guid(track_identifier)
        end

        local track = M.find_track_by_name(track_identifier)
        if track then return track end

        local track_index = tonumber(track_identifier)
        if track_index then return M.find_track_by_index(track_index) end
    end
    return nil
end

function M.rename(param)
    local track_index = param.index
    local new_name = param.name or ""

    -- 1. 校验入参
    if track_index == nil or track_index < 0 then
        logger.error("轨道索引无效：" .. tostring(track_index))
        return false, { code = "INVALID_PARAM", message = "Invalid track index" }
    end

    if new_name == "" then
        logger.error("新轨道名称不能为空")
        return false, { code = "INVALID_PARAM", message = "Track name is empty" }
    end

    -- 2. 获取轨道对象
    local track = M.find_track_by_index(track_index)
    if not track then
        logger.error("轨道不存在，索引：" .. tostring(track_index))
        return false, { code = "NOT_FOUND", message = "Track not found: " .. tostring(track_index) }
    end

    -- 3. 设置轨道名称
    local name_ok, _ = reaper.GetSetMediaTrackInfo_String(track, "P_NAME", new_name, true)
    if not name_ok then
        logger.error("重命名轨道失败：" .. new_name)
        return false, { code = "INTERNAL_ERROR", message = "Failed to rename track" }
    end

    logger.info("轨道重命名成功：" .. "索引" .. track_index .. " -> " .. new_name)
    return true, {
        track_index = track_index,
        track_name = new_name,
        renamed = true
    }
end

function M.set_color(params)
    local track_index = params.index
    -- 建议协议约定：color 是一个包含 {r, g, b} 的表，或者 hex 字符串
    -- 这里演示最通用的 {r, g, b} 方式，例如：[255, 0, 0]
    local rgb = params.color

    -- 1. 基础校验
    if track_index == nil or track_index < 0 then
        return false, { code = "INVALID_PARAM", message = "Invalid track index" }
    end

    if type(rgb) ~= "table" or #rgb ~= 3 then
        return false, { code = "INVALID_PARAM", message = "Color must be [r, g, b] array, e.g. [255, 0, 0]" }
    end

    -- 2. 获取轨道
    local track = reaper.GetTrack(0, track_index) -- 注意：这里直接用 API 即可，除非你有特殊的 M.find_track_by_index 逻辑
    if not track then
        return false, { code = "NOT_FOUND", message = "Track not found at index " .. tostring(track_index) }
    end

    -- 3. 颜色转换核心逻辑 (Critical Logic)
    local r, g, b = rgb[1], rgb[2], rgb[3]

    -- A. 将 RGB 转换为系统原生颜色值 (解决 OS Dependent 问题)
    local native_color = reaper.ColorToNative(r, g, b)

    -- B. 加上“自定义颜色启用”标志 (解决 0x1000000 问题)
    -- Lua 5.3+ 支持 | 运算符。Reaper 内置 Lua 肯定支持。
    local final_color_value = native_color | 0x1000000

    -- 4. 设置属性
    -- 注意：API 名字是 SetMediaTrackInfo_Value，没有 GetSet
    local is_ok = reaper.SetMediaTrackInfo_Value(track, "I_CUSTOMCOLOR", final_color_value)

    if not is_ok then
        return false, { code = "INTERNAL_ERROR", message = "Reaper refused to set color" }
    end

    return true, {
        track_index = track_index,
        color_rgb = rgb,
        native_value = native_color
    }
end

function M.get_color(params)
    local track_index = params.index

    -- 1. 校验入参
    if track_index == nil or track_index < 0 then
        return false, { code = "INVALID_PARAM", message = "Invalid track index" }
    end

    -- 2. 获取轨道对象
    local track = reaper.GetTrack(0, track_index)
    if not track then
        return false, { code = "NOT_FOUND", message = "Track not found" }
    end

    -- 3. 获取原生颜色值
    -- 注意：使用 GetMediaTrackInfo_Value
    local raw_color = reaper.GetMediaTrackInfo_Value(track, "I_CUSTOMCOLOR")

    -- 4. 逻辑判断：是否设置了自定义颜色
    -- 如果位标志 0x1000000 为 0，说明轨道使用的是默认主题色
    if raw_color == 0 or (raw_color & 0x1000000 == 0) then
        return true, {
            track_index = track_index,
            has_custom_color = false,
            rgb = { 200, 200, 200 } -- 返回一个中性的默认提示色，或者 null
        }
    end

    -- 5. 剥离标志位并转换回 RGB
    -- 去掉 0x1000000 标志
    local native_color = raw_color & 0xFFFFFF
    -- 转换回 R, G, B (处理了不同系统的字节序差异)
    local r, g, b = reaper.ColorFromNative(native_color)

    logger.info(string.format("获取轨道颜色成功: Index %d, RGB(%d,%d,%d)", track_index, r, g, b))

    return true, {
        track_index = track_index,
        has_custom_color = true,
        rgb = { r, g, b },
        hex = string.format("#%02X%02X%02X", r, g, b) -- 顺便返回 Hex，方便 Python 处理
    }
end

return M
