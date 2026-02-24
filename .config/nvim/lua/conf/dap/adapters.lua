---@class conf.dap.AdapterRegistry
---@field register fun(filetype: string, module: string)
---@field load fun(filetype: string): boolean
---@field load_project fun()

---@type table<string, string>
local modules_by_filetype = {}
---@type table<string, boolean>
local loaded_filetypes = {}

---@type conf.dap.AdapterRegistry
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

return registry
