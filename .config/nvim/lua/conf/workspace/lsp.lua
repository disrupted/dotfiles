--- Eagerly start LSP clients for the whole project, without opening a buffer
--- first (e.g. for workspace symbols or workspace diagnostics).
---
--- In a mise monorepo every config root (backend/, frontend/) is checked, and
--- each server resolves its root and availability through its own `root_dir`.
local M = {}

local project = require('conf.project')

---@param config vim.lsp.Config
---@param root string
---@return integer? client_id
local function start(config, root)
    for _, client in ipairs(vim.lsp.get_clients({ name = config.name })) do
        if client.root_dir == root and not client:is_stopped() then
            return client.id
        end
    end
    config = vim.deepcopy(config)
    config.root_dir = root
    Snacks.notify.info(
        ('Starting %s [%s]'):format(config.name, vim.fn.fnamemodify(root, ':~')),
        { title = 'LSP' }
    )
    return vim.lsp.start(config, { attach = false })
end

--- Resolve the root of `config` for `dir`; calls exactly one of the callbacks.
---@param config vim.lsp.Config
---@param dir string
---@param on_root fun(root: string)
---@param on_skip fun()
local function resolve(config, dir, on_root, on_skip)
    local root_dir = config.root_dir
    if type(root_dir) == 'function' then
        if project.accepts_path(root_dir) then
            local path_root_dir = root_dir --[[@as fun(source: string, on_dir: fun(root: string), on_skip: fun())]]
            path_root_dir(dir, on_root, on_skip)
        else
            on_skip() -- foreign root_dir functions need a buffer
        end
        return
    end
    local cmd = config.cmd
    if type(cmd) ~= 'table' or not cmd[1] or vim.fn.executable(cmd[1]) == 0 then
        on_skip()
        return
    end
    if type(root_dir) == 'string' then
        on_root(root_dir)
    elseif config.root_markers and not vim.tbl_isempty(config.root_markers) then
        local root = vim.fs.root(dir, config.root_markers)
        if root then
            on_root(root)
        else
            on_skip()
        end
    else
        on_root(dir)
    end
end

--- Enabled configs for a filetype.
---@param filetype string
---@return vim.lsp.Config[]
local function enabled_configs(filetype)
    local configs = {}
    for name in vim.spairs(vim.lsp._enabled_configs) do
        local config = vim.lsp.config[name]
        if config and vim.list_contains(config.filetypes or {}, filetype) then
            configs[#configs + 1] = config
        end
    end
    return configs
end

--- Start the first available config of `names` for `dir`.
---@param names string[]
---@param dir string
---@param done fun(client_id?: integer)
local function start_first(names, dir, done)
    local i = 0
    local function try_next()
        i = i + 1
        local name = names[i]
        if not name then
            done(nil)
            return
        end
        local config = vim.lsp.is_enabled(name) and vim.lsp.config[name] or nil
        if not config then
            try_next()
            return
        end
        resolve(config, dir, function(root)
            done(start(config, root))
        end, try_next)
    end
    try_next()
end

--- Start all available configs of `filetype` for `dir`.
---@param filetype string
---@param dir string
---@param done fun(client_ids: integer[])
local function start_all(filetype, dir, done)
    local configs = enabled_configs(filetype)
    local pending = #configs
    local ids = {}
    if pending == 0 then
        done(ids)
        return
    end
    local function settle(id)
        ids[#ids + 1] = id
        pending = pending - 1
        if pending == 0 then
            done(ids)
        end
    end
    for _, config in ipairs(configs) do
        resolve(config, dir, function(root)
            settle(start(config, root))
        end, function()
            settle(nil)
        end)
    end
end

---@type table<string, fun(dir: string, done: fun(client_ids: integer[]))>
local starters = {
    python = function(dir, done)
        start_first({ 'ty', 'pyrefly', 'basedpyright', 'pyright' }, dir, function(id)
            done({ id })
        end)
    end,
    rust = function(dir, done)
        local root = vim.fs.root(dir, { 'Cargo.toml' })
        if not root then
            done({})
            return
        end
        require('rustaceanvim')
        require('rustaceanvim.lsp').start()
        local config = vim.tbl_extend(
            'keep',
            vim.lsp.config['rust-analyzer'] or {},
            { name = 'rust-analyzer', cmd = { 'rust-analyzer' } }
        ) --[[@as vim.lsp.Config]]
        done({ start(config, root) })
    end,
}

--- Start clients for all project filetypes in every project directory.
--- Non-blocking: `on_done` receives the ids of started (or already running)
--- clients once every server has been resolved.
---@param on_done? fun(client_ids: integer[])
M.start_project_clients = function(on_done)
    on_done = on_done or function() end
    local filetypes = require('conf.workspace').project_filetypes({ buffers = false })
    local dirs = project.dirs()
    local pending = #filetypes * #dirs
    local started = {} ---@type integer[]
    if pending == 0 then
        on_done(started)
        return
    end
    for _, filetype in ipairs(filetypes) do
        for _, dir in ipairs(dirs) do
            local starter = starters[filetype]
                or function(d, done)
                    start_all(filetype, d, done)
                end
            starter(dir, function(ids)
                for _, id in pairs(ids) do
                    if id and not vim.list_contains(started, id) then
                        started[#started + 1] = id
                    end
                end
                pending = pending - 1
                if pending == 0 then
                    on_done(started)
                end
            end)
        end
    end
end

return M
