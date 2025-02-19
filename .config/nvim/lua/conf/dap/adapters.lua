---@type table<string, string>
local adapters = {}

---@alias proxy table<string, any>
---@type proxy
local proxy = {}

return setmetatable(proxy, {
    ---@param t proxy
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
