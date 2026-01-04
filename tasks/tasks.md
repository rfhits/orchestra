# tasks

## 遗留问题

1. 调用 logger 的接口不统一，未来要做成全部使用 logger 模块接口
2. log table 需要 json 打出的 string
3. logger 打印出来的行号总是 logger.lua 的行号
4. 给 clean up 绑定一个脚本快捷键
5. track.create 等 MCP 操作需要设置一个超时时间、以及返回值写到 docstring 中
6. bridge.call_reaper 目前是轮询，写死了超时时间，不知道会不会有性能问题
