-- Take Module
-- Add/list/activate takes for MediaItems.

local M = {}
local logger = nil
local track_module = nil
local time_map = require("time_map")
local item_module = nil

function M.init(log_module)
    logger = log_module.get_logger("Take")
    track_module = require("track")
    item_module = require("item")
    time_map.init(log_module)
    logger.info("Take module initialized")
end

local function file_exists(path)
    local f = io.open(path, "rb")
    if not f then
        return false
    end
    f:close()
    return true
end

local function validate_files(files)
    for _, path in ipairs(files) do
        if not file_exists(path) then
            return false, path
        end
    end
    return true, nil
end

local function get_take_guid(take)
    local ok, guid = reaper.GetSetMediaItemTakeInfo_String(take, "GUID", "", false)
    if not ok or not guid or guid == "" then
        return nil
    end
    return guid
end

local function get_item_guid(item)
    local ok, guid = reaper.GetSetMediaItemInfo_String(item, "GUID", "", false)
    if not ok or not guid or guid == "" then
        return nil
    end
    return guid
end

local function normalize_item_match_mode(mode)
    if mode == nil or mode == "" then
        return "cover_or_create"
    end
    if mode == "cover_or_create" or mode == "exact_start" or mode == "always_new" then
        return mode
    end
    return nil
end

local function set_take_name(take, name)
    if not name or name == "" then
        return
    end
    local ok, _ = reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", name, true)
    if not ok then
        logger.warn("Failed to set take name: " .. tostring(name))
    end
end

local function get_take_source_path(take)
    local src = reaper.GetMediaItemTake_Source(take)
    if not src then
        return ""
    end
    local ok, path = reaper.GetMediaSourceFileName(src, "")
    if ok and path then
        return path
    end
    return ""
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

local function apply_take_source(take, file_path, item_pos)
    local pcm_src = reaper.PCM_Source_CreateFromFile(file_path)
    if not pcm_src then
        return false, { code = "FILE_READ_ERROR", message = "Failed to load file: " .. tostring(file_path) }
    end

    reaper.SetMediaItemTake_Source(take, pcm_src)

    local length, lengthIsQN = reaper.GetMediaSourceLength(pcm_src)
    if lengthIsQN then
        local start_qn = reaper.TimeMap2_timeToQN(0, item_pos)
        local end_time = reaper.TimeMap2_QNToTime(0, start_qn + length)
        length = end_time - item_pos
    end
    return true, length
end

local function build_take_info(item, take, index)
    local item_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    local ok, name = reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", "", false)
    if not ok then
        name = ""
    end

    local active_take = reaper.GetActiveTake(item)
    local is_active = (active_take == take)

    return {
        index = index,
        guid = get_take_guid(take),
        name = name,
        is_active = is_active,
        is_midi = reaper.TakeIsMIDI(take),
        length = get_take_length_sec(take, item_pos),
        source_path = get_take_source_path(take)
    }
end

local function ensure_item_for_add(param)
    local item = nil
    local item_guid = nil
    local item_pos = nil

    if param.item_guid then
        item = item_module._find_item_by_guid(param.item_guid)
        if not item then
            return nil, nil, nil, { code = "NOT_FOUND", message = "Item not found: " .. tostring(param.item_guid) }
        end
        item_guid = param.item_guid
        item_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        return item, item_guid, item_pos, nil, true
    end

    if not param.track then
        return nil, nil, nil, { code = "INVALID_PARAM", message = "track is required when item_guid is not provided" }, nil
    end

    local second = param.second
    if type(second) ~= "number" or second < 0 then
        return nil, nil, nil, { code = "INVALID_PARAM", message = "second must be >= 0" }, nil
    end

    local track_obj = track_module.find_track(param.track)
    if not track_obj then
        return nil, nil, nil, { code = "NOT_FOUND", message = "Track not found: " .. tostring(param.track) }, nil
    end

    local item_match_mode = normalize_item_match_mode(param.item_match_mode)
    if not item_match_mode then
        return nil, nil, nil, {
            code = "INVALID_PARAM",
            message = "item_match_mode must be one of: cover_or_create, exact_start, always_new"
        }, nil
    end

    if item_match_mode ~= "always_new" then
        local lookup_mode = (item_match_mode == "cover_or_create") and "cover" or "exact_start"
        local existing_item = item_module._find_item_on_track_at_second(track_obj, second, lookup_mode)
        if existing_item then
            local existing_guid = get_item_guid(existing_item)
            local existing_pos = reaper.GetMediaItemInfo_Value(existing_item, "D_POSITION")
            logger.info("Reusing existing item for add_at_second: " .. tostring(existing_guid))
            return existing_item, existing_guid, existing_pos, nil, true
        end
    end

    local create_len = param.length
    if type(create_len) ~= "number" or create_len <= 0 then
        create_len = 1
    end

    local new_item, new_guid = item_module._create_item_at_second(track_obj, second, create_len)
    if not new_item then
        return nil, nil, nil, { code = "INTERNAL_ERROR", message = "Failed to create item" }, nil
    end

    return new_item, new_guid, second, nil, false
end

