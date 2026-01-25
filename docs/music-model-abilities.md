# 音乐模型能力

## lyrics2audio

```cpp
lyrics2audio(lyrics, text_prompt, audio_prompt, secs, **args) -> audio
```


具备从歌词生成音乐能力的大模型。

- [DiffRhythm2]()
- [YuE]()
- [ACE-step]()

ACE 功能是最丰富的，但是没看到脚本调用的方式。值得研究一下

## inpaint_audio

```cpp
inpaint_audio(audio, start_sec, end_sec, **args) -> audio
```

需要提供一长段 audio 作为 reference，因为想要 inpaint，得知道前后长什么样

- [ACE-step]

## inpaint

```py
inpaint_midi(midi, start_sec, end_sec, **args)
```

## split_stems

```python
split_stems(audio, **args) -> List[audio]
```

- htdemucs: 这个不太好，因为没法出四大件
- BS-Former

## extract_pitch

```py
extract_pitch(audio, **args) -> midi
```
