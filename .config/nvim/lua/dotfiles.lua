-- ~ and ~/.config aren't git repos: point git integrations at ~/.dotfiles
local M = {}

local HOME = vim.env.HOME
if not HOME then
    return
end
local root = vim.fs.joinpath(HOME, '.dotfiles')
M.config = { root = root, repo = vim.fs.joinpath(root, '.git') }

M.setup = function()
    local cwd = assert(vim.uv.cwd())
    if
        cwd ~= HOME
        and not vim.fs.relpath(
            vim.env.XDG_CONFIG_HOME or vim.fs.joinpath(HOME, '.config'),
            cwd
        )
    then
        return
    end
    if vim.uv.fs_stat(M.config.repo) == nil then
        Snacks.notify.warn('dotfiles repo not found at ' .. root)
        return
    end
    vim.g.git_repo = M.config.repo
    vim.g.git_root = root
    vim.env.GIT_DIR = M.config.repo
    vim.env.GIT_WORK_TREE = root
end

return M
