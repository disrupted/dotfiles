---@class conf.dap.AdapterRegistry
---@field register fun(filetype: string, module: string)
---@field load fun(filetype: string): boolean
---@field load_project fun()

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

---@type conf.dap.AdapterRegistry
return {
    register = register,
    load = load,
    load_project = load_project,
}
