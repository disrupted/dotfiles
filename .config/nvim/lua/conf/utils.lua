local M = {}

--- Check whether the current buffer is empty
function M.is_buffer_empty()
    return vim.fn.empty(vim.fn.expand '%:t') == 1
end

--- Check if the windows width is greater than a given number of columns
function M.has_width_gt(cols)
    return vim.fn.winwidth(0) / 2 > cols
end

---@param path string
---@return string?
function M.dir(path)
    return vim.uv.fs_stat(vim.fs.normalize(path)) and path
end

---@param path string
---@return boolean?
function M.dev(path)
    return M.dir(path) and true
end

return M
