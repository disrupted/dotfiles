local M = {}

--- Check whether the current buffer is empty
function M.is_buffer_empty()
    return vim.fn.empty(vim.fn.expand '%:t') == 1
end

--- Check if the windows width is greater than a given number of columns
function M.has_width_gt(cols)
    return vim.fn.winwidth(0) / 2 > cols
end

return M
