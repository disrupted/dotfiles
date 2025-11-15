---@type vim.lsp.Config
return {
    cmd = { 'svelteserver', '--stdio' },
    filetypes = { 'svelte' },
    root_dir = function(bufnr, on_dir)
        local filename = vim.api.nvim_buf_get_name(bufnr)
        -- Svelte LSP only supports file:// schema. https://github.com/sveltejs/language-tools/issues/2777
        if vim.uv.fs_stat(filename) ~= nil then
            local root = vim.fs.root(bufnr, { 'package-lock.json' })
            on_dir(root)
        end
    end,
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
    end,
}
