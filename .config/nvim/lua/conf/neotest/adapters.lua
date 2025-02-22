---@type table<string, string>
local adapters = {}

local proxy = {}

return setmetatable(proxy, {
    ---@param t table<string, any>
    ---@param key string
    __index = function(t, key)
        local adapter = adapters[key]
        if adapter then
            local module = require(adapter)
            rawset(t, key, module) -- store module for future access
            return module
        end
    end,
    ---@param key string
    ---@param value string
    __newindex = function(_, key, value)
        adapters[key] = value
    end,
})
