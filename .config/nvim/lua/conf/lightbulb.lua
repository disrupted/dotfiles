local M = {}

function M.setup()
    vim.cmd [[packadd nvim-lightbulb]]
    -- vim.fn.sign_define("LightBulbSign", { text = "", texthl = "", linehl="", numhl="" })
    vim.cmd [[autocmd CursorHold,CursorHoldI * lua require'nvim-lightbulb'.update_lightbulb()]]
end

return M
