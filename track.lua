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

return M
