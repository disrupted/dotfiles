local cache_dir = vim.loop.os_homedir() .. '/.cache/gitlab-ci-ls/'
---@type vim.lsp.Config
return {
    cmd = { 'gitlab-ci-ls' },
    filetypes = { 'yaml.gitlab' },
    root_markers = { '.gitlab*', '.git' },
    init_options = {
        cache_path = cache_dir,
        log_path = cache_dir .. '/log/gitlab-ci-ls.log',
    },
}
