---@type vim.lsp.Config
return {
    cmd = { 'docker-compose-langserver', '--stdio' },
    filetypes = { 'yaml.docker-compose' },
    on_attach = function(client)
        client.server_capabilities.codeLensProvider = nil
    end,
}
