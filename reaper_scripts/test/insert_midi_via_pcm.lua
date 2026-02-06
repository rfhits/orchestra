
function InsertMidiSilently(filePath, trackIndex, startTime)
    local track = reaper.GetTrack(0, trackIndex)
    if not track then return end

    local newItem = reaper.CreateNewMIDIItemInProj(track, startTime, startTime + 1, false)

    -- 关闭循环，防止长度不匹配导致重复
    reaper.SetMediaItemInfo_Value(newItem, "B_LOOPSRC", 0)

    local take = reaper.GetActiveTake(newItem)
    local pcm_src = reaper.PCM_Source_CreateFromFile(filePath)
    reaper.SetMediaItemTake_Source(take, pcm_src)

    -- 3. 获取 MIDI 实际长度并更新 Item 长度
    local length, _ = reaper.GetMediaSourceLength(pcm_src)
    reaper.SetMediaItemInfo_Value(newItem, "D_LENGTH", length)

    reaper.UpdateArrange()
end

-- 使用示例：
local path = "C:\\Users\\rfntts\\AppData\\Roaming\\REAPER\\Scripts\\orchestra\\test\\midi\\01_piano.mid"

InsertMidiSilently(path, 11, 2)