local function add_takes_to_item(item, item_pos, files, names)
    local takes = {}
    local max_len = 0
    local first_new_index = nil

    for i, file_path in ipairs(files) do
        local take = reaper.AddTakeToMediaItem(item)
        if not take then
            return nil, 0, nil, { code = "INTERNAL_ERROR", message = "Failed to create take" }
        end

        local ok, length_or_err = apply_take_source(take, file_path, item_pos)
        if not ok then
            return nil, 0, nil, length_or_err
        end

        local take_index = reaper.CountTakes(item) - 1
        if first_new_index == nil then
            first_new_index = take_index
        end

        if names and names[i] then
            set_take_name(take, names[i])
        end

        local info = build_take_info(item, take, take_index)
        info.length = length_or_err
        info.source_path = get_take_source_path(take)

        if length_or_err > max_len then
            max_len = length_or_err
        end

        table.insert(takes, info)
    end

    return takes, max_len, first_new_index, nil
end

function M.add_at_second(param)
    if not param or type(param.files) ~= "table" or #param.files == 0 then
        return false, { code = "INVALID_PARAM", message = "files must be a non-empty array" }
    end

    local ok, bad_path = validate_files(param.files)
    if not ok then
        return false, { code = "FILE_NOT_FOUND", message = "File not found: " .. tostring(bad_path) }
    end

    reaper.Undo_BeginBlock()

    local item, item_guid, item_pos, err, reused_item = ensure_item_for_add(param)
    if err then
        reaper.Undo_EndBlock("Add Takes (failed)", -1)
        return false, err
    end

    reaper.SetMediaItemInfo_Value(item, "B_LOOPSRC", 0)

    local names = nil
    if type(param.names) == "table" then
        names = param.names
    end

    local takes, max_len, first_new_index, add_err = add_takes_to_item(item, item_pos, param.files, names)
    if add_err then
        reaper.Undo_EndBlock("Add Takes (failed)", -1)
        return false, add_err
    end

    local current_len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
    local target_len = current_len
    if max_len > target_len then
        target_len = max_len
    end
    if type(param.length) == "number" and param.length > target_len then
        target_len = param.length
    end
    reaper.SetMediaItemInfo_Value(item, "D_LENGTH", target_len)

    local active_index = nil
    if type(param.set_active) == "number" and param.set_active >= 0 then
        active_index = param.set_active
    else
        active_index = first_new_index
    end

    local active_take_guid = nil
    if active_index ~= nil then
        local active_take = reaper.GetTake(item, active_index)
        if active_take then
            reaper.SetActiveTake(active_take)
            active_take_guid = get_take_guid(active_take)
        end
    end

    reaper.UpdateArrange()
    reaper.Undo_EndBlock("Add Takes", -1)

    return true, {
        item_guid = item_guid,
        takes = takes,
        active_take_guid = active_take_guid,
        item_length = target_len,
        reused_item = (reused_item == true)
    }
end

function M.add_at_measure(param)
    if not param then
        return false, { code = "INVALID_PARAM", message = "param is required" }
    end

    local measure = param.measure
    if type(measure) ~= "number" or measure < 1 then
        return false, { code = "INVALID_PARAM", message = "measure must be >= 1" }
    end

    local second = time_map.measure_to_second(measure)
    local next_param = {}
    for k, v in pairs(param) do
        next_param[k] = v
    end
    next_param.second = second

    return M.add_at_second(next_param)
end

function M.list(param)
    if not param or not param.item_guid then
        return false, { code = "INVALID_PARAM", message = "item_guid is required" }
    end

    local item = item_module._find_item_by_guid(param.item_guid)
    if not item then
        return false, { code = "NOT_FOUND", message = "Item not found: " .. tostring(param.item_guid) }
    end

    local takes = {}
    local count = reaper.CountTakes(item)
    for i = 0, count - 1 do
        local take = reaper.GetTake(item, i)
        if take then
            table.insert(takes, build_take_info(item, take, i))
        end
    end

    local active_take = reaper.GetActiveTake(item)
    local active_take_guid = active_take and get_take_guid(active_take) or nil

    return true, {
        item_guid = param.item_guid,
        takes = takes,
        active_take_guid = active_take_guid,
        count = #takes
    }
end

function M.set_active(param)
    if not param or not param.item_guid then
        return false, { code = "INVALID_PARAM", message = "item_guid is required" }
    end

    local item = item_module._find_item_by_guid(param.item_guid)
    if not item then
        return false, { code = "NOT_FOUND", message = "Item not found: " .. tostring(param.item_guid) }
    end

    local take = nil
    if param.take_guid then
        take = reaper.GetMediaItemTakeByGUID(0, param.take_guid)
        if not take then
            return false, { code = "NOT_FOUND", message = "Take not found: " .. tostring(param.take_guid) }
        end
        local take_item = reaper.GetMediaItemTake_Item(take)
        if take_item ~= item then
            return false, { code = "INVALID_PARAM", message = "Take does not belong to the item" }
        end
    elseif type(param.take_index) == "number" then
        if param.take_index < 0 then
            return false, { code = "INVALID_PARAM", message = "take_index must be >= 0" }
        end
        take = reaper.GetTake(item, param.take_index)
        if not take then
            return false, { code = "NOT_FOUND", message = "Take index out of range: " .. tostring(param.take_index) }
        end
    else
        return false, { code = "INVALID_PARAM", message = "take_guid or take_index is required" }
    end

    reaper.Undo_BeginBlock()
    reaper.SetActiveTake(take)
    reaper.UpdateArrange()
    reaper.Undo_EndBlock("Set Active Take", -1)

    return true, {
        item_guid = param.item_guid,
        active_take_guid = get_take_guid(take)
    }
end

return M
