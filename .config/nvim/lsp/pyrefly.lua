---@type vim.lsp.Config
return {
    cmd = { 'pyrefly', 'lsp' },
    filetypes = { 'python' },
    root_markers = {
        'pyrefly.toml',
        'pyproject.toml',
        '.git',
    },
    on_attach = function(client, bufnr)
        vim.api.nvim_create_autocmd('LspTokenUpdate', {
            buffer = bufnr,
            callback = function(args)
                if args.data.client_id ~= client.id then
                    return
                end
                ---@type STTokenRange
                local token = args.data.token
                if token.type == 'property' then
                    return
                end
                if token.type == 'interface' then
                    vim.lsp.semantic_tokens.highlight_token(
                        token,
                        args.buf,
                        args.data.client_id,
                        '@lsp.type.class.python'
                    )
                end
            end,
        })
    end,
    on_exit = function(code, _, _)
        vim.notify(
            'Closing Pyrefly LSP exited with code: ' .. code,
            vim.log.levels.INFO
        )
    end,
    settings = {
        python = {
            pyrefly = {
                displayTypeErrors = 'force-on',
            },
            analysis = {
                diagnosticMode = 'workspace',
                inlayHints = {
                    callArgumentNames = 'partial',
                    variableTypes = true,
                    functionReturnTypes = true,
                    pytestParameters = true,
                },
            },
        },
    },
}
