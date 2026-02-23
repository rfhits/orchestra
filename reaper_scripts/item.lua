-- Item Module
-- MediaItem creation and lookup helpers for take workflows.

local M = {}
local logger = nil
local track_module = nil
local time_map = require("time_map")

local EPS = 1e-6

function M.init(log_module)
    logger = log_module.get_logger("Item")
    track_module = require("track")
    time_map.init(log_module)
    logger.info("Item module initialized")
end

local function get_item_guid(item)
    local ok, guid = reaper.GetSetMediaItemInfo_String(item, "GUID", "", false)
    if not ok or not guid or guid == "" then
        return nil
    end
    return guid
end

local function get_take_guid(take)
    local ok, guid = reaper.GetSetMediaItemTakeInfo_String(take, "GUID", "", false)
    if not ok or not guid or guid == "" then
        return nil
    end
    return guid
end

local function get_track_info(track_obj)
    if not track_obj then
        return nil
    end

    local track_index = math.floor(reaper.GetMediaTrackInfo_Value(track_obj, "IP_TRACKNUMBER") or 0) - 1
    local _, track_name = reaper.GetSetMediaTrackInfo_String(track_obj, "P_NAME", "", false)
    if not track_name or track_name == "" then
        if track_index >= 0 then
            track_name = "Track " .. tostring(track_index + 1)
        else
            track_name = "Track"
        end
    end

    return {
        guid = reaper.GetTrackGUID(track_obj),
        name = track_name,
        index = track_index
    }
end

local function get_take_length_sec(take, item_pos)
    local src = reaper.GetMediaItemTake_Source(take)
    if not src then
        return 0
    end

    local length, lengthIsQN = reaper.GetMediaSourceLength(src)
    if lengthIsQN then
        local start_qn = reaper.TimeMap2_timeToQN(0, item_pos)
        local end_time = reaper.TimeMap2_QNToTime(0, start_qn + length)
        length = end_time - item_pos
    end
    return length
end

local function build_take_list(item)
    local takes = {}
    local item_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    local active_take = reaper.GetActiveTake(item)
    local take_count = reaper.CountTakes(item)

    for i = 0, take_count - 1 do
        local take = reaper.GetTake(item, i)
        if take then
            local _, take_name = reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", "", false)
            if not take_name then
                take_name = ""
            end
            table.insert(takes, {
                index = i,
                guid = get_take_guid(take),
                name = take_name,
                is_active = (take == active_take),
                is_midi = reaper.TakeIsMIDI(take),
                length = get_take_length_sec(take, item_pos)
            })
        end
    end

    return takes
end

local function build_item_summary(item, include_takes)
    local position_sec = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    local length_sec = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
    local end_sec = position_sec + length_sec

    local position_measure = time_map.second_to_measure(position_sec)
    local end_measure = time_map.second_to_measure(end_sec)

    local track_obj = reaper.GetMediaItem_Track(item)
    local track_info = get_track_info(track_obj)
    local active_take = reaper.GetActiveTake(item)

    local summary = {
        item_guid = get_item_guid(item),
        position_sec = position_sec,
        end_sec = end_sec,
        length_sec = length_sec,
        position_measure = position_measure,
        end_measure = end_measure,
        length_measure = end_measure - position_measure,
        track_guid = track_info and track_info.guid or nil,
        track_name = track_info and track_info.name or nil,
        track_index = track_info and track_info.index or nil,
        take_count = reaper.CountTakes(item),
        active_take_guid = active_take and get_take_guid(active_take) or nil,
        is_midi = active_take and reaper.TakeIsMIDI(active_take) or false
    }

    if include_takes then
        summary.takes = build_take_list(item)
    end

    return summary
end

local function find_item_by_guid(item_guid)
    if not item_guid or item_guid == "" then
        return nil
    end
    local num_items = reaper.CountMediaItems(0)
    for i = 0, num_items - 1 do
        local item = reaper.GetMediaItem(0, i)
        local ok, guid = reaper.GetSetMediaItemInfo_String(item, "GUID", "", false)
        if ok and guid == item_guid then
            return item
        end
    end
    return nil
