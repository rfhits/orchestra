local M = {}
local logger = nil
local config = require("config")
local track_module = nil
local time_map = require("time_map")

function M.init(log_module)
    logger = log_module.get_logger("MIDI")
    track_module = require("track")
    time_map.init(log_module)
    logger.info("MIDI 模块初始化完成")
end

----------------------------------------------------------------
-- 二进制编码工具
----------------------------------------------------------------

local function encode_vlq(n)
    local bytes = {}
    n = math.floor(n)
    local res = n & 0x7F
    n = n >> 7
    table.insert(bytes, 1, res)
    while n > 0 do
        res = (n & 0x7F) | 0x80
        table.insert(bytes, 1, res)
        n = n >> 7
    end
    return string.char(table.unpack(bytes))
end

local function to_u32(n)
    return string.char((n >> 24) & 0xFF, (n >> 16) & 0xFF, (n >> 8) & 0xFF, n & 0xFF)
end

local function to_u16(n)
    return string.char((n >> 8) & 0xFF, n & 0xFF)
end

-- MPQN 计算：考虑拍号的分母
-- MPQN = 60,000,000 * den / (bpm * 4)
-- (因为 bpm 定义的是每分钟有多少个"beat"，而 beat 由时间签名的分母决定)
local function calculate_mpqn(bpm, den)
    return math.floor(60000000 * den / (bpm * 4) + 0.5)
end

-- 转换时间到 MIDI Tick（相对于导出开始位置）
local function time_to_tick(calc_take, time, start_time)
    local abs_ppq = reaper.MIDI_GetPPQPosFromProjTime(calc_take, time)
    local start_ppq = reaper.MIDI_GetPPQPosFromProjTime(calc_take, start_time)
    return math.floor(abs_ppq - start_ppq + 0.5)
end

