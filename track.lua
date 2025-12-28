-- Track Module
-- Track相关操作封装

local M = {}

function M.info(message)
    reaper.ShowConsoleMsg("[Track] " .. message .. "\n")
end

function M.create(param)
    local track_name = param.name or "New Track"
    local track_index = param.index or -1

    M.info("Creating track: name=" .. track_name .. ", index=" .. track_index)

    -- 创建轨道
    reaper.InsertTrackAtIndex(track_index, true)

    -- 获取新创建的轨道
    local num_tracks = reaper.CountTracks(0)
    local track
    if track_index == -1 then
        -- 如果 index 为 -1，创建在最后
        track = reaper.GetTrack(0, num_tracks - 1)
    else
        track = reaper.GetTrack(0, track_index)
    end

    if not track then
        M.error("Failed to create track")
        return false, { code = "INTERNAL_ERROR", message = "Failed to create track" }
    end

    -- 设置轨道名称
    local _, set_name = reaper.GetSetMediaTrackInfo_Value(track, "P_NAME", track_name)
    if set_name then
        reaper.SetMediaTrackInfo_Value(track, "P_NAME", track_name)
    end

    -- 获取轨道 GUID
    local _, track_guid = reaper.GetSetMediaTrackInfo_Value(track, "P_GUID", "")

    M.info("Successfully created track: " .. track_name .. " (GUID: " .. track_guid .. ")")

    return true, {
        track_guid = track_guid,
        created = true,
        track_index = track_index,
        track_name = track_name
    }
end

function M.delete(track_guid)
    M.info("Deleting track: " .. track_guid)

    -- 通过GUID查找轨道
    local track = M.find_track_by_guid(track_guid)
    if not track then
        return false, { code = "NOT_FOUND", message = "Track not found: " .. track_guid }
    end

    -- 删除轨道
    reaper.DeleteTrack(track)
    M.info("Successfully deleted track: " .. track_guid)

    return true, { deleted = true }
end

function M.get_info(track_guid)
    M.info("Getting track info: " .. track_guid)

    local track = M.find_track_by_guid(track_guid)
    if not track then
        return false, { code = "NOT_FOUND", message = "Track not found: " .. track_guid }
    end

    local _, track_name = reaper.GetSetMediaTrackInfo_Value(track, "P_NAME", "")
    local _, track_guid_str = reaper.GetSetMediaTrackInfo_Value(track, "P_GUID", "")
    local track_index = reaper.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER")

    return true, {
        track_guid = track_guid_str,
        track_name = track_name,
        track_index = track_index
    }
end

function M.find_track_by_guid(track_guid)
    local num_tracks = reaper.CountTracks(0)
    for i = 0, num_tracks - 1 do
        local track = reaper.GetTrack(0, i)
        local _, guid = reaper.GetSetMediaTrackInfo_Value(track, "P_GUID", "")
        if guid == track_guid then
            return track
        end
    end
    return nil
end

function M.error(message)
    reaper.ShowConsoleMsg("[Track ERROR] " .. message .. "\n")
end

return M
