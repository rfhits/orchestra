-- Project Module
-- Project相关操作封装

local M = {}
local logger = nil

function M.init(log_module)
    logger = log_module.get_logger("Project")
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

return M
