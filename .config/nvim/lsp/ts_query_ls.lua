-- disable the slow builtin query linter
vim.g.query_lint_on = {}

---@type vim.lsp.Config
return {
    cmd = { 'ts_query_ls' },
    filetypes = { 'query' },
    root_markers = { 'queries' },
}
