--- Tells jest and vitest projects apart.
---
--- Both adapters fall back to the `package.json` at Neovim's cwd, so in a repo
--- with both runners they claim each other's files.
local project = require('conf.project')

local uv = vim.uv

local M = {}

---@alias conf.neotest.Runner 'jest' | 'vitest'

---@type table<conf.neotest.Runner, string[]>
local configs = {
    jest = {
        'jest.config.js',
        'jest.config.ts',
        'jest.config.mjs',
        'jest.config.cjs',
        'jest.config.json',
    },
    vitest = {
        'vitest.config.js',
        'vitest.config.ts',
        'vitest.config.mjs',
        'vitest.config.mts',
        'vitest.config.cjs',
        'vitest.config.cts',
    },
}

--- Only counts when its content mentions vitest: jest projects use vite too.
---@type string[]
local vite_configs = {
    'vite.config.js',
    'vite.config.ts',
    'vite.config.mjs',
    'vite.config.mts',
}

---@type table<conf.neotest.Runner, string[]>
local dependencies = {
    jest = { 'jest', '@nx/jest', 'ts-jest', 'babel-jest' },
    vitest = { 'vitest', '@vitest/ui', '@vitest/coverage-v8' },
}

---@param path string
---@return string?
local function read(path)
    local fd = uv.fs_open(path, 'r', 438)
    if not fd then
        return nil
    end
    local stat = uv.fs_fstat(fd)
    local data = stat and stat.size > 0 and uv.fs_read(fd, stat.size, 0) or nil
    uv.fs_close(fd)
    return data --[[@as string?]]
end

---@type table<string, table|false>
local packages = {}
---@type table<string, conf.neotest.Runner|false>
local runners = {}
---@type string?
local cached_for = nil

local function reset()
    local root = vim.g.workspace_root
    if cached_for ~= root then
        packages, runners, cached_for = {}, {}, root
    end
end

---@param dir string
---@return table?
local function package_of(dir)
    local cached = packages[dir]
    if cached ~= nil then
        return cached or nil
    end
    local content = read(vim.fs.joinpath(dir, 'package.json'))
    local ok, decoded = pcall(vim.json.decode, content or '')
    packages[dir] = ok and type(decoded) == 'table' and decoded or false
    return packages[dir] or nil
end

---@param path string
---@return boolean
local function mentions_vitest(path)
    local content = read(path)
    return content ~= nil and content:find('vitest', 1, true) ~= nil
end

---@param dir string
---@param runner conf.neotest.Runner
---@param pkg table?
---@return integer
local function score(dir, runner, pkg)
    local points = 0

    for _, file in ipairs(configs[runner]) do
        if uv.fs_stat(vim.fs.joinpath(dir, file)) then
            points = points + 2
            break
        end
    end

    if pkg then
        for _, field in ipairs({ 'dependencies', 'devDependencies' }) do
            local deps = pkg[field]
            if type(deps) == 'table' then
                for _, name in ipairs(dependencies[runner]) do
                    if deps[name] then
                        points = points + 2
                        break
                    end
                end
            end
        end
        local script = type(pkg.scripts) == 'table' and pkg.scripts.test
        if type(script) == 'string' and script:find(runner, 1, true) then
            points = points + 1
        end
    end

    if runner == 'vitest' then
        for _, file in ipairs(vite_configs) do
            local path = vim.fs.joinpath(dir, file)
            if uv.fs_stat(path) and mentions_vitest(path) then
                points = points + 2
                break
            end
        end
    end

    return points
end

---@param dir string
---@return conf.neotest.Runner?
local function verdict(dir)
    local pkg = package_of(dir)
    local jest = score(dir, 'jest', pkg)
    local vitest = score(dir, 'vitest', pkg)
    if jest == vitest then
        return nil
    end
    return vitest > jest and 'vitest' or 'jest'
end

--- Test runner of the project `path` belongs to, or nil when unknown.
--- Nearest evidence wins over the workspace root.
---@param path string?
---@return conf.neotest.Runner?
function M.of(path)
    if not path then
        return nil
    end
    reset()

    local dir = vim.fs.dirname(vim.fs.normalize(path))
    local stopped_at = project.of(dir) or vim.g.workspace_root
    for _ = 1, 100 do
        local cached = runners[dir]
        if cached then
            return cached
        end

        -- `false` only means "nothing here": keep walking up
        if cached == nil then
            local found = verdict(dir)
            runners[dir] = found or false
            if found then
                return found
            end
        end

        local parent = vim.fs.dirname(dir)
        if dir == stopped_at or parent == dir then
            return nil
        end
        dir = parent
    end
end

--- Matches each adapter's own default test file matcher.
---@type table<conf.neotest.Runner, string[]>
local kinds = {
    jest = { 'spec', 'e2e-spec', 'test', 'unit', 'regression', 'integration' },
    vitest = { 'e2e', 'spec', 'test' },
}

---@type string[]
local extensions = { 'js', 'jsx', 'coffee', 'ts', 'tsx' }

---@type table<conf.neotest.Runner, string[]>
local patterns = { jest = {}, vitest = {} }
for runner, names in pairs(kinds) do
    for _, name in ipairs(names) do
        for _, extension in ipairs(extensions) do
            patterns[runner][#patterns[runner] + 1] =
                table.concat({ '%.', vim.pesc(name), '%.', vim.pesc(extension), '$' })
        end
    end
end

---@param file_path string?
---@param runner conf.neotest.Runner
---@return boolean
function M.is_test_path(file_path, runner)
    if not file_path then
        return false
    end
    if file_path:find('node_modules', 1, true) then
        return false
    end
    if file_path:find('__tests__', 1, true) then
        return true
    end
    for _, pattern in ipairs(patterns[runner]) do
        if file_path:find(pattern) then
            return true
        end
    end
    return false
end

--- `is_test_file` (`isTestFile` for neotest-jest) scoped to `runner` projects.
--- Unclassified projects stay with jest, like neotest-jest's own default.
---@param runner conf.neotest.Runner
---@return fun(file_path: string?): boolean
function M.is_test_file(runner)
    return function(file_path)
        if not M.is_test_path(file_path, runner) then
            return false
        end
        local detected = M.of(file_path)
        if runner == 'vitest' then
            return detected == 'vitest'
        end
        return detected ~= 'vitest'
    end
end

--- Nearest `node_modules/.bin/<name>`, else the bare name.
---@param name string
---@param path string
---@return string
function M.bin(name, path)
    local dir = vim.fs.dirname(vim.fs.normalize(path))
    local ok, found = pcall(
        vim.fs.find,
        vim.fs.joinpath('node_modules', '.bin', name),
        { path = dir, upward = true, type = 'file', limit = 1 }
    )
    if ok and found and found[1] then
        return found[1]
    end
    return name
end

return M