-- GM 标准乐器列表（program #0-127）
-- 格式：{ program = 数字, names = { "乐器名1", "乐器名2", ... } }
-- names 中的第一个是主要名称，后续是别名
local GM_INSTRUMENTS = {
    { program = 0,   names = { "piano", "acoustic piano" } },
    { program = 1,   names = { "bright piano", "electric piano" } },
    { program = 2,   names = { "electric grand piano" } },
    { program = 3,   names = { "honky tonk piano" } },
    { program = 4,   names = { "electric piano", "e piano" } },
    { program = 5,   names = { "electric piano 2" } },
    { program = 6,   names = { "harpsichord" } },
    { program = 7,   names = { "clavier" } },
    { program = 8,   names = { "celesta" } },
    { program = 9,   names = { "glockenspiel" } },
    { program = 10,  names = { "music box" } },
    { program = 11,  names = { "vibraphone" } },
    { program = 12,  names = { "marimba" } },
    { program = 13,  names = { "xylophone" } },
    { program = 14,  names = { "tubular bells" } },
    { program = 15,  names = { "dulcimer" } },
    { program = 16,  names = { "drawbar organ" } },
    { program = 17,  names = { "percussive organ" } },
    { program = 18,  names = { "rock organ" } },
    { program = 19,  names = { "church organ" } },
    { program = 20,  names = { "reed organ" } },
    { program = 21,  names = { "accordion" } },
    { program = 22,  names = { "harmonica" } },
    { program = 23,  names = { "bandoneon" } },
    { program = 24,  names = { "nylon guitar", "nylon acoustic guitar" } },
    { program = 25,  names = { "steel guitar", "steel acoustic guitar" } },
    { program = 26,  names = { "jazz guitar" } },
    { program = 27,  names = { "clean guitar" } },
    { program = 28,  names = { "muted guitar" } },
    { program = 29,  names = { "overdriven guitar" } },
    { program = 30,  names = { "distortion guitar" } },
    { program = 31,  names = { "guitar harmonics" } },
    { program = 32,  names = { "acoustic bass" } },
    { program = 33,  names = { "fingered bass", "fingered electric bass" } },
    { program = 34,  names = { "picked bass" } },
    { program = 35,  names = { "fretless bass" } },
    { program = 36,  names = { "slap bass", "slap bass 1" } },
    { program = 37,  names = { "slap bass 2" } },
    { program = 38,  names = { "synth bass" } },
    { program = 39,  names = { "synth bass 2" } },
    { program = 40,  names = { "violin" } },
    { program = 41,  names = { "viola" } },
    { program = 42,  names = { "cello" } },
    { program = 43,  names = { "contrabass", "double bass" } },
    { program = 44,  names = { "tremolo strings" } },
    { program = 45,  names = { "pizzicato strings" } },
    { program = 46,  names = { "orchestral harp" } },
    { program = 47,  names = { "timpani" } },
    { program = 48,  names = { "string ensemble", "string ensemble 1" } },
    { program = 49,  names = { "string ensemble 2" } },
    { program = 50,  names = { "synthstrings", "synth strings 1" } },
    { program = 51,  names = { "synth strings 2" } },
    { program = 52,  names = { "choir aahs" } },
    { program = 53,  names = { "voice oohs", "voice aahs" } },
    { program = 54,  names = { "synth voice" } },
    { program = 55,  names = { "orchestra hit" } },
    { program = 56,  names = { "trumpet" } },
    { program = 57,  names = { "trombone" } },
    { program = 58,  names = { "tuba" } },
    { program = 59,  names = { "muted trumpet" } },
    { program = 60,  names = { "french horn" } },
    { program = 61,  names = { "brass section" } },
    { program = 62,  names = { "synthbrass", "synth brass 1" } },
    { program = 63,  names = { "synth brass 2" } },
    { program = 64,  names = { "soprano saxophone" } },
    { program = 65,  names = { "alto saxophone" } },
    { program = 66,  names = { "tenor saxophone" } },
    { program = 67,  names = { "baritone saxophone" } },
    { program = 68,  names = { "oboe" } },
    { program = 69,  names = { "english horn", "cor anglais" } },
    { program = 70,  names = { "bassoon" } },
    { program = 71,  names = { "clarinet" } },
    { program = 72,  names = { "piccolo" } },
    { program = 73,  names = { "flute" } },
    { program = 74,  names = { "recorder" } },
    { program = 75,  names = { "pan flute" } },
    { program = 76,  names = { "blown bottle" } },
    { program = 77,  names = { "shakuhachi" } },
    { program = 78,  names = { "whistle" } },
    { program = 79,  names = { "ocarina" } },
    { program = 80,  names = { "square wave", "lead 1" } },
    { program = 81,  names = { "sawtooth wave", "lead 2" } },
    { program = 82,  names = { "calliope" } },
    { program = 83,  names = { "chiff", "lead 4" } },
    { program = 84,  names = { "charang" } },
    { program = 85,  names = { "voice", "lead 6" } },
    { program = 86,  names = { "fifths", "lead 7" } },
    { program = 87,  names = { "bass and lead" } },
    { program = 88,  names = { "new age", "pad 1" } },
    { program = 89,  names = { "warm", "pad 2" } },
    { program = 90,  names = { "polysynth", "pad 3" } },
    { program = 91,  names = { "choir", "pad 4" } },
    { program = 92,  names = { "bowed glass" } },
    { program = 93,  names = { "metallic", "pad 6" } },
    { program = 94,  names = { "halo", "pad 7" } },
    { program = 95,  names = { "sweep", "pad 8" } },
    { program = 96,  names = { "rain" } },
    { program = 97,  names = { "soundtrack" } },
    { program = 98,  names = { "crystal" } },
    { program = 99,  names = { "atmosphere" } },
    { program = 100, names = { "brightness" } },
    { program = 101, names = { "goblins" } },
    { program = 102, names = { "echoes" } },
    { program = 103, names = { "sci fi" } },
    { program = 104, names = { "sitar" } },
    { program = 105, names = { "banjo" } },
    { program = 106, names = { "shamisen" } },
    { program = 107, names = { "koto" } },
    { program = 108, names = { "kalimba" } },
    { program = 109, names = { "bagpipe" } },
    { program = 110, names = { "fiddle" } },
    { program = 111, names = { "taiko drum", "taiko" } },
    { program = 112, names = { "melodic tom" } },
    { program = 113, names = { "synth drum" } },
    { program = 114, names = { "reverse cymbal" } },
    { program = 115, names = { "guitar fret noise" } },
    { program = 116, names = { "breath noise" } },
    { program = 117, names = { "seashore" } },
    { program = 118, names = { "bird tweet" } },
    { program = 119, names = { "telephone ring" } },
    { program = 120, names = { "helicopter" } },
    { program = 121, names = { "applause" } },
    { program = 122, names = { "gunshot" } },
}

