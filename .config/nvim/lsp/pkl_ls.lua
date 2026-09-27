---@type vim.lsp.Config
return {
    cmd = { 'pkl-lsp' },
    filetypes = { 'pkl', 'pcf' },
    root_markers = {
        'PklProject',
        '.git',
    },
}
