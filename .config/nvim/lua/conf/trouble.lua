local M = {}

function M.setup()
    local opts = { silent = true, noremap = true }
    vim.api.nvim_set_keymap('n', '<space>xx', '<cmd>TroubleToggle<CR>', opts)
    vim.api.nvim_set_keymap(
        'n',
        '<space>xw',
        '<cmd>TroubleToggle lsp_workspace_diagnostics<CR>',
        opts
    )
    vim.api.nvim_set_keymap(
        'n',
        '<space>xb',
        '<cmd>TroubleToggle lsp_document_diagnostics<CR>',
        opts
    )
    vim.api.nvim_set_keymap(
        'n',
        '<space>xq',
        '<cmd>TroubleToggle quickfix<CR>',
        opts
    )
end

function M.config()
    require('trouble').setup {
        fold_open = '▾',
        fold_closed = '▸',
        indent_lines = false,
        signs = {
            error = '',
            warning = '',
            hint = '',
            information = '',
            other = '',
        },
        action_keys = { jump = { '<cr>' }, toggle_fold = { '<tab>' } },
    }
    vim.cmd [[highlight link TroubleText CursorLineNr]]
end

return M
