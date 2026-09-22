---@type vim.lsp.Config
return {
    cmd = {
        'bunx',
        '--bun',
        '--package',
        '@typescript/native',
        'tsc',
        '--lsp',
        '--stdio',
    },
    filetypes = {
        'javascript',
        'javascriptreact',
        'typescript',
        'typescriptreact',
    },
    root_markers = {
        'tsconfig.json',
        'jsconfig.json',
        'package.json',
        '.git',
    },
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
