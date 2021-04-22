local M = {}

function M.setup()
    vim.api.nvim_set_keymap('n', '<space>x', '<cmd>LspTroubleToggle<CR>',
                            {silent = true, noremap = true})
end

function M.config() require'trouble'.setup {} end

return M
