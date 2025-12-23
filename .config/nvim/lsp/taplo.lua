---@type vim.lsp.Config
return {
    cmd = { 'taplo', 'lsp', 'stdio' },
    filetypes = { 'toml' },
    workspace_required = false,
    settings = {
        evenBetterToml = {
            taplo = {
                configFile = { enabled = true },
            },
        },
    },
    root_dir = function(bufnr, cb)
        local fname = vim.api.nvim_buf_get_name(bufnr)
        cb(vim.fs.dirname(fname))
    end,
}