-- 将轨道名称与乐器名称进行分词匹配，返回最匹配的 program #
-- 匹配原理：
--   1. 将轨道名称按空格、下划线等分词
--   2. 遍历所有 GM 乐器，计算轨道名称中有多少个词落在该乐器的名称中
--   3. 返回匹配词数最多的乐器 program #
--   4. 如果匹配词数相同，返回第一个匹配的乐器
--   5. 如果没有任何匹配，返回默认的 0（钢琴）
local function infer_program_from_track_name(track_name)
    if not track_name or track_name == "" then
        logger.debug("轨道名称为空，使用默认 Program #0 (Piano)")
        return 0
    end

    -- 分词：转换为小写，按空格、下划线、中划线分词
    local name_lower = string.lower(track_name)
    local tokens = {}
    for word in string.gmatch(name_lower, "[a-zA-Z0-9]+") do
        table.insert(tokens, word)
    end

    if #tokens == 0 then
        logger.debug("轨道名称无法分词，使用默认 Program #0 (Piano)")
        return 0
    end

    local best_program = 0
    local best_match_count = 0
    local best_instr_name = "piano"

    -- 遍历所有 GM 乐器
    for _, instr in ipairs(GM_INSTRUMENTS) do
        local match_count = 0

        -- 检查轨道名称中的每个词是否在乐器名称中出现
        for _, token in ipairs(tokens) do
            for _, instr_name in ipairs(instr.names) do
                if string.find(instr_name, token, 1, true) then
                    match_count = match_count + 1
                    break -- 每个 token 只计算一次
                end
            end
        end

        -- 更新最佳匹配
        if match_count > best_match_count then
            best_match_count = match_count
            best_program = instr.program
            best_instr_name = instr.names[1]
        end
    end

    -- 日志记录匹配结果
    if best_match_count > 0 then
        logger.info(string.format("轨道名称 [%s] 匹配到乐器 [%s] (Program #%d, 匹配词数=%d)",
            track_name, best_instr_name, best_program, best_match_count))
    else
        logger.debug(string.format("轨道名称 [%s] 无法匹配，使用默认 Program #0 (Piano)", track_name))
    end

    return best_program
end

-- 添加 Meta 事件（Set Tempo / Time Signature）
local function add_tempo_event(events, m, tick)
    local mpqn = calculate_mpqn(m.bpm, m.den)

    logger.info(string.format("Tempo标记 @ %.3fs: BPM=%.1f, TimeSig=%d/%d, MPQN=%d",
        m.time, m.bpm, m.num, m.den, mpqn))

    -- Set Tempo (FF 51)
    table.insert(events, {
        tick = tick,
        msg = string.char(0xFF, 0x51, 0x03, (mpqn >> 16) & 0xFF, (mpqn >> 8) & 0xFF, mpqn & 0xFF),
        type = 4
    })

    -- Time Signature (FF 58)
    local den_pow = math.floor(math.log(m.den, 2) + 0.5)
    logger.info(string.format("Time Signature @ tick %d: %d/%d (den_pow=%d)",
        tick, m.num, m.den, den_pow))

    table.insert(events, {
        tick = tick,
        msg = string.char(0xFF, 0x58, 0x04, m.num, den_pow, 24, 8),
        type = 4
    })
