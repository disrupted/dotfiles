---@type vim.lsp.Config
return {
    cmd = { 'basedpyright-langserver', '--stdio' },
    -- cmd = { 'npm', '-C', '~/dev/basedpyright', 'run', 'run:langserver' },
    filetypes = { 'python' },
    root_markers = {
        'pyproject.toml',
        'setup.py',
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
                if
                    token.type == 'parameter' and not token.modifiers.definition
                then
                    local captures = vim.treesitter.get_captures_at_pos(
                        bufnr,
                        token.line,
                        token.start_col
                    )
                    if
                        vim.iter(captures):any(function(capture)
                            return capture.lang == 'python'
                                and (
                                    capture.capture == 'variable.parameter' -- inside function call
                                    or capture.capture == 'variable.builtin' -- self / cls param
                                )
                        end)
                    then
                        -- abort override
                        return
                    end
                    vim.lsp.semantic_tokens.highlight_token(
                        token,
                        args.buf,
                        args.data.client_id,
                        '@variable.parameter.reference'
                    )
                end
            end,
        })
    end,
    settings = {
        basedpyright = {
            analysis = {
                diagnosticMode = 'workspace', -- default: openFilesOnly
                diagnosticSeverityOverrides = {
                    reportAny = false,
                    reportExplicitAny = false,
                    reportUnusedCallResult = false,
                    reportMissingTypeArgument = false,
                    reportMissingParameterType = false,
                    reportUnknownArgumentType = false,
                    reportUnknownLambdaType = false,
                    reportUnknownMemberType = false,
                    reportUnknownParameterType = false,
                    reportUnknownVariableType = false,
                    reportImplicitStringConcatenation = false,
                },
            },
        },
    },
}
