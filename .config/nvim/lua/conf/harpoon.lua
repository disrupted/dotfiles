local M = {}

function M.setup()
    local map = require('utils').map
    map('n', ';;', '<cmd>lua require("harpoon.ui").toggle_quick_menu()<CR>')
    map('n', 'M', '<cmd>lua require("harpoon.mark").toggle_file()<CR>')
    map('n', ';a', '<cmd>lua require("harpoon.ui").nav_file(1)<CR>')
    map('n', ';s', '<cmd>lua require("harpoon.ui").nav_file(2)<CR>')
    map('n', ';d', '<cmd>lua require("harpoon.ui").nav_file(3)<CR>')
    map('n', ';f', '<cmd>lua require("harpoon.ui").nav_file(4)<CR>')

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
