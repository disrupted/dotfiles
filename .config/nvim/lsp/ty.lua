---@type vim.lsp.Config
return {
    cmd = { 'ty', 'server' },
    filetypes = { 'python' },
    -- nested list = priority groups: prefer the uv workspace root (e.g.
    -- backend/) over the nearest member package pyproject.toml
    root_markers = { { 'ty.toml', 'uv.lock' }, { 'pyproject.toml' } },
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
