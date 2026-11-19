local M = {}

---@type table<string, doze.Plugin>
M.plugins = {}
---@type doze.Plugin[]
M.list = {}

local function warn(msg)
    vim.notify('doze: ' .. msg, vim.log.levels.WARN)
end
M.warn = warn

---@param src string
---@return string
local function default_name(src)
    local name = src:gsub('/+$', ''):gsub('%.git$', ''):match('[^/]+$')
    return name or src
end

local FIELDS = {}
for _, field in ipairs({
    'src',
    'name',
    'version',
    'data',
    'lazy',
    'enabled',
    'priority',
    'dependencies',
    'event',
    'ft',
    'cmd',
    'keys',
    'init',
    'config',
    'build',
}) do
    FIELDS[field] = true
end

---@param specs doze.Spec[]
---@return doze.Plugin[]
function M.register(specs)
    local root = vim.fs.joinpath(vim.fn.stdpath('data'), 'site', 'pack', 'core', 'opt')
    local errors = {}
    for i, spec in ipairs(specs) do
        if type(spec.src) ~= 'string' then
            table.insert(errors, ('spec #%d has no `src`'):format(i))
        else
            local name = spec.name or default_name(spec.src)
            for field in pairs(spec) do
                if not FIELDS[field] then
                    table.insert(
                        errors,
                        ('%s has unknown field `%s`'):format(name, field)
                    )
                end
            end
            if M.plugins[name] then
                table.insert(errors, ('duplicate plugin name %s'):format(name))
            else
                local plugin =
                    { name = name, path = vim.fs.joinpath(root, name), spec = spec }
                M.plugins[name] = plugin
                table.insert(M.list, plugin)
            end
        end
    end
    for _, plugin in ipairs(M.list) do
        for _, dep in ipairs(plugin.spec.dependencies or {}) do
            if not M.plugins[dep] then
                table.insert(
                    errors,
                    ('%s depends on undeclared %s'):format(plugin.name, dep)
                )
            end
        end
    end
    if #errors > 0 then
        error('doze: ' .. table.concat(errors, '; '), 0)
    end
    return M.list
end

---@param plugin doze.Plugin
---@return boolean
function M.enabled(plugin)
    return plugin.spec.enabled ~= false
end

---@param path string
---@return string[]
local function top_modules(path)
    local mods = {}
    for name, kind in vim.fs.dir(vim.fs.joinpath(path, 'lua')) do
        if kind == 'file' and name:sub(-4) == '.lua' then
            table.insert(mods, name:sub(1, -5))
        elseif kind == 'directory' or kind == 'link' then
            table.insert(mods, name)
        end
    end
    table.sort(mods)
    return mods
end

---@type doze.Plugin[]
local after_queue = {}

---@param files string[]
---@param sourced table<string, true>
local function source(files, sourced)
    for _, file in ipairs(files) do
        -- Neovim records sourced scripts by their resolved path.
        local real = vim.uv.fs_realpath(file) or file
        if not sourced[real] then
            sourced[real] = true
            local ok, err = pcall(vim.cmd.source, vim.fn.fnameescape(file))
            if not ok then
                warn(tostring(err))
            end
        end
    end
end

---@param dir string
---@param patterns string[]
---@return string[]
local function glob(dir, patterns)
    local files = {}
    for _, pattern in ipairs(patterns) do
        local found = vim.fn.glob(dir .. pattern, false, true)
        table.sort(found)
        vim.list_extend(files, found)
    end
    return files
end

-- A plugin loaded from another plugin's plugin/ file or a startup autocmd may already be sourced by Neovim's own
-- startup passes, which run on whatever is on 'runtimepath' at the time.
---@return table<string, true>
local function sourced_scripts()
    local sourced = {}
    for _, script in ipairs(vim.fn.getscriptinfo()) do
        sourced[script.name] = true
    end
    return sourced
end

---@param plugin doze.Plugin
local function source_after(plugin)
    source(
        glob(plugin.path, { '/after/plugin/**/*.vim', '/after/plugin/**/*.lua' }),
        sourced_scripts()
    )
end

