--- Runs neotest-vitest through `ng test` for `@angular/build:unit-test` projects:
--- they have no vitest config, only the builder can compile the specs.
local project = require('conf.project')
local runner = require('conf.neotest.runner')

local uv = vim.uv

local M = {}

M.builder = '@angular/build:unit-test'
M.script =
    vim.fs.joinpath(vim.fn.stdpath('config') --[[@as string]], 'scripts', 'ng-vitest')

---@class conf.neotest.angular.Target
---@field workspace string
---@field project string
---@field root string absolute

--- Innermost unit-test project containing `path`; root `""` is the workspace.
---@param workspace string
---@param config table decoded angular.json
---@param path string absolute
---@return conf.neotest.angular.Target?
function M._resolve(workspace, config, path)
    local best ---@type conf.neotest.angular.Target?
    for name, spec in pairs(type(config.projects) == 'table' and config.projects or {}) do
        local targets = type(spec) == 'table' and (spec.architect or spec.targets)
        local test = type(targets) == 'table' and targets.test
        if type(test) == 'table' and test.builder == M.builder then
            local rel = type(spec.root) == 'string' and spec.root or ''
            local root = vim.fs.normalize(
                rel == '' and workspace or vim.fs.joinpath(workspace, rel)
            )
            if vim.fs.relpath(root, path) and (not best or #root > #best.root) then
                best = { workspace = workspace, project = name, root = root }
            end
        end
    end
    return best
end

---@type table<string, { mtime: integer, config: table|false }>
local cache = {}

---@param workspace string
---@return table?
local function config_of(workspace)
    local file = vim.fs.joinpath(workspace, 'angular.json')
    local stat = uv.fs_stat(file)
    if not stat then
        return nil
    end
    local cached = cache[workspace]
    if cached and cached.mtime == stat.mtime.sec then
        return cached.config or nil
    end
    local ok, lines = pcall(vim.fn.readfile, file)
    local decoded_ok, decoded = false, nil
    if ok then
        decoded_ok, decoded = pcall(vim.json.decode, table.concat(lines, '\n'))
    end
    local config = decoded_ok and type(decoded) == 'table' and decoded or false
    cache[workspace] = { mtime = stat.mtime.sec, config = config }
    return config or nil
end

---@param path string
---@return conf.neotest.angular.Target?
function M.target(path)
    path = vim.fs.normalize(path)
    local workspace = vim.fs.root(path, 'angular.json')
    local config = workspace and config_of(workspace)
    return config and M._resolve(workspace --[[@as string]], config, path) or nil
end

---@param target conf.neotest.angular.Target
---@return string[]
local function ng(target)
    for _, marker in ipairs({ 'aube-workspace.yaml', 'aube-lock.yaml' }) do
        if uv.fs_stat(vim.fs.joinpath(target.workspace, marker)) then
            return { 'aube', 'exec', 'ng' }
        end
    end
    return { runner.bin('ng', vim.fs.joinpath(target.root, 'x')) }
end

--- neotest-vitest splits this on whitespace and appends vitest flags.
---@param target conf.neotest.angular.Target
---@return string
function M.command(target)
    local command = { M.script, target.workspace, target.project, target.root }
    vim.list_extend(command, ng(target))
    command[#command + 1] = '--'
    return table.concat(
        project.exec(project.of(target.workspace) or target.workspace, command),
        ' '
    )
end

return M