end

-- 添加音符事件
local function add_note_events(events, tr, track_name, start_time, end_time)
    for j = 0, reaper.GetTrackNumMediaItems(tr) - 1 do
        local item = reaper.GetTrackMediaItem(tr, j)
        local take = reaper.GetActiveTake(item)
        if take and reaper.TakeIsMIDI(take) then
            local _, notecnt = reaper.MIDI_CountEvts(take)
            for n = 0, notecnt - 1 do
                local _, _, _, startppq, endppq, chan, pitch, vel = reaper.MIDI_GetNote(take, n)
                local note_s = reaper.MIDI_GetProjTimeFromPPQPos(take, startppq)
                local note_e = reaper.MIDI_GetProjTimeFromPPQPos(take, endppq)

                if start_time <= note_s and note_e < end_time then
                    -- logger.debug(string.format("轨道 [%s] 发现音符: Pitch=%d, Chan=%d, Vel=%d, Start=%.3fs, End=%.3fs",
                    -- track_name, pitch, chan, vel, note_s, note_e))

                    local tick_s = math.max(0, time_to_tick(take, note_s, start_time))
                    local tick_e = time_to_tick(take, note_e, start_time)
                    local chan_normalized = chan & 0x0F

                    table.insert(events, {
                        tick = tick_s,
                        msg = string.char(0x90 | chan_normalized, pitch & 0x7F, vel & 0x7F),
                        type = 2
                    })
                    table.insert(events, {
                        tick = tick_e,
                        msg = string.char(0x80 | chan_normalized, pitch & 0x7F, 0x40),
                        type = 1
                    })
                end
            end
        end
    end
end

