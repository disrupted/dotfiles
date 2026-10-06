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
    init_options = {
        hostInfo = 'neovim',
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
    on_attach = function(client, bufnr)
        vim.api.nvim_buf_create_user_command(
            bufnr,
            'LspOrganizeImports',
            function()
                client:exec_cmd {
                    title = 'Organize TypeScript imports',
                    command = '_typescript.organizeImports',
                    arguments = { vim.uri_from_bufnr(bufnr) },
                }
            end,
            { desc = 'Organize TypeScript imports' }
        )
    end,
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
