local project = require('conf.project')

-- prefer the package manager workspace root (e.g. frontend/) over the
-- per-project tsconfig.json of each Nx app/lib
local root_markers = {
    {
        'nx.json',
        'aube-workspace.yaml',
        'pnpm-workspace.yaml',
        'package-lock.json',
        'pnpm-lock.yaml',
        'yarn.lock',
        'bun.lock',
    },
    { 'tsconfig.json', 'jsconfig.json', 'package.json' },
    '.git',
}

---@type vim.lsp.Config
return {
    cmd = project.lsp_cmd({ 'tsc', '--lsp', '--stdio' }),
    filetypes = {
        'javascript',
        'javascriptreact',
        'typescript',
        'typescriptreact',
    },
    root_markers = root_markers,
    root_dir = project.lsp_root_dir(root_markers, 'tsc'),
    settings = {
        ['js/ts'] = {
            inlayHints = {
                parameterNames = {
                    enabled = 'literals', -- 'all'
                    suppressWhenArgumentMatchesName = true,
                },
                parameterTypes = { enabled = true },
                variableTypes = { enabled = true },
                -- propertyDeclarationTypes = { enabled = true },
                -- functionLikeReturnTypes = { enabled = true },
                enumMemberValues = { enabled = true },
            },
            referencesCodeLens = {
                enabled = true,
                showOnAllFunctions = true,
            },
            implementationsCodeLens = {
                enabled = true,
                showOnInterfaceMethods = true,
                showOnAllClassMethods = true,
            },
        },
    },
}
