---@type vim.lsp.Config
return {
    cmd = { 'pkl-lsp' },
    filetypes = { 'pkl' },
    root_markers = {
        'PklProject',
        '.git',
    },
    workspace_required = false,
    settings = {
        ['pkl.cli.path'] = 'pkl',
    },
}
