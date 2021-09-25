local M = {}

function M.setup()
    local map = require('utils').map
    map('n', '<space>xx', '<cmd>TroubleToggle<CR>')
    map('n', '<space>xw', '<cmd>TroubleToggle lsp_workspace_diagnostics<CR>')
    map('n', '<space>xb', '<cmd>TroubleToggle lsp_document_diagnostics<CR>')
    map('n', '<space>xq', '<cmd>TroubleToggle quickfix<CR>')
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
