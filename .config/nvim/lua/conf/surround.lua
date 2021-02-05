local M = {}

function M.setup()
    vim.g.surround_mappings_style = 'surround'
    require'surround'.setup{}
end

return M
