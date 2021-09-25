local M = {}

function M.setup()
    local map = require('utils').map
    map('n', '"', '<cmd>lua require("harpoon.ui").toggle_quick_menu()<CR>')
    map('n', 'M', '<cmd>lua require("harpoon.mark").toggle_file()<CR>')

    -- Use common mappings to close popup
    vim.cmd [[ 
        autocmd FileType harpoon nnoremap <buffer> q :q<cr> 
        autocmd FileType harpoon nnoremap <buffer> <esc> :q<cr> 
    ]]
end

function M.config()
    require('harpoon').setup {}
end

return M
