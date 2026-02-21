-- Marker Module
-- 项目 marker 的基础 CRUD 操作（仅 marker，不含 region）

local M = {}
local logger = nil

function M.init(log_module)
    logger = log_module.get_logger("Marker")
end

local function is_integer(value)
    return type(value) == "number" and value % 1 == 0
end

local function validate_marker_id(marker_id)
    if not is_integer(marker_id) or marker_id < 0 then
        return false, {
            code = "INVALID_PARAM",
            message = "marker_id must be a non-negative integer"
        }
    end
    return true, nil
end

local function collect_markers()
    local total = reaper.CountProjectMarkers(0)
    local markers = {}

    for idx = 0, total - 1 do
        local retval, isrgn, pos, _, name, markrgnindexnumber, color =
            reaper.EnumProjectMarkers3(0, idx)
        if retval == 0 then
            break
        end

        if not isrgn then
            table.insert(markers, {
                markrgnidx = idx,
                marker_id = markrgnindexnumber,
                time = pos,
                desc = name or "",
                color = color or 0
            })
        end
    end

    return markers
end

local function find_marker_by_id(marker_id)
    local markers = collect_markers()
    for _, marker in ipairs(markers) do
        if marker.marker_id == marker_id then
            return marker
        end
    end
    return nil
end

function M.create(param)
    if not param then
        return false, { code = "INVALID_PARAM", message = "param is required" }
    end

    local time = param.time
    if type(time) ~= "number" or time < 0 then
        return false, { code = "INVALID_PARAM", message = "time must be a non-negative number" }
    end

    local desc = param.desc
    if type(desc) ~= "string" then
        return false, { code = "INVALID_PARAM", message = "desc must be a string" }
    end

    reaper.Undo_BeginBlock()
    local marker_id = reaper.AddProjectMarker2(0, false, time, 0, desc, -1, 0)
    reaper.UpdateArrange()
    reaper.Undo_EndBlock("Create Marker", -1)

    if marker_id == -1 then
        logger.error(string.format("创建 marker 失败: time=%.3f, desc=%s", time, desc))
        return false, { code = "INTERNAL_ERROR", message = "Failed to create marker" }
    end

    logger.info(string.format("创建 marker 成功: id=%d, time=%.3f, desc=%s", marker_id, time, desc))

    return true, {
        marker_id = marker_id,
        time = time,
        desc = desc,
        created = true
    }
end

function M.list(_)
    local raw_markers = collect_markers()
    local markers = {}

    for _, marker in ipairs(raw_markers) do
        table.insert(markers, {
            marker_id = marker.marker_id,
            time = marker.time,
            desc = marker.desc
        })
    end

    return true, {
        markers = markers,
        count = #markers
    }
end

function M.update(param)
    if not param then
        return false, { code = "INVALID_PARAM", message = "param is required" }
    end

    local marker_id = param.marker_id
    local marker_id_ok, marker_err = validate_marker_id(marker_id)
    if not marker_id_ok then
        return false, marker_err
    end

    local desc = param.desc
    if type(desc) ~= "string" then
        return false, { code = "INVALID_PARAM", message = "desc must be a string" }
    end

    local marker = find_marker_by_id(marker_id)
    if not marker then
        return false, { code = "NOT_FOUND", message = "Marker not found: " .. tostring(marker_id) }
    end

    local flags = 0
    if desc == "" then
        flags = 1 -- clear name
    end

    reaper.Undo_BeginBlock()
    local ok = reaper.SetProjectMarkerByIndex2(
        0,
        marker.markrgnidx,
        false,
        marker.time,
        0,
        marker.marker_id,
        desc,
        marker.color,
        flags
    )
    reaper.UpdateArrange()
    reaper.Undo_EndBlock("Update Marker", -1)

    if not ok then
        logger.error(string.format("更新 marker 失败: id=%d", marker_id))
        return false, { code = "INTERNAL_ERROR", message = "Failed to update marker" }
    end

    logger.info(string.format("更新 marker 成功: id=%d, desc=%s", marker_id, desc))

    return true, {
        marker_id = marker_id,
        time = marker.time,
        desc = desc,
        updated = true
    }
end

function M.delete(param)
    if not param then
        return false, { code = "INVALID_PARAM", message = "param is required" }
    end

    local marker_id = param.marker_id
    local marker_id_ok, marker_err = validate_marker_id(marker_id)
    if not marker_id_ok then
        return false, marker_err
    end

    local marker = find_marker_by_id(marker_id)
    if not marker then
        return false, { code = "NOT_FOUND", message = "Marker not found: " .. tostring(marker_id) }
    end

    reaper.Undo_BeginBlock()
    local ok = reaper.DeleteProjectMarkerByIndex(0, marker.markrgnidx)
    reaper.UpdateArrange()
    reaper.Undo_EndBlock("Delete Marker", -1)

    if not ok then
        logger.error(string.format("删除 marker 失败: id=%d", marker_id))
        return false, { code = "INTERNAL_ERROR", message = "Failed to delete marker" }
    end

    logger.info(string.format("删除 marker 成功: id=%d", marker_id))

    return true, {
        marker_id = marker_id,
        deleted = true
    }
end

return M