-- Before load-plugins, Neovim sources everything on 'runtimepath' itself; doing it here would run it twice.
---@param plugin doze.Plugin
local function source_runtime(plugin)
    if vim.v.vim_did_init == 0 then
        return
    end
    source(
        glob(plugin.path, {
            '/plugin/**/*.vim',
            '/plugin/**/*.lua',
            '/ftdetect/*.vim',
            '/ftdetect/*.lua',
        }),
        sourced_scripts()
    )
    if vim.v.vim_did_enter == 1 then
        source_after(plugin)
    else
        -- Neovim's after/plugin pass may still be ahead; VimEnter sources whatever it left out.
        if #after_queue == 0 then
            vim.api.nvim_create_autocmd('VimEnter', {
                once = true,
                callback = function()
                    for _, queued in ipairs(after_queue) do
                        source_after(queued)
                    end
                    after_queue = {}
                end,
            })
        end
        table.insert(after_queue, plugin)
    end
end

---@param plugin doze.Plugin
local function configure(plugin)
    local config = plugin.spec.config
    if not config then
        return
    end
    local ok, err = pcall(config, plugin)
    if not ok then
        warn(('config of %s failed: %s'):format(plugin.name, err))
    end
end

-- All directories of the tree go on 'runtimepath' before any of it sources: a dependency's after/plugin may require
-- its parent (cmp sources register into nvim-cmp).
---@param name string
function M.load(name)
    local root = M.plugins[name]
    if not root or root.state or not M.enabled(root) then
        return
    end

    ---@type doze.Plugin[]
    local tree = {}
    local seen = {}
    ---@param plugin doze.Plugin
    local function visit(plugin)
        if seen[plugin.name] or plugin.state then
            return
        end
        seen[plugin.name] = true
        for _, dep in ipairs(plugin.spec.dependencies or {}) do
            local dep_plugin = M.plugins[dep]
            if dep_plugin and M.enabled(dep_plugin) then
                visit(dep_plugin)
            elseif dep_plugin then
                warn(('%s depends on disabled %s'):format(plugin.name, dep))
            end
        end
        table.insert(tree, plugin)
    end
    visit(root)

    for _, plugin in ipairs(tree) do
        plugin.state = 'loading'
        local ok, err = pcall(vim.cmd.packadd, { plugin.name, bang = true })
        if not ok then
            warn(('cannot load %s: %s'):format(plugin.name, err))
        end
    end
    for _, plugin in ipairs(tree) do
        source_runtime(plugin)
        configure(plugin)
        plugin.state = 'loaded'
    end
end

---@type table<string, doze.Plugin[]>?
local module_index

---@return table<string, doze.Plugin[]>
local function build_index()
    local index = {}
    for _, plugin in ipairs(M.list) do
        if M.enabled(plugin) then
            for _, mod in ipairs(top_modules(plugin.path)) do
                index[mod] = index[mod] or {}
                table.insert(index[mod], plugin)
            end
        end
    end
    return index
end

-- Several plugins can share a top-level module (`lua/telescope/_extensions/…`), so the file decides the owner.
---@param plugin doze.Plugin
---@param modname string
---@return boolean
local function provides(plugin, modname)
    local base = vim.fs.joinpath(plugin.path, 'lua', (modname:gsub('%.', '/')))
    return vim.uv.fs_stat(base .. '.lua') ~= nil
        or vim.uv.fs_stat(base .. '/init.lua') ~= nil
end

-- Appended to package.loaders, so it only runs for a require every other loader missed.
---@param modname string
---@return (fun(name: string): any)?
local function searcher(modname)
    module_index = module_index or build_index()
    for _, plugin in ipairs(module_index[modname:match('^[^.]+')] or {}) do
        if not plugin.state and provides(plugin, modname) then
            return function(name)
                -- require holds a sentinel in package.loaded while this loader runs; the require below needs it gone.
                package.loaded[name] = nil
                M.load(plugin.name)
                return require(name)
            end
        end
    end
end

function M.install_searcher()
    if not vim.list_contains(package.loaders, searcher) then
        table.insert(package.loaders, searcher)
    end
end

return M
