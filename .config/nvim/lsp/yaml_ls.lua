---@type vim.lsp.Config
return {
    cmd = { 'bunx', '--bun', 'yaml-language-server', '--stdio' },
    filetypes = { 'yaml' },
    ---@type table<vim.lsp.protocol.Methods, lsp.Handler>
    handlers = {
        ['textDocument/publishDiagnostics'] = function(err, result, ctx)
            ---@param diagnostic vim.Diagnostic
            result.diagnostics = vim.tbl_filter(function(diagnostic)
                if
                    -- mkdocs
                    diagnostic.message:match 'Unresolved tag: tag:yaml%.org,2002:python/'
                then
                    return false
                end

                return true
            end, result.diagnostics)
            vim.lsp.handlers[ctx.method](err, result, ctx)
        end,
    },
    settings = {
        yaml = {
            editor = { formatOnType = false },
            schemas = {
                -- GitHub CI workflows
                -- ['https://json.schemastore.org/github-workflow.json'] = '/.github/workflows/*',
                -- Helm charts
                -- ['https://json.schemastore.org/chart.json'] = '/templates/*',
            },
            customTags = {},
        },
    },
}
