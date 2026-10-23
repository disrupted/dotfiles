---@type LazeSpec
return {
    'joechrisellis/lsp-format-modifications.nvim',
    main = 'lsp-format-modifications',
    module = 'lsp-format-modifications',
    dependencies = { 'nvim-lua/plenary.nvim' },
    init = function()
        vim.api.nvim_create_user_command('FormatModified', function()
            local bufnr = vim.api.nvim_get_current_buf()
            local clients = vim.lsp.get_clients({
                bufnr = bufnr,
                method = 'textDocument/rangeFormatting',
            })

            if #clients == 0 then
                Snacks.notify.error(
                    'Format request failed, no matching language servers',
                    { title = 'LSP' }
                )
            end

            for _, client in pairs(clients) do
                require('lsp-format-modifications').format_modifications(
                    client,
                    bufnr,
                    { experimental_empty_line_handling = true }
                )
            end
            vim.b.disable_autoformat = true
        end, {})
    end,
}
