local M = {}

function M.config()
    vim.api.nvim_create_user_command('Rest', require('rest-nvim').run, {})
end

return M
