## Track Parent/Child API Plan

Goal: add a track-level API to set parent/child folder hierarchy using REAPER's documented APIs (no custom/undocumented calls).

Key REAPER APIs (see docs/standards/reaper-api-functions.md):
- GetMediaTrackInfo_Value("IP_TRACKNUMBER") to get 1-based track index.
- GetMediaTrackInfo_Value("I_FOLDERDEPTH") to detect if a track is last in a folder.
- ReorderSelectedTracks(beforeTrackIdx, makePrevFolder) to move the child under the parent and create/extend folders.
- GetParentTrack(track) to verify the result.
- SetOnlyTrackSelected(track), SetTrackSelected(track, bool), CountSelectedTracks, GetSelectedTrack for selection control.
- Undo_BeginBlock/Undo_EndBlock + UpdateArrange for proper UI/undo behavior.

Algorithm sketch:
1) Validate param.parent_track / param.child_track (non-empty).
2) Resolve both tracks via track.find_track (GUID/name/index).
3) If same track -> INVALID_PARAM. If already parent -> early success.
4) Compute parent_index / child_index from IP_TRACKNUMBER.
5) Compute before_index:
   - if child_index < parent_index -> before_index = parent_index
   - else before_index = parent_index + 1
   - clamp to [0, CountTracks(0)]
6) Decide makePrevFolder:
   - if parent I_FOLDERDEPTH < 0, use 2 to extend folder
   - else use 1
7) Save current selection, select child only, call ReorderSelectedTracks.
8) Restore selection, UpdateArrange, verify GetParentTrack(child) == parent.

Return payload:
- moved / already_parent
- parent_track_guid / child_track_guid
- before_index / make_prev_folder (debug/trace)
