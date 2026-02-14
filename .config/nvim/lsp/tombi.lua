---@type vim.lsp.Config
return {
    cmd = { 'tombi', 'lsp' },
    filetypes = { 'toml' },
    workspace_required = false,
    root_dir = function(bufnr, cb)
        local fname = vim.api.nvim_buf_get_name(bufnr)
        cb(vim.fs.dirname(fname))
    end,
}
