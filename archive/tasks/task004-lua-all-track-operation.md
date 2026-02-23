# all track operations

我们现在目标是要在 Lua 侧实现如下这些关于轨道的函数。这样我们就可以使得 MCP 可以就是获取到一个跟获取到当前项目下所有 track 的信息，比如说叫什么名字，有什么颜色，对吧？当然这只是一个粗略的信息，他没有办法那个获得很好。然后我们要仔细想想怎么做这些事情，因为有时候他是做 operation 似的，有时候他是做 get 似的，然后它 get 是它要怎么给它返回一个东西，对吧？这个整个 track 要怎么表示它？这是一个比较繁琐的事情，嗯，我们要好好想一想，然后我们当然可以先慢慢做，先做那个，先慢慢做，先做 operation 形式的，就是可以直接设置好这个 track 的某种属性的，然后我们再想办法给它返回说某个 track 的某种属性，当然这个要参考 reaper 的 API 了。

下面是另一个项目的 api 名字，做的不好，只是给我们参考：

-   rename_track: Rename an existing track
-   set_track_color: Set track color
-   get_track_color: Get track color
-   get_track_count: Get number of tracks in project
-   get_track_list: Get list of all tracks with their properties

## 要给这些 api 合理的名字和参数、返回值

track.rename(index, new_name)
track.set_color(index, color)
track.get_color(index)

project.get_track_count()
project.get_track_list() -> [track]

track 的信息要同步更新到 [track.md](../docs/track.md)

## 需要严谨地调用 reaper 的 API 实现

参考 [reaper-api-functions.md](../docs/reaper-api-functions.md)

注意实现到 track、project lua 文件下，

## 做好测试

同时需要创建对应的 testcases，testcases 也放在对应的文件夹下面
比如 测试 track，就放到 test/track 下面的 json，

同时修改 [test_runner.lua](../test_runner.lua) ，因为文件夹变了

## 审核代码

-   track.rename: 没有问题
-   track.set_color: 没有问题
-   track.get_color: 没有问题
-   project.get_track_count: 没有问题
-   project.get_track_list: 没有问题
