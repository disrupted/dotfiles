---@type vim.lsp.Config
return {
    cmd = { 'gitlab-ci-ls' },
    filetypes = { 'yaml.gitlab' },
    root_markers = { '.gitlab*', '.git' },
    init_options = {
        cache_path = vim.fn.stdpath 'cache',
        log_path = vim.fn.stdpath 'log' .. '/lsp.gitlab-ci-ls.log',
    },
}
