local M = {}

function M.config()
    vim.g.neoterm_default_mod = 'vertical'
    vim.g.neoterm_size = 80
    vim.g.neoterm_autoinsert = 1
    vim.g.neoterm_autoscroll = 1
    vim.g.neoterm_term_per_tab = 1
    -- Key bindings
    local opts = { noremap = true, silent = true }
    vim.api.nvim_set_keymap('n', '<C-q>', ':Ttoggle<CR>', opts)
    vim.api.nvim_set_keymap('i', '<C-q>', '<Esc>:Ttoggle<CR>', opts)
    vim.api.nvim_set_keymap('t', '<C-q>', '<C-\\><C-N>:Ttoggle<CR>', opts)
end

return M
