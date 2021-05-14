local M = {}

function M.config()
    vim.cmd [[:command Rest lua require'rest-nvim'.run()]]
end

return M
