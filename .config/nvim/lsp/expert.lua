-- TODO: replace with elixir-tools.nvim once it supports expert https://github.com/elixir-tools/elixir-tools.nvim/issues/245
---@type vim.lsp.Config
return {
    filetypes = { 'elixir', 'eelixir', 'heex', 'surface' },
    cmd = { 'expert', '--stdio' },
    root_markers = { 'mix.exs' },
}
