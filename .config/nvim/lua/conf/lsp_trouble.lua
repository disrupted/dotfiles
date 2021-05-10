local M = {}

function M.setup()
    local opts = {silent = true, noremap = true}
    vim.api.nvim_set_keymap('n', '<space>xx', '<cmd>LspTroubleToggle<CR>', opts)
    vim.api.nvim_set_keymap('n', '<space>xw',
                            '<cmd>LspTroubleToggle lsp_workspace_diagnostics<CR>',
                            opts)
    vim.api.nvim_set_keymap('n', '<space>xb',
                            '<cmd>LspTroubleToggle lsp_document_diagnostics<CR>',
                            opts)
    vim.api.nvim_set_keymap('n', '<space>xq',
                            '<cmd>LspTroubleToggle quickfix<CR>', opts)
end

function M.config()
    require'trouble'.setup {
        fold_open = '▾',
        fold_closed = '▸',
        indent_lines = false,
        signs = {
            error = '',
            warning = '',
            hint = '',
            information = '',
            other = ''
        },
        action_keys = {jump = {'<cr>'}, toggle_fold = {'<tab>'}}
    }
end

return M
