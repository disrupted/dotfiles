local inlayHints = {
    parameterNames = {
        enabled = 'all',
    },
    parameterTypes = {
        enabled = true,
    },
    variableTypes = {
        enabled = true,
    },
    -- propertyDeclarationTypes = {
    --     enabled = true,
    -- },
    -- functionLikeReturnTypes = {
    --     enabled = true,
    -- },
    enumMemberValues = {
        enabled = true,
    },
}

---@type vim.lsp.Config
return {
    cmd = { 'vtsls', '--stdio' },
    filetypes = {
        'javascript',
        'javascriptreact',
        'javascript.jsx',
        'typescript',
        'typescriptreact',
        'typescript.tsx',
    },
    root_markers = {
        'tsconfig.json',
        'jsconfig.json',
        'package.json',
        '.git',
    },
    settings = {
        typescript = {
            inlayHints = inlayHints,
            tsserver = {
                experimental = {
                    enableProjectDiagnostics = true,
                },
            },
        },
    },
}
