# Orchestra Client Architecture v2

基于用户反馈重新设计的模块化架构，解决了原版代码的以下问题：

## 主要改进

### 1. **模块化设计**

-   ✅ **文件分离**：功能按职责拆分为独立模块
-   ✅ **动态加载**：使用模块加载器管理依赖关系
-   ✅ **清晰接口**：每个模块都有明确的职责和接口

### 2. **专业 JSON 处理**

-   ✅ **外部库支持**：`json.lua`
-   ✅ **向后兼容**：自动回退到内置解析器
-   ✅ **完整功能**：支持数组、对象、嵌套结构

### 3. **表驱动分派**

-   ✅ **消除 if-else 链**：使用表进行函数分派
-   ✅ **易于扩展**：新增功能只需注册处理器
-   ✅ **错误处理**：统一的错误响应机制

### 4. **改进的循环机制**

-   ✅ **reaper.defer**：替代 while true + sleep
-   ✅ **非阻塞**：不影响 REAPER 界面响应
-   ✅ **资源友好**：只在有请求时处理

## 模块结构

```
orchestra_loader.lua    # 模块加载器和启动入口
├── logger.lua          # 日志记录系统
├── file_manager.lua    # 文件系统操作
├── json_manager.lua    # JSON解析和生成
├── track.lua           # Track操作封装
├── media.lua           # Media操作封装
├── project.lua         # Project操作封装
├── dispatcher.lua      # 动态函数分派器
└── orchestra_main.lua  # 主逻辑和循环
```

## 模块详解

### orchestra_loader.lua

-   **职责**：模块加载管理和启动
-   **功能**：
    -   自动检测脚本路径
    -   动态注入 package.path
    -   安全加载所有模块
    -   验证关键模块

### logger.lua

-   **职责**：统一日志系统
-   **功能**：
    -   多级别日志（DEBUG/INFO/WARN/ERROR）
    -   文件和控制台双输出
    -   时间戳和格式化

### file_manager.lua

-   **职责**：文件系统操作封装
-   **功能**：
    -   目录初始化和管理
    -   原子文件操作
    -   IPC 协议文件管理

### json_manager.lua

-   **职责**：JSON处理

### track.lua

-   **职责**：Track操作封装
-   **功能**：
    -   创建、删除、查询轨道
    -   轨道信息获取
    -   错误处理

### media.lua

-   **职责**：Media操作封装
-   **功能**：
    -   插入媒体文件
    -   媒体文件验证
    -   错误处理

### project.lua

-   **职责**：Project操作封装
-   **功能**：
    -   获取项目信息
    -   项目状态查询

### dispatcher.lua

-   **职责**：动态函数分派
-   **功能**：
    -   字符串驱动的函数分派（module.method）
    -   统一响应格式
    -   错误处理和验证
    -   动态模块调用

### orchestra_main.lua

-   **职责**：主逻辑控制
-   **功能**：
    -   reaper.defer 循环
    -   请求处理流程
    -   模块协调
    -   状态管理

## 使用方法

### 启动 Orchestra

1. **启动**：运行 `orchestra_loader.lua`
2. **自动加载**：所有模块自动加载和初始化
3. **后台运行**：使用 defer 机制不影响界面

### 停止 Orchestra

1. **优雅停止**：运行 `orchestra_stop.lua` 创建停止信号
2. **强制停止**：直接关闭 REAPER 或脚本

### 运行测试

1. **测试运行器**：运行 `test/test_runner.lua` 选择测试
2. **手动测试**：将 JSON 文件复制到 `~/.orchestra/inbox/`

## 扩展新功能

### 1. 添加新的功能模块

创建新的独立模块文件（如 `effects.lua`）：

```lua
-- effects.lua
local M = {}

function M.apply_reverb(param)
    -- 实现逻辑
    return true, {result = "reverb applied"}
end

return M
```

### 2. 直接使用新功能

无需修改dispatcher，直接调用：

```json
{
  "request": {
    "func": "effects.apply_reverb",
    "param": {"intensity": 0.8}
  }
}
```

### 3. 添加新模块到加载列表

在 `orchestra_loader.lua` 中添加到 modules 列表：

```lua
local modules = {
    "file_manager",
    "json_manager",
    "track",
    "media",
    "project",
    "dispatcher",
    "logger",
    "effects"  -- 新模块
}
```

## 协议支持

完全兼容原始的 Orchestra File IPC Protocol v1：

-   ✅ 原子文件操作
-   ✅ .part/.req/.reply 后缀规范
-   ✅ 单消费者语义
-   ✅ 错误处理机制

## 性能优势

1. **模块化**：按需加载，减少内存占用
2. **非阻塞**：reaper.defer 提升界面响应
3. **专业库**：外部 JSON 库提升性能
4. **表分派**：O(1)查找替代 O(n)if 链

这个新架构解决了原版代码的所有问题，提供了更好的可维护性、扩展性和性能。
