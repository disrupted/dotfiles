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
    cmd = { 'bunx', '--bun', 'tsgo', '--lsp', '--stdio' },
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
        typescript = {
            inlayHints = inlayHints,
        },
        javascript = {
            inlayHints = inlayHints,
        },
    },
}
