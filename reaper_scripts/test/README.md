# Orchestra 测试指南

## 测试文件说明

### 测试用例文件

在 `test/cases/` 目录下有预制的测试JSON文件：

1. **track_create_test.json** - 测试创建轨道
   - 功能：`track.create`
   - 参数：创建名为"Test Piano Track"的轨道

2. **track_delete_test.json** - 测试删除轨道
   - 功能：`track.delete`
   - 参数：删除指定GUID的轨道

3. **media_insert_test.json** - 测试插入媒体
   - 功能：`media.insert`
   - 参数：插入音频文件到指定轨道

4. **project_get_info_test.json** - 测试获取项目信息
   - 功能：`project.get_info`
   - 参数：空参数

5. **error_test_invalid_function.json** - 测试错误处理
   - 功能：`invalid.module.function`
   - 预期：返回错误响应

## 如何运行测试

### 方法1：使用测试运行器
1. 在REAPER中运行 `test/test_runner.lua`
2. 选择测试菜单中的选项
3. 查看控制台输出和outbox目录中的结果

### 方法2：手动复制测试文件
1. 将测试JSON文件复制到 `~/.orchestra/inbox/` 目录
2. 重命名为 `{timestamp}_{agent_id}_{random}.json` 格式
3. 运行 `orchestra_loader.lua` 开始处理
4. 查看 `~/.orchestra/outbox/` 目录中的响应

## 停止Orchestra客户端

### 方法1：使用停止脚本
运行 `orchestra_stop.lua` 创建停止信号，客户端会自动停止。

### 方法2：直接关闭
由于使用 `reaper.defer`，直接关闭REAPER或脚本即可停止。

## 测试流程示例

1. **启动Orchestra**：
   ```
   运行 orchestra_loader.lua
   ```

2. **运行测试**：
   ```
   运行 test/test_runner.lua
   选择 "1. Test Track Create"
   ```

3. **查看结果**：
   - 检查控制台输出
   - 查看 `~/.orchestra/outbox/` 目录中的 `.reply.json` 文件

4. **停止客户端**：
   ```
   运行 orchestra_stop.lua
   ```

## 预期结果

### 成功响应格式
```json
{
  "meta": {"id": "...", "version": "1"},
  "request": {"func": "...", "param": {...}},
  "response": {
    "ok": true,
    "result": {...},
    "error": null
  }
}
```

### 错误响应格式
```json
{
  "meta": {"id": "...", "version": "1"},
  "request": {"func": "...", "param": {...}},
  "response": {
    "ok": false,
    "result": null,
    "error": {
      "code": "ERROR_CODE",
      "message": "Error description"
    }
  }
}
```

## 故障排除

1. **测试文件未处理**：
   - 检查inbox目录权限
   - 确认orchestra客户端正在运行

2. **响应文件未生成**：
   - 检查outbox目录权限
   - 查看控制台错误信息

3. **客户端无法停止**：
   - 运行 `orchestra_stop.lua`
   - 重启REAPER