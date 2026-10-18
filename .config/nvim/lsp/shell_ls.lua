---@type vim.lsp.Config
return {
    cmd = { 'shell-lsp' },
    filetypes = {
        'sh',
        'bash',
        'zsh',
        'ksh',
        'make',
        'just',
        'dockerfile',
        'nix',
    },
}