-- 添加初始化事件（轨道名称、Program Change、Reset Controllers）
local function add_init_events(events, track_name, first_tempo)
    -- 轨道名称 (FF 03)
    table.insert(events, {
        tick = 0,
        msg = string.char(0xFF, 0x03, #track_name) .. track_name,
        type = 5
    })

    -- Set Tempo (初始)
    local mpqn = calculate_mpqn(first_tempo.bpm, first_tempo.den)
    table.insert(events, {
        tick = 0,
        msg = string.char(0xFF, 0x51, 0x03, (mpqn >> 16) & 0xFF, (mpqn >> 8) & 0xFF, mpqn & 0xFF),
        type = 5
    })

    -- Reset All Controllers (B0 79 00)
    table.insert(events, {
        tick = 0,
        msg = string.char(0xB0, 0x79, 0x00),
        type = 5
    })

    -- Program Change - 从轨道名称推断乐器
    local program = infer_program_from_track_name(track_name)
    logger.info(string.format("轨道 [%s] 设置 Program Change: #%d", track_name, program))
    table.insert(events, {
        tick = 0,
        msg = string.char(0xC0, program & 0x7F),
        type = 5
    })
end

----------------------------------------------------------------
-- Tempo Map 采集
----------------------------------------------------------------

local function collect_tempo_map(end_time)
    local tempo_map = {}
    local marker_count = reaper.CountTempoTimeSigMarkers(0)
    local last_valid_num, last_valid_den = nil, nil

    if marker_count == 0 then
        local cur_bpm = reaper.Master_GetTempo()
        local num, den = reaper.GetProjectTimeSignature2(0)

        if not num or num <= 0 or not den or den <= 0 then
            logger.error(string.format("获取项目初始拍号失败: num=%s, den=%s", tostring(num), tostring(den)))
            return nil
        end

        table.insert(tempo_map, { time = 0, bpm = cur_bpm, num = num, den = den })
        last_valid_num, last_valid_den = num, den
    else
        for i = 0, marker_count - 1 do
            local _, timepos, _, _, bpm, num, den, _ = reaper.GetTempoTimeSigMarker(0, i)
            if timepos <= end_time then
                logger.info(string.format("发现 Tempo 标记 @ %.3fs: BPM=%.1f, TimeSig=%d/%d",
                    timepos, bpm, num, den))

                if num == -1 and den == -1 then
                    if not last_valid_num or not last_valid_den then
                        logger.error(string.format("无法继承时间签名：@ %.3fs 遇到 -1/-1，但之前没有有效的拍号", timepos))
                        return nil
                    end
                    num, den = last_valid_num, last_valid_den
                    logger.debug(string.format("  -> 沿用上一个时间签名: %d/%d", num, den))
                else
                    if not num or num <= 0 or not den or den <= 0 then
                        logger.error(string.format("无效的时间签名 @ %.3fs: num=%s, den=%s", timepos, tostring(num),
                            tostring(den)))
                        return nil
                    end
                    last_valid_num, last_valid_den = num, den
                end

                table.insert(tempo_map, { time = timepos, bpm = bpm, num = num, den = den })
            end
        end

        if #tempo_map == 0 or tempo_map[1].time > 0 then
            local cur_bpm = reaper.Master_GetTempo()
            local num, den = reaper.GetProjectTimeSignature2(0)

            if not num or num <= 0 or not den or den <= 0 then
                logger.error(string.format("获取初始拍号失败（回退）: num=%s, den=%s", tostring(num), tostring(den)))
                return nil
            end

            table.insert(tempo_map, 1, { time = 0, bpm = cur_bpm, num = num, den = den })
            last_valid_num, last_valid_den = num, den
        end
    end

    logger.info(string.format("采集完成：共 %d 个 Tempo 标记", #tempo_map))
    return tempo_map
end

----------------------------------------------------------------
-- 核心导出函数
----------------------------------------------------------------

local function perform_midi_render(tracks, start_time, end_time, session_id)
    logger.info(string.format("开始导出 MIDI：start=%.3fs, end=%.3fs, session=%s", start_time, end_time, session_id))

    local tempo_map = collect_tempo_map(end_time)
    if not tempo_map then
        return false, { code = "INVALID_PARAM", message = "Failed to collect tempo map" }
    end

    local datetime = os.date("%Y%m%d_%H%M%S")
    local folder_name = string.format("%s_%s", datetime, session_id)
    local outbox_dir = config.get_outbox_dir()
    local session_path = outbox_dir .. "/" .. folder_name
    reaper.RecursiveCreateDirectory(session_path, 0)
    logger.info(string.format("创建导出文件夹: %s", session_path))

    for index, id in ipairs(tracks) do
        local tr = track_module.find_track(id)
        if not tr then
            logger.warn(string.format("轨道 #%d 未找到，跳过", index))
            goto continue
        end

        local _, track_name = reaper.GetSetMediaTrackInfo_String(tr, "P_NAME", "", false)
        if track_name == "" then track_name = "Track_" .. index end
        local safe_name = track_name:gsub('[%s%p]', '_')
        local file_path = session_path .. "/" .. string.format("%02d_%s.mid", index, safe_name)

        logger.info(string.format("处理轨道 [%s] -> %s", track_name, file_path))

        -- 获取 MIDI Take
        local calc_take = nil
        for j = 0, reaper.GetTrackNumMediaItems(tr) - 1 do
            local it = reaper.GetTrackMediaItem(tr, j)
            local tk = reaper.GetActiveTake(it)
            if tk and reaper.TakeIsMIDI(tk) then
                calc_take = tk
                break
            end
        end

        local is_temp_item = false
        if not calc_take then
            logger.debug("轨道没有 MIDI Item，创建临时 Item")
            local temp_item = reaper.CreateNewMIDIItemInProj(tr, 0, 1, false)
            calc_take = reaper.GetActiveTake(temp_item)
            is_temp_item = true
        end

        -- 获取 PPQ 分辨率
        local actual_ppq = reaper.MIDI_GetPPQPosFromProjQN(calc_take, 1) -
            reaper.MIDI_GetPPQPosFromProjQN(calc_take, 0)
        actual_ppq = math.floor(actual_ppq + 0.5)
        logger.info(string.format("轨道 [%s] PPQ 分辨率: %d", track_name, actual_ppq))

        -- 构建事件列表
        local events = {}
        add_init_events(events, track_name, tempo_map[1])

        for _, m in ipairs(tempo_map) do
            local tick = time_to_tick(calc_take, m.time, start_time)
            if tick >= 0 then
                add_tempo_event(events, m, tick)
            end
        end

        add_note_events(events, tr, track_name, start_time, end_time)

        -- 排序事件
        table.sort(events, function(a, b)
            if a.tick ~= b.tick then return a.tick < b.tick end
            return a.type > b.type
        end)
        logger.debug(string.format("事件排序完成，共 %d 个事件", #events))

        -- 编码为 MIDI 数据
        local track_data = ""
        local last_tick = 0
        for _, ev in ipairs(events) do
            local delta = ev.tick - last_tick
            if delta < 0 then delta = 0 end
            track_data = track_data .. encode_vlq(delta) .. ev.msg
            last_tick = ev.tick
        end
        track_data = track_data .. encode_vlq(0) .. string.char(0xFF, 0x2F, 0x00)
        logger.debug(string.format("Track Data 编码完成，大小: %d 字节", #track_data))

        -- 写入文件
        local f, err = io.open(file_path, "wb")
        if f then
            f:write("MThd" .. to_u32(6) .. to_u16(0) .. to_u16(1) .. to_u16(actual_ppq))
            f:write("MTrk" .. to_u32(#track_data) .. track_data)
            f:close()
            logger.info(string.format("MIDI 写入成功: %s (PPQ=%d, 大小=%d+14字节)",
                file_path, actual_ppq, #track_data))
        else
            logger.error(string.format("文件写入失败 [%s]: %s", file_path, tostring(err)))
        end

        if is_temp_item then
            reaper.DeleteTrackMediaItem(tr, reaper.GetMediaItemTake_Item(calc_take))
            logger.debug("临时 MIDI Item 已删除")
        end

        ::continue::
    end

    logger.info(string.format("导出完成：%s", session_path))
    return { path = session_path, folder_name = folder_name, session_id = session_id }
end

----------------------------------------------------------------
-- API 接口
----------------------------------------------------------------

function M.render_measures(param)
    local start_t = time_map.measure_to_second(param.begin)
    local end_t = time_map.measure_to_second(param.begin + (param.len or 1))
    logger.info(string.format("render_measures: begin=%d, len=%d -> [%.3fs, %.3fs]",
        param.begin or 1, param.len or 1, start_t, end_t))
    return true, perform_midi_render(param.tracks or {}, start_t, end_t, param.session_id or "meas")
end

function M.render_seconds(param)
    local start_t = param.begin or 0
    local end_t = start_t + (param.len or 10)
    logger.info(string.format("render_seconds: begin=%.3fs, len=%.3fs -> [%.3fs, %.3fs]",
        start_t, param.len or 10, start_t, end_t))
    return true, perform_midi_render(param.tracks or {}, start_t, end_t, param.session_id or "sec")
end

function M.insert_at_measure(param)
    local pos = time_map.measure_to_second(param.measure or 1)
    logger.info(string.format("insert_at_measure: measure=%d -> %.3fs", param.measure or 1, pos))

    reaper.SetEditCurPos(pos, false, false)
    local tr = track_module.find_track(param.track)
    if tr then
        reaper.SetOnlyTrackSelected(tr)
        reaper.InsertMedia(param.file_path, 0)
        logger.info(string.format("MIDI 插入成功: %s", param.file_path))
        return true, { success = true }
    end

    logger.error(string.format("轨道未找到: %s", tostring(param.track)))
    return false, { code = "NOT_FOUND", message = "Track not found" }
end

return M
