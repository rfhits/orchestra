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

function M.set_parent_as(param)
    if not param then
        logger.error("参数不能为空")
        return false, { code = "INVALID_PARAM", message = "Param is nil" }
    end

    local parent_identifier = param.parent_track
    local child_identifier = param.child_track

    if parent_identifier == nil or parent_identifier == "" then
        logger.error("父轨道标识不能为空")
        return false, { code = "INVALID_PARAM", message = "Parent track identifier is empty" }
    end

    if child_identifier == nil or child_identifier == "" then
        logger.error("子轨道标识不能为空")
        return false, { code = "INVALID_PARAM", message = "Child track identifier is empty" }
    end

    local parent_track = M.find_track(parent_identifier)
    if not parent_track then
        logger.error("父轨道不存在: " .. tostring(parent_identifier))
        return false, { code = "NOT_FOUND", message = "Parent track not found: " .. tostring(parent_identifier) }
    end

    local child_track = M.find_track(child_identifier)
    if not child_track then
        logger.error("子轨道不存在: " .. tostring(child_identifier))
        return false, { code = "NOT_FOUND", message = "Child track not found: " .. tostring(child_identifier) }
    end

    if parent_track == child_track then
        logger.error("父轨道和子轨道不能相同")
        return false, { code = "INVALID_PARAM", message = "Parent and child tracks are the same" }
    end

    local parent_guid = reaper.GetTrackGUID(parent_track)
    local child_guid = reaper.GetTrackGUID(child_track)

    local current_parent = reaper.GetParentTrack(child_track)
    if current_parent and current_parent == parent_track then
        return true, {
            parent_track_guid = parent_guid,
            child_track_guid = child_guid,
            already_parent = true
        }
    end

    local parent_track_number = reaper.GetMediaTrackInfo_Value(parent_track, "IP_TRACKNUMBER")
    local child_track_number = reaper.GetMediaTrackInfo_Value(child_track, "IP_TRACKNUMBER")
    if not parent_track_number or parent_track_number <= 0 then
        logger.error("父轨道索引无效: " .. tostring(parent_track_number))
        return false, { code = "INTERNAL_ERROR", message = "Invalid parent track index" }
    end
    if not child_track_number or child_track_number <= 0 then
        logger.error("子轨道索引无效: " .. tostring(child_track_number))
        return false, { code = "INTERNAL_ERROR", message = "Invalid child track index" }
    end

    local parent_index = math.floor(parent_track_number) - 1
    local child_index = math.floor(child_track_number) - 1

    local before_index
    if child_index < parent_index then
        before_index = parent_index
    else
        before_index = parent_index + 1
    end

    local track_count = reaper.CountTracks(0)
    if before_index < 0 then before_index = 0 end
    if before_index > track_count then before_index = track_count end

    local parent_folder_depth = reaper.GetMediaTrackInfo_Value(parent_track, "I_FOLDERDEPTH")
    local make_prev_folder = 1
    if parent_folder_depth < 0 then
        make_prev_folder = 2
    end

    local selected_tracks = {}
    local selected_count = reaper.CountSelectedTracks(0)
    for i = 0, selected_count - 1 do
        selected_tracks[#selected_tracks + 1] = reaper.GetSelectedTrack(0, i)
    end

    reaper.Undo_BeginBlock()
    reaper.Main_OnCommand(40297, 0) -- Unselect all tracks
    reaper.SetOnlyTrackSelected(child_track)

    local moved_ok = reaper.ReorderSelectedTracks(before_index, make_prev_folder)
    reaper.UpdateArrange()
    reaper.Undo_EndBlock("Set Track Parent", -1)

    reaper.Main_OnCommand(40297, 0)
    for _, track in ipairs(selected_tracks) do
        if track then
            reaper.SetTrackSelected(track, true)
        end
    end

    if not moved_ok then
        logger.error("设置父子关系失败: ReorderSelectedTracks 返回 false")
        return false, { code = "INTERNAL_ERROR", message = "ReorderSelectedTracks failed" }
    end

    local new_parent = reaper.GetParentTrack(child_track)
    if not new_parent or new_parent ~= parent_track then
        logger.error("设置父子关系失败: 父轨道不匹配")
        return false, { code = "INTERNAL_ERROR", message = "Failed to set parent track" }
    end

    logger.info("设置父子轨道成功: 父 " .. parent_guid .. " -> 子 " .. child_guid)

    return true, {
        parent_track_guid = parent_guid,
        child_track_guid = child_guid,
        moved = true,
        already_parent = false,
        before_index = before_index,
        make_prev_folder = make_prev_folder
    }
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
    local clear = (params.clear == true)
    local rgb = params.color

    -- 1. 基础校验
    if track_index == nil or track_index < 0 then
        return false, { code = "INVALID_PARAM", message = "Invalid track index" }
    end

    -- 2. 获取轨道
    local track = reaper.GetTrack(0, track_index) -- 注意：这里直接用 API 即可，除非你有特殊的 M.find_track_by_index 逻辑
    if not track then
        return false, { code = "NOT_FOUND", message = "Track not found at index " .. tostring(track_index) }
    end

    local final_color_value = 0
    local native_color = nil
    if not clear then
        if type(rgb) ~= "table" or #rgb ~= 3 then
            return false, { code = "INVALID_PARAM", message = "Color must be [r, g, b] array, e.g. [255, 0, 0]" }
        end

        local r, g, b = rgb[1], rgb[2], rgb[3]
        native_color = reaper.ColorToNative(r, g, b)
        -- 需要显式打开自定义颜色位，否则只是存储，不会生效。
        final_color_value = native_color | 0x1000000
    end

    -- 4. 设置属性
    -- 注意：API 名字是 SetMediaTrackInfo_Value，没有 GetSet
    local is_ok = reaper.SetMediaTrackInfo_Value(track, "I_CUSTOMCOLOR", final_color_value)

    if not is_ok then
        return false, { code = "INTERNAL_ERROR", message = "Reaper refused to set color" }
    end

    if clear then
        return true, {
            track_index = track_index,
            has_custom_color = false,
            cleared = true
        }
    end

    return true, {
        track_index = track_index,
        color_rgb = rgb,
        native_value = native_color,
        has_custom_color = true
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

local function validate_track_index(track_index)
    if type(track_index) ~= "number" or track_index % 1 ~= 0 or track_index < 0 then
        return nil, { code = "INVALID_PARAM", message = "Invalid track index" }
    end

    local track = M.find_track_by_index(track_index)
    if not track then
        return nil, { code = "NOT_FOUND", message = "Track not found: " .. tostring(track_index) }
    end

    return track, nil
end

function M.set_mute(param)
    if not param then
        return false, { code = "INVALID_PARAM", message = "param is required" }
    end

    local track_index = param.index
    local track, track_err = validate_track_index(track_index)
    if not track then
        return false, track_err
    end

    local action = param.action or "set"
    if action ~= "set" and action ~= "toggle" then
        return false, { code = "INVALID_PARAM", message = "action must be 'set' or 'toggle'" }
    end

    local command = -1
    if action == "set" then
        if type(param.mute) ~= "boolean" then
            return false, { code = "INVALID_PARAM", message = "mute must be boolean when action is 'set'" }
        end
        command = param.mute and 1 or 0
    end

    reaper.Undo_BeginBlock()
    local new_state = reaper.SetTrackUIMute(track, command, 0)
    reaper.UpdateArrange()
    reaper.Undo_EndBlock("Set Track Mute", -1)

    if type(new_state) ~= "number" or new_state < 0 then
        return false, { code = "INTERNAL_ERROR", message = "SetTrackUIMute failed" }
    end

    local muted = (new_state > 0)
    return true, {
        track_index = track_index,
        muted = muted,
        action = action
    }
end

function M.get_mute(param)
    if not param then
        return false, { code = "INVALID_PARAM", message = "param is required" }
    end

    local track_index = param.index
    local track, track_err = validate_track_index(track_index)
    if not track then
        return false, track_err
    end

    local ok, muted = reaper.GetTrackUIMute(track)
    if not ok then
        return false, { code = "INTERNAL_ERROR", message = "GetTrackUIMute failed" }
    end

    return true, {
        track_index = track_index,
        muted = (muted == true)
    }
end

function M.set_solo(param)
    if not param then
        return false, { code = "INVALID_PARAM", message = "param is required" }
    end

    local track_index = param.index
    local track, track_err = validate_track_index(track_index)
    if not track then
        return false, track_err
    end

    local action = param.action or "set"
    if action ~= "set" and action ~= "toggle" then
        return false, { code = "INVALID_PARAM", message = "action must be 'set' or 'toggle'" }
    end

    local command = -1
    local mode = param.mode or "default"
    if action == "set" then
        if type(param.solo) ~= "boolean" then
            return false, { code = "INVALID_PARAM", message = "solo must be boolean when action is 'set'" }
        end

        if param.solo then
            if mode == "default" then
                command = 1
            elseif mode == "non_sip" then
                command = 2
            elseif mode == "sip" then
                command = 4
            else
                return false, { code = "INVALID_PARAM", message = "mode must be 'default', 'non_sip', or 'sip'" }
            end
        else
            command = 0
            mode = "off"
        end
    else
        mode = "toggle"
    end

    reaper.Undo_BeginBlock()
    local new_state = reaper.SetTrackUISolo(track, command, 0)
    reaper.UpdateArrange()
    reaper.Undo_EndBlock("Set Track Solo", -1)

    if type(new_state) ~= "number" or new_state < 0 then
        return false, { code = "INTERNAL_ERROR", message = "SetTrackUISolo failed" }
    end

    local solo_state = math.floor(new_state + 0.5)
    local soloed = (solo_state > 0)
    return true, {
        track_index = track_index,
        soloed = soloed,
        solo_state = solo_state,
        action = action,
        mode = mode
    }
end

function M.get_solo(param)
    if not param then
        return false, { code = "INVALID_PARAM", message = "param is required" }
    end

    local track_index = param.index
    local track, track_err = validate_track_index(track_index)
    if not track then
        return false, track_err
    end

    local solo_val = reaper.GetMediaTrackInfo_Value(track, "I_SOLO")
    if type(solo_val) ~= "number" then
        return false, { code = "INTERNAL_ERROR", message = "Failed to get track solo state" }
    end

    local solo_state = math.floor(solo_val + 0.5)
    return true, {
        track_index = track_index,
        soloed = (solo_state > 0),
        solo_state = solo_state
    }
end

return M
