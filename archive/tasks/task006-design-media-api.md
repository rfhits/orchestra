# design media API

单数表示一个位置，点位
复数表示一个区间

sadi.render_measures(tracks, begin, len)
注：SADI 是自定义音乐格式，以后若要添加其他音乐格式导出，直接加入对应文件即可

audio.render_measures(tracks, begin, len)

audio.render_seconds(tracks, begin, len)

render 都放在 orchestra 的 outbox 下面，和对应 request 同名，但是 extension 不一样

midi.render_measures(tracks, begin, len)

midi.render_seconds(tracks, begin, len)

media.insert_at_measure(file, track, measure)

media.insert_at_second(file, track, second)

media will dispatch by file extension to midi/audio, and support other format like SADI
midi.insert_at_measure/second
audio.insert_at_measure/second
sadi.insert_at_measure/second

project.second_to_measure

project.measure_to_second

project.get_time_map(): 获取全局的时间变化，是一个 [time_map]

```JSON
{
  "time_map": [
    {
      "measure": 1.0,
      "second": 0.0,
      "bpm": 120.0,
      "time_signature": [4, 4]
    },
    {
      "measure": 9.0,
      "second": 16.0,
      "bpm": 140.0,
      "time_signature": [3, 4]
    }
  ],
  "current_cursor": {
    "measure": 10.5,
    "second": 18.25
  }
}
```

if want to import media, u have to create a track then call insert

我们要好好想一想，就是怎么把媒体文件给它插入到整个项目当中去？比如说我们调用一些 API，比如说像孙某说，你说其他 AI，它会专门生成一滚音频，然后我们要想办法这些操作都拆开，比如说如果用 MP3 文件，我希望放到某个轨道上，或者说我希望新建一个轨道，然后专门用来放我这个 MP3。或者说我有一个批量文件，我应该放到某一个轨道上，以某个时间开始，对吧？这是一个非常重要的 API，如果我们有 a i 来能够生成一针对已有的项目生成一些音频，然后我们要放进去，就是我们需要指定轨道，然后再把音频放进去，然后甚至可能要放到指定的位置，然后除此以外我们还可能是 MP3 以外的东西，可能是表格文件。对吧？我们是要把指定的 media 文件插到魔鬼轨道，什么时候开始插进去？然后我记得好像。

这个东西我也是有些想法，比如说我们可以有 MIDI，或者说有 media。对，他可以是一个什么点 operation？但是具体来说要怎么说，就是第一个问题是我们不知道要用什么点开始，因为之前轨道有轨道点吗？工程有工程点。但是现在这个插入文件我们不知道要用什么去表示它，然后第二个这个参数的问题，就是他要有时间，你要有轨道，然后轨道也可能是新建的，我们是要让他新建一个轨道再放进去，还是说直接放到某个轨道上？好？肯定要支持能够直接放到某个轨道上，因为我们可能是说专门要放到某轨道上，那这个怎么点？什么点？要怎么写比较合适？怎么设计比较合适呢？

而且比如说以后我们要针对一个轨道来说去 get info，对吧？获取某个轨道的信息，那么我们其实也要设计一种文件结构，设计一种 JSON 的结构能够返回说这个轨道的信息，或者说它其实要能够，其实还有很重要的操作是 render，就是渲染出整个项目从某一个时间段里的音频，或者说某一个轨道在某个区间内的音频，对吧？这个又要怎么设计？你整理一下我提到的这些 API，然后详细要怎么设计成我们说好的这种以点来作为分隔的格式更清晰。
