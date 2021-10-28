local M = {}

function M.prequire(...)
    local status, lib = pcall(require, ...)
    if status then
        return lib
    end
    return nil
end

-- only actually `require()`s a module when it gets used
-- from feline.nvim
function M.lazy_require(module)
    local mt = {}

    mt.__index = function(_, key)
        if not mt._module then
            mt._module = require(module)
        end

        return mt._module[key]
    end

    mt.__newindex = function(_, key, val)
        if not mt._module then
            mt._module = require(module)
        end

        mt._module[key] = val
    end

    mt.__metatable = false

    return setmetatable({}, mt)
end

function M.map(mode, lhs, rhs, opts)
    local options = { noremap = true, silent = true }
    if opts then
        options = vim.tbl_extend('force', options, opts)
    end
    vim.api.nvim_set_keymap(mode, lhs, rhs, options)
end

return M
