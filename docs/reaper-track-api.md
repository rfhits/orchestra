

## color

C: void SetTrackColor(MediaTrack* track, int color)

EEL2: SetTrackColor(MediaTrack track, int color)

Lua: reaper.SetTrackColor(MediaTrack track, integer color)

Python: RPR_SetTrackColor(MediaTrack track, Int color)

Set the custom track color, color is OS dependent (i.e. ColorToNative(r,g,b). To unset the track color, see SetMediaTrackInfo_Value I_CUSTOMCOLOR


C: int GetTrackColor(MediaTrack* track)

EEL2: int GetTrackColor(MediaTrack track)

Lua: integer reaper.GetTrackColor(MediaTrack track)

Python: Int RPR_GetTrackColor(MediaTrack track)

Returns the track custom color as OS dependent color|0x1000000 (i.e. ColorToNative(r,g,b)|0x1000000). Black is returned as 0x1000000, no color setting is returned as 0.