local M = {}

function M.config()
    vim.g.neoterm_default_mod = 'vertical'
    vim.g.neoterm_size = 80
    vim.g.neoterm_autoinsert = 1
    vim.g.neoterm_autoscroll = 1
    vim.g.neoterm_term_per_tab = 1

    local map = require('utils').map
    map('n', '<C-q>', ':Ttoggle<CR>')
    map('i', '<C-q>', '<Esc>:Ttoggle<CR>')
    map('t', '<C-q>', '<C-\\><C-N>:Ttoggle<CR>')
end

return M
