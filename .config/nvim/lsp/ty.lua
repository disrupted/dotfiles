---@type vim.lsp.Config
return {
    cmd = { 'ty', 'server' },
    filetypes = { 'python' },
    root_markers = { 'ty.toml', 'pyproject.toml' },
    settings = {
        ty = {
            diagnosticMode = 'workspace',
            completions = {
                completeFunctionParentheses = true,
            },
        },
    },
    trace = 'messages',
}
