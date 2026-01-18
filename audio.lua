-- Audio Module
-- 强化了日志记录与错误追踪

local M = {}
local logger = nil
local config = require("config")
local track_module = nil
local time_map = require("time_map")

function M.init(log_module)
    logger = log_module.get_logger("Audio")
    track_module = require("track")
    time_map.init(log_module)
    logger.info("Audio 模块初始化完成")
end


--[[
    执行渲染的核心逻辑 (全状态保护版)
    @param tracks table: 轨道 ID 列表 (如果为空则渲染 Master)
    @param start_time number: 起始时间 (秒)
    @param end_time number: 结束时间 (秒)
    @param output_filename string: 输出文件名
--]]
local function perform_render(tracks, start_time, end_time, output_filename)
    logger.info(string.format("准备渲染任务 | 范围: %.3fs - %.3fs", start_time, end_time))

    -- 1. 现场快照：记录所有轨道当前的 Solo 和 Mute 状态
    local track_count = reaper.CountTracks(0)
    local original_states = {} -- 存储格式: { [track_ptr] = { solo = val, mute = val } }

    for i = 0, track_count - 1 do
        local tr = reaper.GetTrack(0, i)
        original_states[tr] = {
            solo = reaper.GetMediaTrackInfo_Value(tr, "I_SOLO"),
            mute = reaper.GetMediaTrackInfo_Value(tr, "B_MUTE")
        }
    end

    -- 2. 准备渲染环境
    reaper.Undo_BeginBlock()

    -- 设置时间轴选区 (Time Selection)
    reaper.GetSet_LoopTimeRange(true, false, start_time, end_time, false)

    -- 配置渲染范围标志: 2 = Time Selection
    reaper.GetSetProjectInfo(0, "RENDER_BOUNDSFLAG", 2, true)

    -- 配置渲染源: 0 = Master Mix
    reaper.GetSetProjectInfo(0, "RENDER_SETTINGS", 0, true)

    -- 3. 强制轨道状态以满足渲染需求
    -- 第一步：全部取消 Solo，全部取消 Mute (确保渲染时不会被之前的设置静音)
    reaper.Main_OnCommand(40340, 0) -- Unsolo all tracks
    reaper.Main_OnCommand(40339, 0) -- Unmute all tracks

    -- 第二步：如果有指定轨道，则将其 Solo
    if tracks and #tracks > 0 then
        logger.info("执行特定轨道 Solo 渲染")
        for _, id in ipairs(tracks) do
            local track = track_module.find_track(id) -- 假设 track_module 已在外部定义
            if track then
                reaper.SetMediaTrackInfo_Value(track, "I_SOLO", 1)
                local _, t_name = reaper.GetSetMediaTrackInfo_String(track, "P_NAME", "", false)
                logger.debug(string.format("渲染目标已激活: [%s]", t_name))
            else
                logger.warn("未找到目标轨道: " .. tostring(id))
            end
        end
    else
        logger.info("未指定特定轨道，将渲染 Master Mix (当前已清理所有 Mute/Solo)")
    end

    -- 4. 【核心保护逻辑】：原生方式强制素材上线
    -- 逻辑：选中所有 Item -> 执行上线指令 -> 取消选中
    -- 这会强制 REAPER 扫描并加载所有选中的素材，防止渲染出静音
    reaper.Main_OnCommand(40182, 0) -- Item: Select all items
    reaper.Main_OnCommand(40101, 0) -- Media items: Set all media online
    reaper.Main_OnCommand(40289, 0) -- Item: Unselect all items

    -- 4. 配置输出路径
    local outbox_dir = config.get_outbox_dir() -- 假设 config 已在外部定义
    -- 去掉文件名扩展名，防止生成 .wav.wav
    local pattern = output_filename:match("(.+)%..+") or output_filename

    reaper.GetSetProjectInfo_String(0, "RENDER_FILE", outbox_dir, true)
    reaper.GetSetProjectInfo_String(0, "RENDER_PATTERN", pattern, true)
    logger.info("输出路径: " .. outbox_dir .. "/" .. output_filename)

    -- 5. 执行渲染命令 (41824: Render project, using most recent render settings, then auto-close)
    reaper.Main_OnCommand(41824, 0)
    logger.info("渲染命令执行完毕")

    -- 6. 现场还原：根据快照恢复每一个轨道的原始状态
    for tr, state in pairs(original_states) do
        if reaper.ValidatePtr(tr, "MediaTrack*") then
            reaper.SetMediaTrackInfo_Value(tr, "I_SOLO", state.solo)
            reaper.SetMediaTrackInfo_Value(tr, "B_MUTE", state.mute)
        end
    end

    -- 7. 刷新工程界面
    reaper.UpdateArrange()
    reaper.Undo_EndBlock("Batch Audio Render", -1)

    return outbox_dir .. "/" .. output_filename
