local project = require('conf.project')

local root_markers = {
    { 'pyrightconfig.json', 'uv.lock' },
    { 'pyproject.toml', 'setup.py' },
    '.git',
}

---@type vim.lsp.Config
return {
    cmd = project.lsp_cmd({ 'pyright-langserver', '--stdio' }),
    filetypes = { 'python' },
    root_markers = root_markers,
    root_dir = project.lsp_root_dir(root_markers, 'pyright-langserver'),
    settings = {
        python = {
            analysis = {
                diagnosticMode = 'workspace',
            },
        },
    },
}
