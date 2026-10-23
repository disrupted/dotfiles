local M = {}

---@param modname string
function M.prequire(modname)
    local ok, lib = pcall(require, modname)
    if ok then
        return lib
    end
    return nil
end

-- only actually `require()`s a module when it gets used
-- from feline.nvim
---@param modname string
function M.lazy_require(modname)
    local mt = {}

    mt.__index = function(_, key)
        if not mt._module then
            mt._module = require(modname)
        end

        return mt._module[key]
    end

    mt.__newindex = function(_, key, val)
        if not mt._module then
            mt._module = require(modname)
        end

        mt._module[key] = val
    end

    mt.__metatable = false

    return setmetatable({}, mt)
end

return M
