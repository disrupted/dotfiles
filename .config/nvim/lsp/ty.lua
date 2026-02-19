---@type vim.lsp.Config
return {
    cmd = { 'ty', 'server' },
    filetypes = { 'python' },
    root_markers = { 'ty.toml', 'pyproject.toml' },
    init_options = {
        settings = {
            logLevel = 'warn',
            logFile = vim.fn.stdpath 'log' .. '/lsp.ty.log',
        },
    },
    settings = {
        ty = {
            diagnosticMode = 'workspace',
        },
    },
    trace = 'messages',
}
