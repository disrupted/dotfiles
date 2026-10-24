---@class conf.neotest.AdapterRegistry
---@field register fun(filetype: string, module: string)
---@field load fun(filetype: string): boolean
---@field load_project fun()
---@field attach fun(adapter: table): table

---@type table<string, string>
local modules_by_filetype = {}
---@type table<string, boolean>
local loaded_filetypes = {}

---@param filetype string
---@param module string
local function register(filetype, module)
    modules_by_filetype[filetype] = module
    loaded_filetypes[filetype] = nil
end

---@param filetype string
---@return boolean
local function load(filetype)
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

local function load_project()
    local filetypes = require('conf.workspace').project_filetypes()
    for _, filetype in ipairs(filetypes) do
        load(filetype)
    end
end

---@param adapter table
---@return table
local function attach(adapter)
    ---@type table[]
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

---@type conf.neotest.AdapterRegistry
return {
    register = register,
    load = load,
    load_project = load_project,
    attach = attach,
}