end

function M.render_seconds(param)
    local begin_sec = param.begin or 0
    local len_sec = param.len or 10
    local filename = param.filename or ("render_" .. os.time() .. ".wav")
    local path = perform_render(param.tracks, begin_sec, begin_sec + len_sec, filename)
    return true, { file_path = path }
end

function M.render_measures(param)
    local begin_meas_input = param.begin or 1
    local len_meas = param.len or 1
    -- 0-based 转换
    local begin_sec = time_map.measure_to_second(begin_meas_input)
    local end_sec = time_map.measure_to_second(begin_meas_input + len_meas)

    local filename = param.filename or string.format("render_m%d_l%d.wav", begin_meas_input, len_meas)
    local path = perform_render(param.tracks, begin_sec, end_sec, filename)
    return true, { file_path = path }
end

function M.insert(param)
    local file_path = param.file_path
    local track = param.track
    local position = param.position or 0

    logger.info(string.format("准备插入媒体 | 位置: %.3fs", position))

    -- 检查文件是否存在
    local f = io.open(file_path, "r")
    if not f then
        logger.error("文件不可访问: " .. tostring(file_path))
        return false, { code = "FILE_NOT_FOUND", message = "Path: " .. tostring(file_path) }
    end
    f:close()

    reaper.Undo_BeginBlock()

    -- 1. 保存当前状态
    local initial_selected_track = reaper.GetSelectedTrack(0, 0)
    local saved_cursor = reaper.GetCursorPosition()

    -- 2. 处理轨道逻辑
    if track then
        local found_track = track_module.find_track(track)
        if found_track then
            -- 反选所有轨道
            reaper.Main_OnCommand(40297, 0)
            -- 设置轨道为选中状态
            reaper.SetTrackSelected(found_track, true)
            -- 【核心修复】：设置目标轨道为最后触碰轨道 (Last Touched)
            -- InsertMedia 依赖这个状态来决定插入位置
            reaper.SetOnlyTrackSelected(found_track)
        else
            logger.warn("目标轨道不存在，将插入到当前活动轨道")
        end
    end

    -- 3. 设置光标位置并插入
    reaper.SetEditCurPos(position, false, false)
    -- mode 0 表示直接插入。注意：如果是多声道文件，可能会弹出对话框，某些环境下可用 512 (静默插入)
    reaper.InsertMedia(file_path, 0)

    -- 4. 恢复现场
    reaper.SetEditCurPos(saved_cursor, false, false)
    if initial_selected_track then
        reaper.Main_OnCommand(40297, 0)
        reaper.SetTrackSelected(initial_selected_track, true)
    end

    -- 强制刷新
    reaper.UpdateArrange()
    reaper.Undo_EndBlock("Insert Media: " .. file_path, -1)

    logger.info("媒体插入操作完成")
    return true, {
        inserted = true,
        file_path = file_path,
        track = track,
        position = position
    }
end

function M.insert_at_second(param)
    -- 注意：这里需要确保输入的 param 字段与 M.insert 对应
    return M.insert({
        file_path = param.file_path,
        track = param.track,
        position = param.second
    })
end

function M.insert_at_measure(param)
    local sec = time_map.measure_to_second(param.measure or 1)
    return M.insert({
        file_path = param.file_path,
        track = param.track,
        position = sec
    })
end

return M
