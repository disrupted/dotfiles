local M = {}

M.async = {
    ---@async
    ---@param path string
    ---@return string? content
    read = function(path)
        local err_stat, stat = require('coop.uv').fs_stat(path)
        assert(not err_stat, err_stat)
        assert(stat)
        local err_open, fd = require('coop.uv').fs_open(path, 'r', 438)
        assert(not err_open, err_open)
        assert(fd)
        local err_read, content = require('coop.uv').fs_read(fd, stat.size)
        assert(not err_read, err_read)
        local err_close = require('coop.uv').fs_close(fd)
        assert(not err_close, err_close)
        return content
    end,
    ---@async
    ---@param path string
    ---@param content string
    write = function(path, content)
        local err_open, fd = require('coop.uv').fs_open(path, 'w', 438)
        assert(not err_open, err_open)
        assert(fd)
        local err_write = require('coop.uv').fs_write(fd, content, 0)
        assert(not err_write, err_write)
        local err_close = require('coop.uv').fs_close(fd)
        assert(not err_close, err_close)
    end,
}

---@param path string
---@return string? content
M.read = function(path)
    local stat, err_stat = vim.uv.fs_stat(path)
    assert(not err_stat, err_stat)
    assert(stat)
    local fd, err_open = vim.uv.fs_open(path, 'r', 438)
    assert(not err_open, err_open)
    assert(fd)
    local content, err_read = vim.uv.fs_read(fd, stat.size)
    assert(not err_read, err_read)
    local _, err_close = vim.uv.fs_close(fd)
    assert(not err_close, err_close)
    return content
end

---@param path string
---@param content string
M.write = function(path, content)
    local fd, err_open = vim.uv.fs_open(path, 'w', 438)
    assert(not err_open, err_open)
    assert(fd)
    local _, err_write = vim.uv.fs_write(fd, content, 0)
    assert(not err_write, err_write)
    local _, err_close = vim.uv.fs_close(fd)
    assert(not err_close, err_close)
end

return M
