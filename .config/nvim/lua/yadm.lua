local M = {}

local repo = vim.fs.joinpath(vim.env.XDG_DATA_HOME, 'yadm', 'repo.git')
M.config = { repo = repo }

M.setup = function()
    if vim.fn.executable 'yadm' ~= 1 then
        Snacks.notify.warn 'yadm not installed'
        return
    end
    local cwd = assert(vim.uv.cwd())
    if
        cwd ~= vim.env.HOME
        and not vim.fs.relpath(vim.env.XDG_CONFIG_HOME, cwd)
    then
        return
    end
    if vim.uv.fs_stat(repo) == nil then
        local out = vim.system({ 'yadm', 'rev-parse', '--git-dir' }):wait()
        repo = vim.trim(out.stdout or '')
        if not repo then
            Snacks.notify.error 'yadm repo not found'
            return
        end
    end
    vim.g.git_repo = repo
    vim.env.GIT_DIR = repo
    vim.env.GIT_WORK_TREE = vim.env.HOME
end

return M
