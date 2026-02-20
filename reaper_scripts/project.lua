-- Project Module
-- Project相关操作封装

local M = {}
local logger = nil
local time_map = require("time_map")

function M.init(log_module)
    logger = log_module.get_logger("Project")
    time_map.init(log_module)
end

local function get_track_info(track)
    if not track then
        return nil
    end

    local track_index = math.floor(reaper.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER") or 0) - 1
    local _, track_name = reaper.GetSetMediaTrackInfo_String(track, "P_NAME", "", false)
    if track_name == "" then
        track_name = "Track " .. tostring(track_index + 1)
    end

    return {
        track_guid = reaper.GetTrackGUID(track),
        track_name = track_name,
        track_index = track_index
    }
end

local function get_take_info(item)
    local active_take = reaper.GetActiveTake(item)
    if not active_take then
        return {
            take_guid = nil,
            take_name = "",
            is_midi = false
        }
    end

    local _, take_guid = reaper.GetSetMediaItemTakeInfo_String(active_take, "GUID", "", false)
    local _, take_name = reaper.GetSetMediaItemTakeInfo_String(active_take, "P_NAME", "", false)
    if not take_name then
        take_name = ""
    end

    return {
        take_guid = take_guid,
        take_name = take_name,
        is_midi = reaper.TakeIsMIDI(active_take)
    }
end

local function get_cursor_context_name(context_code)
    if context_code == 0 then
        return "track"
    elseif context_code == 1 then
        return "item"
    elseif context_code == 2 then
        return "envelope"
    end
    return "unknown"
end

local function build_selected_item_info(item, selected_index)
    local _, item_guid = reaper.GetSetMediaItemInfo_String(item, "GUID", "", false)
    local position_sec = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    local length_sec = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
    local end_sec = position_sec + length_sec
    local position_measure = time_map.second_to_measure(position_sec)
    local end_measure = time_map.second_to_measure(end_sec)

    local track = reaper.GetMediaItem_Track(item)
    local track_info = get_track_info(track)
    local take_info = get_take_info(item)

    return {
        selected_index = selected_index,
        item_guid = item_guid,
        position_sec = position_sec,
        end_sec = end_sec,
        length_sec = length_sec,
        position_measure = position_measure,
        end_measure = end_measure,
        length_measure = end_measure - position_measure,
        track = track_info,
        active_take = take_info,
        take_count = reaper.CountTakes(item)
    }
end

function M.get_info(permit)
    logger.info("Getting project info")

    local project_name = reaper.GetProjectName(0, "")
    local project_path = reaper.GetProjectPath(0, "")
    local num_tracks = reaper.CountTracks(0)
    local num_items = reaper.CountMediaItems(0)

    return true, {
        project_name = project_name,
        project_path = project_path,
        num_tracks = num_tracks,
        num_items = num_items
    }
end

function M.get_track_count()
    logger.info("Getting track count")

    local num_tracks = reaper.CountTracks(0)
    logger.info("Track count: " .. num_tracks)

    return true, {
        count = num_tracks
    }
end

function M.get_track_list()
    logger.info("Getting track list")

    local num_tracks = reaper.CountTracks(0)
    local track_list = {}

    for i = 0, num_tracks - 1 do
        local track = reaper.GetTrack(0, i)
        if track then
            -- 1. 获取字符串属性 (返回 boolean, string)
            local _, track_name = reaper.GetSetMediaTrackInfo_String(track, "P_NAME", "", false)
            if track_name == "" then
                track_name = "Track " .. (i + 1)
            end

            local _, track_guid = reaper.GetSetMediaTrackInfo_String(track, "GUID", "", false)

            -- 2. 获取数值属性 (注意：只返回一个 number 值)
            local raw_color     = reaper.GetMediaTrackInfo_Value(track, "I_CUSTOMCOLOR")
            local mute_val      = reaper.GetMediaTrackInfo_Value(track, "B_MUTE")
            local solo_val      = reaper.GetMediaTrackInfo_Value(track, "I_SOLO") -- 正确名称是 I_SOLO
            local arm_val       = reaper.GetMediaTrackInfo_Value(track, "I_RECARM")
            local vol_val       = reaper.GetMediaTrackInfo_Value(track, "D_VOL")

            -- 3. 颜色解析逻辑
            local rgb           = nil
            if raw_color ~= 0 and (raw_color & 0x1000000 ~= 0) then
                local r, g, b = reaper.ColorFromNative(raw_color & 0xFFFFFF)
                rgb = { r, g, b }
            end

            -- 4. 插入列表 (注意索引从 1 开始)
            table.insert(track_list, {
                track_index = i,
                track_name = track_name,
                track_guid = track_guid,
                color = rgb,                -- 返回 {r,g,b} 数组，AI 更易读
                is_muted = (mute_val == 1),
                is_soloed = (solo_val > 0), -- Solo 有多种模式(1, 2, 5, 6)，>0 统一视为已 Solo
                is_armed = (arm_val == 1),
                volume_gain = vol_val       -- 显式标注这是 gain
            })
        end
    end

    logger.info("Track list retrieved: " .. #track_list .. " tracks")
    return true, {
        tracks = track_list,
        count = #track_list
    }
end

function M.get_selection_info(_)
    logger.info("Getting selection info")

    local cursor_context = reaper.GetCursorContext2(true)
    local edit_cursor_sec = reaper.GetCursorPosition()
    local ts_start_sec, ts_end_sec = reaper.GetSet_LoopTimeRange2(0, false, false, 0, 0, false)
    local ts_length_sec = ts_end_sec - ts_start_sec
    if ts_length_sec < 0 then
        ts_length_sec = 0
    end

    local selected_items = {}
    local selected_item_count = reaper.CountSelectedMediaItems(0)
    for i = 0, selected_item_count - 1 do
        local item = reaper.GetSelectedMediaItem(0, i)
        if item then
            table.insert(selected_items, build_selected_item_info(item, i))
        end
    end

    local selected_tracks = {}
    local selected_track_count = reaper.CountSelectedTracks(0)
    for i = 0, selected_track_count - 1 do
        local track = reaper.GetSelectedTrack(0, i)
        if track then
            local track_info = get_track_info(track)
            if track_info then
                track_info.selected_index = i
                table.insert(selected_tracks, track_info)
            end
        end
    end

    return true, {
        selection = {
            context = {
                cursor_context = cursor_context,
                cursor_context_name = get_cursor_context_name(cursor_context),
                edit_cursor_sec = edit_cursor_sec,
                time_selection = {
                    start_sec = ts_start_sec,
                    end_sec = ts_end_sec,
                    length_sec = ts_length_sec
                }
            },
            items = selected_items,
            tracks = selected_tracks,
            item_count = #selected_items,
            track_count = #selected_tracks
        }
    }
end

--[[
    设置指定秒数的速度/拍号标记
    注意：REAPER 通过 Tempo/TimeSig marker 来定义项目的速度与拍号
--]]
function M.set_tempo_timesig_at_second(param)
    if not param then
        logger.error("参数为空")
        return false, {
            code = "INVALID_PARAM",
            message = "param is required"
        }
    end

    local sec = param.sec
    if sec == nil then
        sec = param.second -- 兼容 second 字段
    end

    if type(sec) ~= "number" or sec < 0 then
        logger.error(string.format("秒数无效: %s", tostring(sec)))
        return false, {
            code = "INVALID_PARAM",
            message = "sec must be a non-negative number"
        }
    end

    local bpm = param.bpm
    if type(bpm) ~= "number" or bpm <= 0 then
        logger.error(string.format("BPM 无效: %s", tostring(bpm)))
        return false, {
            code = "INVALID_PARAM",
            message = "bpm must be a positive number"
        }
    end

    local ts_num = param.ts_num
    local ts_den = param.ts_den
    if ts_num == nil or ts_den == nil then
        logger.error("时间签名参数缺失")
        return false, {
            code = "INVALID_PARAM",
            message = "ts_num and ts_den are required"
        }
    end

    if type(ts_num) ~= "number" or ts_num <= 0 or ts_num % 1 ~= 0 then
        logger.error(string.format("时间签名分子无效: %s", tostring(ts_num)))
        return false, {
            code = "INVALID_PARAM",
            message = "ts_num must be a positive integer"
        }
    end

    if type(ts_den) ~= "number" or ts_den <= 0 or ts_den % 1 ~= 0 then
        logger.error(string.format("时间签名分母无效: %s", tostring(ts_den)))
        return false, {
            code = "INVALID_PARAM",
            message = "ts_den must be a positive integer"
        }
    end

    -- 查找指定时间点是否已有 marker（Find 返回该时间点或之前的 marker）
    local existing_idx = reaper.FindTempoTimeSigMarker(0, sec)
    local target_idx = -1
    if existing_idx >= 0 then
        local retval, timepos = reaper.GetTempoTimeSigMarker(0, existing_idx)
        if retval and math.abs(timepos - sec) < 1e-6 then
            target_idx = existing_idx -- 编辑已有 marker
        end
    end

    reaper.Undo_BeginBlock()
    local ok = reaper.SetTempoTimeSigMarker(0, target_idx, sec, -1, -1, bpm, ts_num, ts_den, false)
    reaper.UpdateArrange()
    reaper.Undo_EndBlock("Set Tempo/TimeSig Marker", -1)

    if not ok then
        logger.error(string.format("设置 Tempo/TimeSig 失败: sec=%.3f, bpm=%.2f, ts=%d/%d",
            sec, bpm, ts_num, ts_den))
        return false, {
            code = "INTERNAL_ERROR",
            message = "Failed to set tempo/time signature marker"
        }
    end

    if target_idx >= 0 then
        logger.info(string.format("更新 Tempo/TimeSig marker: idx=%d, sec=%.3f, bpm=%.2f, ts=%d/%d",
            target_idx, sec, bpm, ts_num, ts_den))
    else
        logger.info(string.format("插入 Tempo/TimeSig marker: sec=%.3f, bpm=%.2f, ts=%d/%d",
            sec, bpm, ts_num, ts_den))
    end

    return true, {
        success = true,
        second = sec,
        bpm = bpm,
        ts_num = ts_num,
        ts_den = ts_den
    }
end

--[[
    设置项目默认拍号/速度（等价于在 0 秒处设置 Tempo/TimeSig marker）
--]]
function M.set_project_timesig(param)
    if not param then
        logger.error("参数为空")
        return false, {
            code = "INVALID_PARAM",
            message = "param is required"
        }
    end

    -- 复用 set_tempo_timesig_at_second 逻辑，固定 sec=0
    param.sec = 0
    return M.set_tempo_timesig_at_second(param)
end

return M
