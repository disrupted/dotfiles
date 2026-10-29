local project = require('conf.project')

local root_markers = { { 'ty.toml', 'uv.lock' }, { 'pyproject.toml' } }

---@type vim.lsp.Config
return {
    cmd = project.lsp_cmd({ 'ty', 'server' }),
    filetypes = { 'python' },
    root_markers = root_markers,
    root_dir = project.lsp_root_dir(root_markers, 'ty'),
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
