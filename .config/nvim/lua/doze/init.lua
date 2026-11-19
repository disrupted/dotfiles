--- Declarative lazy-loading on top of vim.pack. Owes a lot to laze: https://github.com/sys9kdr/laze
local M = {}

---@param specs doze.Spec[]
function M.setup(specs)
    local loader = require('doze.loader')
    local build = require('doze.build')
    if #loader.list > 0 then
        error('doze: setup() already ran', 0)
    end
    local plugins = loader.register(specs)

    -- PackChanged fires inside vim.pack.add() for fresh installs, so the subscription must come first.
    build.subscribe(loader.plugins)

    local eager, lazy = {}, {}
    for _, plugin in ipairs(plugins) do
        local spec = plugin.spec
        local pack = {
            src = spec.src,
            name = plugin.name,
            version = spec.version,
            data = spec.data,
        }
        table.insert(
            (spec.lazy == false and loader.enabled(plugin)) and eager or lazy,
            pack
        )
    end
    if #eager > 0 then
        vim.pack.add(eager, { load = false })
    end
    if #lazy > 0 then
        vim.pack.add(lazy, { load = function() end })
    end
    build.wait()
    loader.install_searcher()

    for _, plugin in ipairs(plugins) do
        if plugin.spec.init and loader.enabled(plugin) then
            local ok, err = pcall(plugin.spec.init, plugin)
            if not ok then
                loader.warn(('init of %s failed: %s'):format(plugin.name, err))
            end
        end
    end

    ---@type doze.Plugin[]
    local startup = vim.tbl_filter(function(plugin)
        return plugin.spec.lazy == false
    end, plugins)
    ---@type table<doze.Plugin, integer>
    local order = {}
    for i, plugin in ipairs(startup) do
        order[plugin] = i
    end
    table.sort(startup, function(a, b)
        local pa, pb = a.spec.priority or 50, b.spec.priority or 50
        if pa ~= pb then
            return pa > pb
        end
        return order[a] < order[b]
    end)
    for _, plugin in ipairs(startup) do
        loader.load(plugin.name)
    end

    require('doze.handlers').setup(plugins)
end

return M
