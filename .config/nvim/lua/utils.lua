local M = {}

function M.prequire(...)
    local status, lib = pcall(require, ...)
    if status then
        return lib
    end
    return nil
end

function M.map(mode, lhs, rhs, opts)
    local options = { noremap = true, silent = true }
    if opts then
        options = vim.tbl_extend('force', options, opts)
    end
    vim.api.nvim_set_keymap(mode, lhs, rhs, options)
end

return M