end

local function find_item_on_track_at_second(track_obj, second, match_mode)
    if not track_obj then
        return nil
    end

    local item_count = reaper.GetTrackNumMediaItems(track_obj)
    local best_exact = nil
    local best_cover = nil
    local best_delta = nil

    for i = 0, item_count - 1 do
        local item = reaper.GetTrackMediaItem(track_obj, i)
        if item then
            local start_sec = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
            local length_sec = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
            local end_sec = start_sec + math.max(length_sec, 0)

            if math.abs(start_sec - second) <= EPS then
                best_exact = item
            end

            if second >= start_sec and second < end_sec then
                local delta = second - start_sec
                if not best_cover or (best_delta and delta < best_delta) or (not best_delta) then
                    best_cover = item
                    best_delta = delta
                end
            end
        end
    end

    if match_mode == "exact_start" then
        return best_exact
    end

    if match_mode == "always_new" then
        return nil
    end

    return best_cover
end

local function create_item_at_second(track_obj, second, length)
    local item = reaper.AddMediaItemToTrack(track_obj)
    if not item then
        return nil, "Failed to create media item"
    end

    reaper.SetMediaItemInfo_Value(item, "D_POSITION", second)
    reaper.SetMediaItemInfo_Value(item, "D_LENGTH", length)
    reaper.SetMediaItemInfo_Value(item, "B_LOOPSRC", 0)

    local guid = get_item_guid(item)
    return item, guid
end

local function is_match_mode_valid(match_mode)
    return match_mode == "cover" or match_mode == "cover_or_create" or match_mode == "exact_start" or
        match_mode == "always_new"
end

