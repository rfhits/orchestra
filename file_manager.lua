-- File Manager Module
-- 文件系统操作封装

local M = {}
local orchestra_dir = nil
local inbox_dir = nil
local outbox_dir = nil
local archive_dir = nil

-- 引入配置模块
local config = require("config")

function M.init_directories()
    local dirs = config.get_directories()
    orchestra_dir = dirs.orchestra
    inbox_dir = dirs.inbox
    outbox_dir = dirs.outbox
    archive_dir = dirs.archive

    M.info("Initializing directories...")
    M.info("Orchestra dir: " .. orchestra_dir)
    M.info("Inbox dir: " .. inbox_dir)
    M.info("Outbox dir: " .. outbox_dir)
    M.info("Archive dir: " .. archive_dir)

    -- 创建必要目录
    -- 因为 lua 没有文件系统 api 支持，所以用 reaper 方便
    config.init_directories()

    -- 验证目录是否成功创建
    local function check_dir_exists(dir_path, dir_name)
        local test_file = io.open(dir_path .. "/.test_write", "w")
        if test_file then
            test_file:close()
            os.remove(dir_path .. "/.test_write")
            M.info(dir_name .. " directory is writable: " .. dir_path)
            return true
        else
            M.error("Cannot write to " .. dir_name .. " directory: " .. dir_path)
            return false
        end
    end

    -- 验证所有目录
    local all_dirs_ok = true
    all_dirs_ok = check_dir_exists(orchestra_dir, "Orchestra") and all_dirs_ok
    all_dirs_ok = check_dir_exists(inbox_dir, "Inbox") and all_dirs_ok
    all_dirs_ok = check_dir_exists(outbox_dir, "Outbox") and all_dirs_ok
    all_dirs_ok = check_dir_exists(archive_dir, "Archive") and all_dirs_ok

    if all_dirs_ok then
        M.info("All directories initialized successfully")
    else
        M.error("Some directories failed to initialize properly")
    end
end

function M.info(message)
    reaper.ShowConsoleMsg("[FileManager] " .. message .. "\n")
end

function M.error(message)
    reaper.ShowConsoleMsg("[FileManager ERROR] " .. message .. "\n")
end

function M.warn(message)
    reaper.ShowConsoleMsg("[FileManager WARN] " .. message .. "\n")
end

-- 使用操作系统 API 列出 inbox 中的 .json 文件（忽略 .part 文件）
function M.list_pending_requests()
    local files = {}    -- 存储符合条件的文件名
    local fileindex = 0 -- 从索引0开始遍历

    -- 循环遍历所有文件：直到 EnumerateFiles 返回 nil 停止
    -- 强制刷新，防止缓存问题
    reaper.EnumerateFiles(inbox_dir, -1)
    while true do
        -- 按索引获取文件名：返回字符串（文件名）或 nil（遍历完毕）
        local filename = reaper.EnumerateFiles(inbox_dir, fileindex)

        -- 终止条件：没有更多文件了
        if not filename then
            break
        end

        -- 过滤条件：是 .json 文件 且 不是 .part 文件
        -- 正则解释：%.json$ 匹配以 .json 结尾；%.part$ 匹配以 .part 结尾
        local is_json = filename:match("%.json$")
        local is_part = filename:match("%.part$")
        if is_json and not is_part then
            table.insert(files, filename) -- 符合条件则加入列表
            M.info("Found pending request: " .. filename)
        end

        fileindex = fileindex + 1 -- 索引自增，遍历下一个文件
    end

    -- M.info("Total pending requests found: " .. #files)
    return files -- 返回所有符合条件的 .json 文件名列表
end

-- 原子认领请求文件
function M.claim_request(filename)
    local source_path = inbox_dir .. "/" .. filename
    local job_id = filename:gsub("%.json$", "")
    local target_path = outbox_dir .. "/" .. job_id .. ".req.json"

    M.info("Attempting to claim request: " .. filename)

    -- 检查源文件是否存在
    local source_file = io.open(source_path, "r")
    if not source_file then
        M.info("Source file does not exist: " .. source_path)
        return nil, nil
    end
    source_file:close()

    -- 尝试移动文件（原子操作）
    local success = os.rename(source_path, target_path)
    if success then
        M.info("Successfully claimed request: " .. job_id)
        return target_path, job_id
    else
        M.info("Failed to claim request: " .. filename)
        -- 详细调试信息
        local target_file = io.open(target_path, "r")
        if target_file then
            M.info("Target file already exists: " .. target_path)
            target_file:close()
        end
        return nil, nil
    end
end

-- 原子写入回复文件
function M.write_reply(job_id, reply_content)
    local part_path = outbox_dir .. "/" .. job_id .. ".reply.json.part"
    local final_path = outbox_dir .. "/" .. job_id .. ".reply.json"

    M.info("Writing reply for job: " .. job_id)

    -- 写入 .part 文件
    local file = io.open(part_path, "w")
    if not file then
        M.error("Cannot write reply file for job: " .. job_id)
        return false
    end

    file:write(reply_content)
    file:close()

    -- 原子重命名到最终文件
    local success = os.rename(part_path, final_path)
    if success then
        M.info("Successfully wrote reply for job: " .. job_id)
    else
        M.error("Failed to finalize reply file for job: " .. job_id)
    end
    return success
end

-- 读取请求文件
function M.read_request(file_path)
    local file = io.open(file_path, "r")
    if not file then
        return nil, "Cannot open request file"
    end

    local content = file:read("*a")
    file:close()

    return content, nil
end

-- 删除已处理的请求文件
function M.cleanup_request(job_id)
    local req_path = outbox_dir .. "/" .. job_id .. ".req.json"
    local reply_path = outbox_dir .. "/" .. job_id .. ".reply.json"

    -- 清理请求文件
    local req_success = os.remove(req_path)
    if req_success then
        M.info("Cleaned up request file: " .. job_id)
    else
        M.warn("Failed to cleanup request file: " .. job_id)
        -- 尝试检查文件是否存在
        local file = io.open(req_path, "r")
        if file then
            file:close()
            M.warn("Request file still exists: " .. req_path)
        else
            M.info("Request file already removed: " .. job_id)
        end
    end

    -- 清理回复文件（可选，保留一段时间）
    local reply_success = os.remove(reply_path)
    if reply_success then
        M.info("Cleaned up reply file: " .. job_id)
    end

    return req_success
end

-- 强制清理所有已处理的文件
function M.force_cleanup()
    M.info("Performing force cleanup of processed files")

    -- 清理outbox中所有的.reply.json文件（保留24小时以上的）
    local fileindex = 0
    while true do
        local filename = reaper.EnumerateFiles(outbox_dir, fileindex)
        if not filename then
            break
        end

        if filename:match("%.reply%.json$") then
            local file_path = outbox_dir .. "/" .. filename
            local success = os.remove(file_path)
            if success then
                M.info("Force cleaned up old reply file: " .. filename)
            end
        end

        fileindex = fileindex + 1
    end
end

-- 获取目录路径
function M.get_directories()
    return {
        orchestra = orchestra_dir,
        inbox = inbox_dir,
        outbox = outbox_dir,
        archive = archive_dir
    }
end

return M
