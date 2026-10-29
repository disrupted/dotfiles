local project = require('conf.project')

local root_markers =
    { { 'ruff.toml', '.ruff.toml', 'uv.lock' }, { 'pyproject.toml' }, '.git' }

---@type vim.lsp.Config
return {
    cmd = project.lsp_cmd({ 'ruff', 'server' }),
    filetypes = { 'python' },
    root_markers = root_markers,
    root_dir = project.lsp_root_dir(root_markers, 'ruff'),
    settings = {},
}
