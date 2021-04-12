local M = {}

function M.setup()
    vim.cmd [[packadd surround.nvim]]
    vim.g.surround_mappings_style = 'surround'
    require'surround'.setup{}
end

return M
