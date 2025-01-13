---@type vim.lsp.Config
return {
    cmd = { 'pylyzer', '--server' },
    filetypes = { 'python' },
    root_markers = {
        'pyproject.toml',
        'requirements.txt',
        '.git',
    },
    settings = {
        python = {
            diagnostics = true,
            smartCompletion = true,
            checkOnType = false,
            inlayHints = true,
            semanticTokens = false, -- currently very wrong
        },
    },
}
