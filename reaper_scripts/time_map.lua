-- Time Map Utilities Module
-- 提供基于 TimeMap_GetMeasureInfo 的准确时间和小节转换

local M = {}
local logger = nil

function M.init(log_module)
    logger = log_module.get_logger("TimeMap")
    logger.info("TimeMap 模块初始化完成")
end

--[[
    将 1-based 小节号（包括小数部分）转换为秒数
    
    例如：
      measure_to_second(1) 返回第 1 小节开头的秒数
      measure_to_second(1.5) 返回第 1 小节过了一半的秒数
      measure_to_second(2.75) 返回第 2 小节过了 3/4 的秒数
    
    使用 TimeMap_GetMeasureInfo API 正确处理变拍、变速的情况
    
    @param float_meas number: 1-based 小节号（可包含小数部分）
    @return number: 对应的秒数
--]]
function M.measure_to_second(float_meas)
    if not float_meas or float_meas < 1 then
        float_meas = 1
    end

    local m_int = math.floor(float_meas)  -- 整数部分（小节号，1-based）
    local m_frac = float_meas - m_int      -- 小数部分（0-1 之间）

    -- 1. 获取该小节的信息（使用 0-based 索引）
    local meas_idx = m_int - 1
    local retval, qn_start, qn_end, ts_num, ts_den, tempo = 
        reaper.TimeMap_GetMeasureInfo(0, meas_idx)

    if not retval or retval < 0 then
        logger.error(string.format("无法获取小节 %d 的信息 (0-based index: %d)", m_int, meas_idx))
        return 0
    end

    -- 2. 计算该小节内的偏移（QN 单位）
    local meas_length_qn = qn_end - qn_start
    local offset_qn = meas_length_qn * m_frac

    -- 3. 获取目标 QN 位置的秒数
    local target_qn = qn_start + offset_qn
    local final_sec = reaper.TimeMap2_QNToTime(0, target_qn)

    if logger then
        logger.debug(string.format("小节转换 | 输入:%.2f -> 小节:(%d-based), 偏移:%.2f%%, QN:%.2f, 拍号:%d/%d, 速度:%.1fBPM -> 秒:%.3f",
            float_meas, m_int, m_frac * 100, target_qn, ts_num, ts_den, tempo, final_sec))
    end

    return final_sec
end

--[[
    获取指定小节（1-based）的开头时间（秒）
    
    @param measure_idx integer: 1-based 小节号
    @return number: 小节开头的秒数
--]]
function M.get_measure_start_time(measure_idx)
    if not measure_idx or measure_idx < 1 then
        measure_idx = 1
    end

    local retval, qn_start = reaper.TimeMap_GetMeasureInfo(0, measure_idx - 1)
    if not retval or retval < 0 then
        logger.error(string.format("无法获取小节 %d 的开头时间", measure_idx))
        return 0
    end

    local start_sec = reaper.TimeMap2_QNToTime(0, qn_start)
    if logger then
        logger.debug(string.format("获取小节 %d 开头时间: QN=%.2f -> %.3fs", measure_idx, qn_start, start_sec))
    end

    return start_sec
end

--[[
    获取指定小节（1-based）的结束时间（秒）
    
    @param measure_idx integer: 1-based 小节号
    @return number: 小节结束的秒数
--]]
function M.get_measure_end_time(measure_idx)
    if not measure_idx or measure_idx < 1 then
        measure_idx = 1
    end

    local retval, _, qn_end = reaper.TimeMap_GetMeasureInfo(0, measure_idx - 1)
    if not retval or retval < 0 then
        logger.error(string.format("无法获取小节 %d 的结束时间", measure_idx))
        return 0
    end

    local end_sec = reaper.TimeMap2_QNToTime(0, qn_end)
    if logger then
        logger.debug(string.format("获取小节 %d 结束时间: QN=%.2f -> %.3fs", measure_idx, qn_end, end_sec))
    end

    return end_sec
end

--[[
    获取指定小节（1-based）的时间签名
    
    @param measure_idx integer: 1-based 小节号
    @return integer, integer: 分子, 分母
--]]
function M.get_measure_time_signature(measure_idx)
    if not measure_idx or measure_idx < 1 then
        measure_idx = 1
    end

    local retval, _, _, ts_num, ts_den = reaper.TimeMap_GetMeasureInfo(0, measure_idx - 1)
    if not retval or retval < 0 then
        logger.warn(string.format("无法获取小节 %d 的时间签名，使用默认 4/4", measure_idx))
        return 4, 4
    end

    if logger then
        logger.debug(string.format("小节 %d 的时间签名: %d/%d", measure_idx, ts_num, ts_den))
    end

    return ts_num, ts_den
end

--[[
    获取指定小节（1-based）的 BPM
    
    @param measure_idx integer: 1-based 小节号
    @return number: BPM
--]]
function M.get_measure_tempo(measure_idx)
    if not measure_idx or measure_idx < 1 then
        measure_idx = 1
    end

    local retval, _, _, _, _, tempo = reaper.TimeMap_GetMeasureInfo(0, measure_idx - 1)
    if not retval or retval < 0 then
        logger.warn(string.format("无法获取小节 %d 的 BPM，使用默认 120", measure_idx))
        return 120
    end

    if logger then
        logger.debug(string.format("小节 %d 的 BPM: %.1f", measure_idx, tempo))
    end

    return tempo
end

--[[
    将秒数转换为小节号（包含小数部分）
    
    例如：如果 10.5 秒对应第 4 小节的中点，返回 4.5
    
    @param time_sec number: 秒数
    @return number: 小节号（1-based，包含小数）
--]]
function M.second_to_measure(time_sec)
    if not time_sec then time_sec = 0 end

    -- 1. 将秒数转换为 QN
    local qn = reaper.TimeMap2_timeToQN(0, time_sec)

    -- 2. 二分查找找到包含该 QN 的小节
    local measure_idx = 0
    local low, high = 0, 1000  -- 假设项目最多 1000 小节

    while low < high do
        local mid = math.floor((low + high) / 2)
        local retval, qn_start, qn_end = reaper.TimeMap_GetMeasureInfo(0, mid)
        
        if not retval or retval < 0 then
            high = mid
        elseif qn < qn_start then
            high = mid
        elseif qn >= qn_end then
            low = mid + 1
        else
            measure_idx = mid
            break
        end
    end

    -- 3. 获取该小节的信息
    local retval, qn_start, qn_end = reaper.TimeMap_GetMeasureInfo(0, measure_idx)
    if not retval or retval < 0 then
        logger.error(string.format("无法获取小节 %d 的信息", measure_idx))
        return 1
    end

    -- 4. 计算小节号和小数部分
    local meas_length_qn = qn_end - qn_start
    local offset_ratio = (qn - qn_start) / meas_length_qn
    local result = (measure_idx + 1) + offset_ratio  -- +1 转换为 1-based

    if logger then
        logger.debug(string.format("秒数转换 | 输入:%.3fs -> QN:%.2f, 小节:%d (0-based), 偏移:%.2f%% -> %.2f",
            time_sec, qn, measure_idx, offset_ratio * 100, result))
    end

    return result
end

return M
