--- Project structure derived from mise.
---
--- A project is the workspace root (`vim.g.workspace_root`, usually the Git
--- work tree root). In a mise monorepo (`monorepo_root = true`) it is split
--- into config roots (`[monorepo] config_roots`), each with its own mise
--- environment (tools, venv, node_modules).
---
--- Principle: cwd is for humans and pickers; tools derive their root from the
--- file path via `of()` and run inside that root's environment via `exec()`.
local M = {}

---@type string[]? absolute config roots; nil until loaded
local roots = nil
---@type string? workspace root the cached roots belong to
local roots_for = nil
---@type integer generation counter to drop stale async results
local generation = 0

---@param root string
---@return string[]
local function cmd(root)
    return { 'mise', '-C', root, 'config', 'get', 'monorepo.config_roots' }
end

--- Parse `mise config get monorepo.config_roots` output into absolute paths.
---@param root string workspace root
---@param out vim.SystemCompleted
---@return string[]
function M._parse(root, out)
    if out.code ~= 0 or not out.stdout or vim.trim(out.stdout) == '' then
        return {} -- not a monorepo, mise missing or config untrusted
    end
    local ok, decoded = pcall(vim.json.decode, out.stdout)
    if not ok or type(decoded) ~= 'table' then
        return {}
    end
    local result = {}
    for _, rel in ipairs(decoded) do
        if type(rel) == 'string' and rel ~= '' then
            result[#result + 1] = vim.fs.normalize(vim.fs.joinpath(root, rel))
        end
    end
    return result
end

---@param root string
---@param value string[]
local function store(root, value)
    roots, roots_for = value, root
    vim.g.project_roots = value
    vim.api.nvim_exec_autocmds('User', { pattern = 'ProjectRoots', modeline = false })
end

--- Resolve config roots in the background. Fires `User ProjectRoots` when done.
---@param root? string defaults to vim.g.workspace_root
function M.load(root)
    root = root or vim.g.workspace_root
    if not root or vim.fn.executable('mise') == 0 then
        return
    end
    generation = generation + 1
    local gen = generation
    vim.async.run(function()
        local out = require('conf.async').system(cmd(root), { text = true })
        if gen == generation and root == vim.g.workspace_root then
            store(root, M._parse(root, out))
        end
    end)
end

--- Config roots (absolute). Non-blocking once loaded; before that, falls back
--- to a short blocking call so callers never act on incomplete information.
---@return string[]
function M.roots()
    local root = vim.g.workspace_root
    if not root then
        return {}
    end
    if roots and roots_for == root then
        return roots
    end
    if vim.fn.executable('mise') == 0 then
        store(root, {})
        return {}
    end
    generation = generation + 1 -- supersede in-flight async load
    local out = vim.system(cmd(root), { text = true }):wait(1000)
    store(root, M._parse(root, out))
    return roots --[[@as string[] ]]
end

---@return boolean
function M.is_monorepo()
    return #M.roots() > 0
end

--- Workspace root followed by all config roots: the directories in which
--- project markers (pyproject.toml, package.json, ...) are looked up.
---@return string[]
function M.dirs()
    local root = vim.g.workspace_root
    if not root then
        return {}
    end
    local dirs = { root }
    vim.list_extend(dirs, M.roots())
    return dirs
end

--- Innermost config root containing `path`, else the workspace root.
---@param path string absolute file or directory path
---@param candidates? string[] defaults to M.roots()
---@return string?
function M.of(path, candidates)
    path = vim.fs.normalize(path)
    local best = nil ---@type string?
    for _, root in ipairs(candidates or M.roots()) do
        if vim.fs.relpath(root, path) and (not best or #root > #best) then
            best = root
        end
    end
    return best or vim.g.workspace_root
end

--- Wrap `command` so it runs in the mise environment of `root`.
--- No-op for the workspace root itself: Neovim already inherits that env.
---@param root string
---@param command string[]
---@return string[]
function M.exec(root, command)
    if root == vim.g.workspace_root or vim.fn.executable('mise') == 0 then
        return command
    end
    return vim.list_extend({ 'mise', '-C', root, 'exec', '--' }, command)
end

---@type table<string, table<string, string>|false> root -> env (false: failed)
local envs = {}
---@type table<string, fun(env: table<string, string>?)[]> pending callbacks
local env_waiters = {}

--- Resolved mise environment of a config root (`mise env --json`), cached.
--- Used to look up executables; processes are spawned via `exec()`.
---@param root string
---@param cb fun(env: table<string, string>?) called on the main loop
function M.env(root, cb)
    local cached = envs[root]
    if cached ~= nil then
        cb(cached or nil)
        return
    end
    if env_waiters[root] then
        table.insert(env_waiters[root], cb)
        return
    end
    local waiters = { cb }
    env_waiters[root] = waiters
    vim.async.run(function()
        local out = require('conf.async').system(
            { 'mise', '-C', root, 'env', '--json' },
            { text = true }
        )
        local ok, env = false, nil
        if out.code == 0 and out.stdout then
            ok, env = pcall(vim.json.decode, out.stdout)
        end
        envs[root] = ok and type(env) == 'table' and env or false
        env_waiters[root] = nil
        for _, waiter in ipairs(waiters) do
            waiter(envs[root] or nil)
        end
    end)
end

---@param bin string
---@param path string PATH-style list
---@return string?
local function search_path(bin, path)
    for dir in vim.gsplit(path, ':', { plain = true, trimempty = true }) do
        local candidate = vim.fs.joinpath(dir, bin)
        if vim.uv.fs_access(candidate, 'X') then
            return candidate
        end
    end
end

--- Find `bin` in the environment of `root`: Neovim's own PATH for the
--- workspace root, the root's mise env for monorepo config roots.
---@param root string
---@param bin string
---@param cb fun(path: string?) called on the main loop
function M.executable(root, bin, cb)
    if root == vim.g.workspace_root or vim.fn.executable('mise') == 0 then
        local path = vim.fn.exepath(bin)
        cb(path ~= '' and path or nil)
        return
    end
    M.env(root, function(env)
        cb(env and env.PATH and search_path(bin, env.PATH) or nil)
    end)
end

--- `cmd` for vim.lsp.Config: spawn the server in the mise env of the config
--- root that contains the client's root_dir.
---@param command string[]
---@return fun(dispatchers: vim.lsp.rpc.Dispatchers, config: vim.lsp.ClientConfig): vim.lsp.rpc.Client
function M.lsp_cmd(command)
    return function(dispatchers, config)
        local root = config.root_dir and M.of(config.root_dir) or vim.g.workspace_root
        return vim.lsp.rpc.start(M.exec(root, command), dispatchers, {
            cwd = config.cmd_cwd or config.root_dir,
            env = config.cmd_env,
            detached = config.detached,
        })
    end
end

---@type table<function, true>
local path_aware = setmetatable({}, { __mode = 'k' })

--- `root_dir` for vim.lsp.Config: resolve the root from `markers` and only
--- activate when `bin` exists in that root's environment. Also accepts a
--- directory path instead of a buffer (see `accepts_path`), so clients can be
--- started eagerly without a buffer. `on_skip` (not passed by Neovim) is
--- called when the server does not apply, so eager callers can count results.
---@param markers (string|string[])[]
---@param bin string
---@return fun(source: integer|string, on_dir: fun(root_dir?: string), on_skip?: fun())
function M.lsp_root_dir(markers, bin)
    local fn = function(source, on_dir, on_skip)
        on_skip = on_skip or function() end
        local root = vim.fs.root(source, markers)
        if not root then
            on_skip()
            return
        end
        M.executable(M.of(root) or root, bin, function(path)
            if path then
                on_dir(root)
            else
                on_skip()
            end
        end)
    end
    path_aware[fn] = true
    return fn
end

--- Whether a `root_dir` function was created by `lsp_root_dir()`.
---@param fn any
---@return boolean
function M.accepts_path(fn)
    return path_aware[fn] == true
end

function M.reload()
    roots, roots_for = nil, nil
    envs = {}
    M.load()
end

function M.setup()
    M.load()
    local group = vim.api.nvim_create_augroup('conf.project', { clear = true })
    vim.api.nvim_create_autocmd('BufWritePost', {
        group = group,
        pattern = { 'mise.toml', '.mise.toml', 'mise.*.toml' },
        callback = M.reload,
        desc = 'Reload mise monorepo config roots',
    })
end

return M
