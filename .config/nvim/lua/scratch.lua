---@param name string
---@param reps uinteger
---@param f fun()
local function perf(name, reps, f)
    local start_time = os.clock()
    for _ = 1, reps do
        f()
    end
    local end_time = os.clock()
    vim.print(name, end_time - start_time)
end

local cwd = assert(vim.uv.cwd())

---@param path string
local function root(path)
    return vim.fs.root(path, '.git')
end

---@param path string
local function parents(path)
    local paths = { path }
    for dir in vim.fs.parents(path) do
        table.insert(paths, dir)
    end
    for _, dir in ipairs(paths) do
        if vim.uv.fs_stat(dir .. '/.git') ~= nil then
            return dir
        end
    end
end

vim.api.nvim_create_user_command('Perf', function()
    vim.print(root(cwd))
    perf('vim.fs.root', 10000, function()
        return root(cwd)
    end)
    vim.print(Snacks.git.get_root(cwd))
    perf('Snacks.git.get_root', 10000, function()
        return Snacks.git.get_root(cwd)
    end)
    vim.print(parents(cwd))
    perf('vim.fs.parents', 10000, function()
        return parents(cwd)
    end)
end, {})
