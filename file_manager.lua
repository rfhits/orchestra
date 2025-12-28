-- File Manager Module
-- 文件系统操作封装

local M = {}
local orchestra_dir = nil
local inbox_dir = nil
local outbox_dir = nil
local archive_dir = nil

function M.init_directories()
    orchestra_dir = reaper.GetResourcePath() .. "/.orchestra"
    inbox_dir = orchestra_dir .. "/inbox"
    outbox_dir = orchestra_dir .. "/outbox"
    archive_dir = orchestra_dir .. "/archive"

    -- 创建必要目录
    -- 因为 lua 没有文件系统 api 支持，所以用 reaper 方便
    reaper.RecursiveCreateDirectory(orchestra_dir, 0)
    reaper.RecursiveCreateDirectory(inbox_dir, 0)
    reaper.RecursiveCreateDirectory(outbox_dir, 0)
    reaper.RecursiveCreateDirectory(archive_dir, 0)

    M.info("Directories initialized")
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
        end

        fileindex = fileindex + 1 -- 索引自增，遍历下一个文件
    end

    return files -- 返回所有符合条件的 .json 文件名列表
end

-- 原子认领请求文件
function M.claim_request(filename)
    local source_path = inbox_dir .. "/" .. filename
    local job_id = filename:gsub("%.json$", "")
    local target_path = outbox_dir .. "/" .. job_id .. ".req.json"

    M.info("Attempting to claim request: " .. filename)

    -- 尝试移动文件（原子操作）
    local success = os.rename(source_path, target_path)
    if success then
        M.info("Successfully claimed request: " .. job_id)
        return target_path, job_id
    else
        M.info("Failed to claim request: " .. filename)
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
    local success = os.remove(req_path)
    if success then
        M.info("Cleaned up request file: " .. job_id)
    else
        M.warn("Failed to cleanup request file: " .. job_id)
    end
    return success
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
