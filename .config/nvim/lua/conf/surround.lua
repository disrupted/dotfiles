local M = {}

function M.config()
    vim.g.surround_mappings_style = 'surround'
    require'surround'.setup {}
end

return M
