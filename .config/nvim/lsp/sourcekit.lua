local root_markers = {
    'buildServer.json',
    '*.xcodeproj',
    '*.xcworkspace',
    '.git',
}

---@type vim.lsp.Config
return {
    cmd = { 'sourcekit-lsp' },
    filetypes = { 'swift' },
    root_markers = root_markers,
    root_dir = function(bufnr, on_dir)
        local filename = vim.api.nvim_buf_get_name(bufnr)
        local root = vim.fs.root(filename, root_markers)
        on_dir(root)
    end,
}