local function is_finite_number(value)
    return type(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end

local function capture_selected_items()
    local selected = {}
    local selected_count = reaper.CountSelectedMediaItems(0)
    for i = 0, selected_count - 1 do
        local item = reaper.GetSelectedMediaItem(0, i)
        if item then
            table.insert(selected, item)
        end
    end
    return selected
end

local function restore_selected_items(selected_items)
    reaper.Main_OnCommand(40289, 0) -- Item: Unselect all items
    for _, item in ipairs(selected_items or {}) do
        if reaper.ValidatePtr(item, "MediaItem*") then
            reaper.SetMediaItemSelected(item, true)
        end
    end
end

function M._find_item_by_guid(item_guid)
    return find_item_by_guid(item_guid)
end

function M._find_item_on_track_at_second(track_obj, second, match_mode)
    return find_item_on_track_at_second(track_obj, second, match_mode or "cover")
end

function M._create_item_at_second(track_obj, second, length)
    return create_item_at_second(track_obj, second, length)
end

function M.create_at_second(param)
    if not param or not param.track then
        return false, { code = "INVALID_PARAM", message = "track is required" }
    end

    local second = param.second
    if type(second) ~= "number" or second < 0 then
        return false, { code = "INVALID_PARAM", message = "second must be >= 0" }
    end

    local length = param.length
    if type(length) ~= "number" or length <= 0 then
        return false, { code = "INVALID_PARAM", message = "length must be > 0" }
    end

    local track_obj = track_module.find_track(param.track)
    if not track_obj then
        return false, { code = "NOT_FOUND", message = "Track not found: " .. tostring(param.track) }
    end

    reaper.Undo_BeginBlock()
    local item, guid_or_err = create_item_at_second(track_obj, second, length)
    reaper.UpdateArrange()
    reaper.Undo_EndBlock("Create Media Item", -1)

    if not item then
        return false, { code = "INTERNAL_ERROR", message = guid_or_err or "Failed to create item" }
    end

    return true, {
        item_guid = guid_or_err,
        item_length = length,
        item_position = second
    }
end

function M.create_at_measure(param)
    if not param or not param.track then
        return false, { code = "INVALID_PARAM", message = "track is required" }
    end

    local measure = param.measure
    if type(measure) ~= "number" or measure < 1 then
        return false, { code = "INVALID_PARAM", message = "measure must be >= 1" }
    end

    local second = time_map.measure_to_second(measure)
    return M.create_at_second({
        track = param.track,
        second = second,
        length = param.length
    })
end

function M.list_by_track(param)
    if not param or param.track == nil or param.track == "" then
        return false, { code = "INVALID_PARAM", message = "track is required" }
    end

    local begin_second = param.begin_second
    if begin_second == nil then
        begin_second = param.begin
    end

    local end_second = param.end_second
    if end_second == nil then
        end_second = param["end"]
    end

    if begin_second ~= nil and (type(begin_second) ~= "number" or begin_second < 0) then
        return false, { code = "INVALID_PARAM", message = "begin_second must be >= 0" }
    end
    if end_second ~= nil and (type(end_second) ~= "number" or end_second < 0) then
        return false, { code = "INVALID_PARAM", message = "end_second must be >= 0" }
    end
    if begin_second ~= nil and end_second ~= nil and end_second < begin_second then
        return false, { code = "INVALID_PARAM", message = "end_second must be >= begin_second" }
    end

    local include_takes = (param.include_takes == true)
    local track_obj = track_module.find_track(param.track)
    if not track_obj then
        return false, { code = "NOT_FOUND", message = "Track not found: " .. tostring(param.track) }
    end

    local items = {}
    local item_count = reaper.GetTrackNumMediaItems(track_obj)
    for i = 0, item_count - 1 do
        local item = reaper.GetTrackMediaItem(track_obj, i)
        if item then
            local summary = build_item_summary(item, include_takes)
            local intersects = true
            if begin_second ~= nil and summary.end_sec <= begin_second then
                intersects = false
            end
            if end_second ~= nil and summary.position_sec >= end_second then
                intersects = false
            end
            if intersects then
                table.insert(items, summary)
            end
        end
    end

    table.sort(items, function(a, b)
        return a.position_sec < b.position_sec
    end)

    return true, {
        track = get_track_info(track_obj),
        items = items,
        count = #items
    }
end

function M.find_at_second(param)
    if not param or param.track == nil or param.track == "" then
        return false, { code = "INVALID_PARAM", message = "track is required" }
    end

    local second = param.second
    if type(second) ~= "number" or second < 0 then
        return false, { code = "INVALID_PARAM", message = "second must be >= 0" }
    end

    local match_mode = param.match_mode or "cover"
    if not is_match_mode_valid(match_mode) then
        return false, { code = "INVALID_PARAM", message = "match_mode must be one of: cover, exact_start, cover_or_create, always_new" }
    end

    local include_takes = (param.include_takes == true)
    local track_obj = track_module.find_track(param.track)
    if not track_obj then
        return false, { code = "NOT_FOUND", message = "Track not found: " .. tostring(param.track) }
    end

    local item = find_item_on_track_at_second(track_obj, second, match_mode)
    if not item then
        return true, {
            found = false,
            track = get_track_info(track_obj),
            second = second
        }
    end

    return true, {
        found = true,
        track = get_track_info(track_obj),
        second = second,
        item = build_item_summary(item, include_takes)
    }
end

function M.find_at_measure(param)
    if not param or param.track == nil or param.track == "" then
        return false, { code = "INVALID_PARAM", message = "track is required" }
    end

    local measure = param.measure
    if type(measure) ~= "number" or measure < 1 then
        return false, { code = "INVALID_PARAM", message = "measure must be >= 1" }
    end

    local next_param = {}
    for k, v in pairs(param) do
        next_param[k] = v
    end
    next_param.second = time_map.measure_to_second(measure)

    local ok, result = M.find_at_second(next_param)
    if not ok then
        return false, result
    end
    result.measure = measure
    return true, result
end

function M.find_by_guid(param)
    if not param or not param.item_guid then
        return false, { code = "INVALID_PARAM", message = "item_guid is required" }
    end

    local item = find_item_by_guid(param.item_guid)
    if not item then
        return false, { code = "NOT_FOUND", message = "Item not found: " .. tostring(param.item_guid) }
    end

    local summary = build_item_summary(item, false)

    return true, {
        item_guid = param.item_guid,
        item_position = summary.position_sec,
        item_length = summary.length_sec,
        item_end = summary.end_sec,
        item_position_measure = summary.position_measure,
        item_length_measure = summary.length_measure,
        item_end_measure = summary.end_measure,
        track_guid = summary.track_guid,
        track_name = summary.track_name,
        track_index = summary.track_index,
        take_count = summary.take_count,
        active_take_guid = summary.active_take_guid,
        is_midi = summary.is_midi
    }
end

function M.set_length(param)
    if not param or not param.item_guid then
        return false, { code = "INVALID_PARAM", message = "item_guid is required" }
    end

    local length = param.length
    if type(length) ~= "number" or length <= 0 then
        return false, { code = "INVALID_PARAM", message = "length must be > 0" }
    end

    local item = find_item_by_guid(param.item_guid)
    if not item then
        return false, { code = "NOT_FOUND", message = "Item not found: " .. tostring(param.item_guid) }
    end

    reaper.Undo_BeginBlock()
    reaper.SetMediaItemInfo_Value(item, "D_LENGTH", length)
    reaper.UpdateArrange()
    reaper.Undo_EndBlock("Set Media Item Length", -1)

    return true, { item_guid = param.item_guid, item_length = length }
end

local function parse_rgb(color)
    if type(color) ~= "table" or #color ~= 3 then
        return nil, "color must be [r, g, b] array"
    end

    local rgb = {}
    for i = 1, 3 do
        local v = color[i]
        if type(v) ~= "number" or v % 1 ~= 0 or v < 0 or v > 255 then
            return nil, "color values must be integers in range 0..255"
        end
        rgb[i] = v
    end

    return rgb, nil
end

function M.set_color(param)
    if not param or not param.item_guid then
        return false, { code = "INVALID_PARAM", message = "item_guid is required" }
    end

    local item = find_item_by_guid(param.item_guid)
    if not item then
        return false, { code = "NOT_FOUND", message = "Item not found: " .. tostring(param.item_guid) }
    end

    local clear = (param.clear == true)
    local color_value = 0
    local rgb = nil

    if not clear then
        local err
        rgb, err = parse_rgb(param.color)
        if not rgb then
            return false, { code = "INVALID_PARAM", message = err }
        end
        color_value = reaper.ColorToNative(rgb[1], rgb[2], rgb[3]) | 0x1000000
    end

    reaper.Undo_BeginBlock()
    local ok = reaper.SetMediaItemInfo_Value(item, "I_CUSTOMCOLOR", color_value)
    reaper.UpdateArrange()
    reaper.Undo_EndBlock("Set Media Item Color", -1)

    if not ok then
        return false, { code = "INTERNAL_ERROR", message = "Failed to set item color" }
    end

    if clear then
        return true, {
            item_guid = param.item_guid,
            has_custom_color = false,
            rgb = nil,
            hex = nil
        }
    end

    return true, {
        item_guid = param.item_guid,
        has_custom_color = true,
        rgb = { rgb[1], rgb[2], rgb[3] },
        hex = string.format("#%02X%02X%02X", rgb[1], rgb[2], rgb[3])
    }
end

function M.get_color(param)
    if not param or not param.item_guid then
        return false, { code = "INVALID_PARAM", message = "item_guid is required" }
    end

    local item = find_item_by_guid(param.item_guid)
    if not item then
        return false, { code = "NOT_FOUND", message = "Item not found: " .. tostring(param.item_guid) }
    end

    local raw_color = reaper.GetMediaItemInfo_Value(item, "I_CUSTOMCOLOR")
    if type(raw_color) ~= "number" then
        return false, { code = "INTERNAL_ERROR", message = "Failed to get item color" }
    end

    local raw_int = math.floor(raw_color + 0.5)
    if raw_int == 0 or (raw_int & 0x1000000 == 0) then
        return true, {
            item_guid = param.item_guid,
            has_custom_color = false,
            rgb = nil,
            hex = nil
        }
    end

    local native_color = raw_int & 0xFFFFFF
    local r, g, b = reaper.ColorFromNative(native_color)
    return true, {
        item_guid = param.item_guid,
        has_custom_color = true,
        rgb = { r, g, b },
        hex = string.format("#%02X%02X%02X", r, g, b)
    }
end

function M.split(param)
    if not param or not param.item_guid then
        return false, { code = "INVALID_PARAM", message = "item_guid is required" }
    end

    if type(param.item_guid) ~= "string" or param.item_guid == "" then
        return false, { code = "INVALID_PARAM", message = "item_guid must be a non-empty string" }
    end

    local times = param.times
    if type(times) ~= "table" or #times == 0 then
        return false, { code = "INVALID_PARAM", message = "times must be a non-empty array" }
    end

    local item = find_item_by_guid(param.item_guid)
    if not item then
        return false, { code = "NOT_FOUND", message = "Item not found: " .. tostring(param.item_guid) }
    end

    local start_sec = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    local length_sec = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
    local end_sec = start_sec + length_sec

    local split_times = {}
    local prev = nil
    for i, t in ipairs(times) do
        if not is_finite_number(t) then
            return false, { code = "INVALID_PARAM", message = "times[" .. tostring(i) .. "] must be a finite number" }
        end
        if t <= start_sec + EPS or t >= end_sec - EPS then
            return false, {
                code = "INVALID_PARAM",
                message = "times[" .. tostring(i) .. "] must be strictly inside item range"
            }
        end
        if prev and t <= prev + EPS then
            return false, { code = "INVALID_PARAM", message = "times must be strictly increasing" }
        end
        table.insert(split_times, t)
        prev = t
    end

    reaper.Undo_BeginBlock()
    local segments = {}
    local current = item
    local split_err = nil

    for _, t in ipairs(split_times) do
        local right_item = reaper.SplitMediaItem(current, t)
        if not right_item then
            split_err = "Failed to split item at " .. tostring(t)
            break
        end
        table.insert(segments, current)
        current = right_item
    end

    if not split_err and current then
        table.insert(segments, current)
    end

    reaper.UpdateArrange()
    reaper.Undo_EndBlock("Split Media Item", -1)

    if split_err then
        return false, { code = "INTERNAL_ERROR", message = split_err }
    end

    local result_items = {}
    for _, seg in ipairs(segments) do
        if not reaper.ValidatePtr(seg, "MediaItem*") then
            return false, { code = "INTERNAL_ERROR", message = "Split produced invalid media item" }
        end
        table.insert(result_items, build_item_summary(seg, false))
    end

    table.sort(result_items, function(a, b)
        return a.position_sec < b.position_sec
    end)

    return true, {
        source_item_guid = param.item_guid,
        split_times = split_times,
        items = result_items,
        count = #result_items
    }
end

function M.merge(param)
    if not param or type(param.item_guids) ~= "table" then
        return false, { code = "INVALID_PARAM", message = "item_guids is required" }
    end

    if #param.item_guids < 2 then
        return false, { code = "INVALID_PARAM", message = "item_guids must contain at least 2 GUIDs" }
    end

    local seen = {}
    local entries = {}
    local track_obj = nil

    for i, item_guid in ipairs(param.item_guids) do
        if type(item_guid) ~= "string" or item_guid == "" then
            return false, { code = "INVALID_PARAM", message = "item_guids[" .. tostring(i) .. "] must be a non-empty string" }
        end
        if seen[item_guid] then
            return false, { code = "INVALID_PARAM", message = "Duplicate item GUID: " .. item_guid }
        end
        seen[item_guid] = true

        local item = find_item_by_guid(item_guid)
        if not item then
            return false, { code = "NOT_FOUND", message = "Item not found: " .. item_guid }
        end

        local item_track = reaper.GetMediaItem_Track(item)
        if not track_obj then
            track_obj = item_track
        elseif item_track ~= track_obj then
            return false, { code = "INVALID_PARAM", message = "All items must be on the same track" }
        end

        local start_sec = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        local length_sec = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")

        table.insert(entries, {
            guid = item_guid,
            item = item,
            start_sec = start_sec,
            end_sec = start_sec + length_sec
        })
    end

    table.sort(entries, function(a, b)
        if math.abs(a.start_sec - b.start_sec) <= EPS then
            return a.end_sec < b.end_sec
        end
        return a.start_sec < b.start_sec
    end)

    local merged_end = entries[1].end_sec
    for i = 2, #entries do
        local next_entry = entries[i]
        if next_entry.start_sec > merged_end + EPS then
            return false, {
                code = "INVALID_PARAM",
                message = "Items must be contiguous or overlapping to merge"
            }
        end
        if next_entry.end_sec > merged_end then
            merged_end = next_entry.end_sec
        end
    end

    local selected_before = capture_selected_items()
    local merge_ok = true
    local merge_err = nil
    local merged_item = nil

    reaper.Undo_BeginBlock()
    reaper.Main_OnCommand(40289, 0) -- Item: Unselect all items
    for _, entry in ipairs(entries) do
        if reaper.ValidatePtr(entry.item, "MediaItem*") then
            reaper.SetMediaItemSelected(entry.item, true)
        else
            merge_ok = false
            merge_err = "Invalid item pointer before merge"
            break
        end
    end

    if merge_ok then
        reaper.Main_OnCommand(41588, 0) -- Item: Glue items
        local selected_count = reaper.CountSelectedMediaItems(0)
        if selected_count ~= 1 then
            merge_ok = false
            merge_err = "Glue operation did not produce exactly one item"
        else
            merged_item = reaper.GetSelectedMediaItem(0, 0)
            if not merged_item or not reaper.ValidatePtr(merged_item, "MediaItem*") then
                merge_ok = false
                merge_err = "Merged item is invalid"
            end
        end
    end

    reaper.UpdateArrange()
    reaper.Undo_EndBlock("Merge Media Items", -1)
    restore_selected_items(selected_before)

    if not merge_ok then
        return false, { code = "INTERNAL_ERROR", message = merge_err or "Failed to merge items" }
    end

    local source_item_guids = {}
    for _, entry in ipairs(entries) do
        table.insert(source_item_guids, entry.guid)
    end

    return true, {
        source_item_guids = source_item_guids,
        merged_item = build_item_summary(merged_item, false),
        merged = true
    }
end

function M.delete(param)
    if not param or not param.item_guid then
        return false, { code = "INVALID_PARAM", message = "item_guid is required" }
    end

    if type(param.item_guid) ~= "string" or param.item_guid == "" then
        return false, { code = "INVALID_PARAM", message = "item_guid must be a non-empty string" }
    end

    local item = find_item_by_guid(param.item_guid)
    if not item then
        return false, { code = "NOT_FOUND", message = "Item not found: " .. tostring(param.item_guid) }
    end

    local track_obj = reaper.GetMediaItem_Track(item)
    if not track_obj then
        return false, { code = "INTERNAL_ERROR", message = "Failed to locate item track" }
    end

    reaper.Undo_BeginBlock()
    local ok = reaper.DeleteTrackMediaItem(track_obj, item)
    reaper.UpdateArrange()
    reaper.Undo_EndBlock("Delete Media Item", -1)

    if not ok then
        return false, { code = "INTERNAL_ERROR", message = "Failed to delete item" }
    end

    return true, {
        item_guid = param.item_guid,
        deleted = true
    }
end

return M
