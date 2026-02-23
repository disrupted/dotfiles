---@type vim.lsp.Config
return {
    cmd = { 'bunx', '--bun', 'vscode-json-language-server', '--stdio' },
    filetypes = { 'json', 'jsonc' },
    ---@type table<vim.lsp.protocol.Methods, lsp.Handler>
    handlers = {
        ['textDocument/diagnostic'] = function(err, result, ctx)
            ---@param diagnostic vim.Diagnostic
            result.items = vim.tbl_filter(function(diagnostic)
                -- disable diagnostic for trailing comma in JSONC
                if diagnostic.code == 519 and diagnostic.source == 'jsonc' then
                    return false
                end

                return true
            end, result.items)
            vim.lsp.handlers[ctx.method](err, result, ctx)
        end,
    },
    init_options = {
        provideFormatter = false,
    },
    settings = {
        json = {
            validate = { enable = true },
            schemas = {
                {
                    fileMatch = { 'package.json' },
                    url = 'https://json.schemastore.org/package.json',
                },
                {
                    fileMatch = { 'tsconfig*.json' },
                    url = 'https://json.schemastore.org/tsconfig.json',
                },
                {
                    fileMatch = {
                        '.prettierrc',
                        '.prettierrc.json',
                        'prettier.config.json',
                    },
                    url = 'https://json.schemastore.org/prettierrc.json',
                },
                {
                    fileMatch = {
                        '.eslintrc',
                        '.eslintrc.json',
                    },
                    url = 'https://json.schemastore.org/eslintrc.json',
                },
                {
                    fileMatch = {
                        '.stylelintrc',
                        '.stylelintrc.json',
                        'stylelint.config.json',
                    },
                    url = 'http://json.schemastore.org/stylelintrc.json',
                },
            },
        },
    },
}
