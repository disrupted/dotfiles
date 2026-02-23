---@class conf.neotest.AdapterRegistry
---@field register fun(filetype: string, module: string)
---@field load fun(filetype: string): boolean
---@field load_project fun()
---@field attach fun(adapter: table): table

---@type table<string, string>
local modules_by_filetype = {}
---@type table<string, boolean>
local loaded_filetypes = {}

---@type conf.neotest.AdapterRegistry
local registry = {}

---@param filetype string
---@param module string
function registry.register(filetype, module)
    modules_by_filetype[filetype] = module
    loaded_filetypes[filetype] = nil
end

---@param filetype string
---@return boolean
function registry.load(filetype)
    if loaded_filetypes[filetype] then
        return true
    end

    local module = modules_by_filetype[filetype]
    if not module then
        return false
    end

    loaded_filetypes[filetype] = true
    local ok = pcall(require, module)
    if not ok then
        loaded_filetypes[filetype] = nil
    end
    return ok
end

function registry.load_project()
    local filetypes = require('conf.workspace').project_filetypes()
    for _, filetype in ipairs(filetypes) do
        registry.load(filetype)
    end
end

---@param adapter table
---@return table
function registry.attach(adapter)
    local adapters = require('neotest.config').adapters
    local adapter_id = adapter.adapter_id or adapter.name
    for _, existing in ipairs(adapters) do
        if existing == adapter then
            return existing
        end
        local existing_adapter_id = existing.adapter_id or existing.name
        if
            adapter_id ~= nil
            and existing_adapter_id ~= nil
            and existing_adapter_id == adapter_id
        then
            return existing
        end
    end
    table.insert(adapters, adapter)
    return adapter
end

return setmetatable(registry, {
    ---@param t table<string, any>
    ---@param key string
    __index = function(t, key)
        local value = rawget(t, key)
        if value ~= nil then
            return value
        end
        if registry.load(key) then
            return package.loaded[modules_by_filetype[key]]
        end
    end,
    ---@param _ table<string, any>
    ---@param key string
    ---@param value string
    __newindex = function(_, key, value)
        registry.register(key, value)
    end,
})
