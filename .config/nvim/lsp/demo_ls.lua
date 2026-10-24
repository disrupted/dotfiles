---@type vim.lsp.Config
return {
    cmd = { 'lsp' },
    filetypes = { 'text' },
    on_attach = function(client, _bufnr)
        vim.print(client.server_capabilities)
    end,
}
