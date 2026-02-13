---@type vim.lsp.Config
return {
    cmd = { 'bunx', '--bun', 'svelteserver', '--stdio' },
    filetypes = { 'svelte' },
    root_dir = function(bufnr, on_dir)
        local filename = vim.api.nvim_buf_get_name(bufnr)
        -- Svelte LSP only supports file:// schema. https://github.com/sveltejs/language-tools/issues/2777
        if vim.uv.fs_stat(filename) ~= nil then
            local root = vim.fs.root(bufnr, { 'package-lock.json' })
            on_dir(root)
        end
    end,
    workspace_required = true,
    on_attach = function(client, bufnr)
        -- Workaround to trigger reloading JS/TS files
        -- See https://github.com/sveltejs/language-tools/issues/2008
        vim.api.nvim_create_autocmd({ 'BufWritePre' }, {
            group = vim.api.nvim_create_augroup('lsp.svelte', {}),
            pattern = { '*.js', '*.ts' },
            callback = function(ctx)
                -- internal API to sync changes that have not yet been saved to the file system
                client:notify('$/onDidChangeTsOrJsFile', {
                    uri = ctx.match,
                })
            end,
        })
        vim.api.nvim_buf_create_user_command(
            bufnr,
            'LspOrganizeImports',
            function()
                client:exec_cmd {
                    title = 'Svelte: Organize imports',
                    command = 'source.organizeImports',
                    arguments = { vim.uri_from_bufnr(bufnr) },
                }
            end,
            { desc = 'Svelte: Organize imports' }
        )
        vim.api.nvim_buf_create_user_command(
            bufnr,
            'LspRemoveUnusedImports',
            function()
                client:exec_cmd {
                    title = 'Svelte: Remove unused imports',
                    command = 'source.removeUnusedImports',
                    arguments = { vim.uri_from_bufnr(bufnr) },
                }
            end,
            { desc = 'Svelte: Remove unused imports' }
        )
        vim.api.nvim_buf_create_user_command(
            bufnr,
            'LspMigrateToSvelte5',
            function()
                client:exec_cmd {
                    title = 'Migrate Component to Svelte 5 Syntax',
                    command = 'migrate_to_svelte_5',
                    arguments = { vim.uri_from_bufnr(bufnr) },
                }
            end,
            { desc = 'Migrate Component to Svelte 5 Syntax' }
        )
    end,
    settings = {
        vtsls = {
            tsserver = {
                globalPlugins = {
                    {
                        name = 'typescript-svelte-plugin',
                        location = vim.fs.normalize(
                            vim.fn.stdpath 'data'
                                .. '/mason/packages/'
                                .. 'svelte-language-server'
                                .. '/node_modules/typescript-svelte-plugin'
                        ),
                        enableForWorkspaceTypeScriptVersions = true,
                    },
                },
            },
        },
    },
}
