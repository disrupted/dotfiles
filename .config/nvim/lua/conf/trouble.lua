local M = {}

function M.setup()
    local map = require('utils').map
    map('n', '<space>xx', '<cmd>lua require("trouble").toggle()<CR>')
    map(
        'n',
        '<space>xw',
        '<cmd>lua require("trouble").toggle { mode = "workspace_diagnostics" }<CR>'
    )
    map(
        'n',
        '<space>xb',
        '<cmd>lua require("trouble").toggle { mode = "document_diagnostics" }<CR>'
    )
    map(
        'n',
        '<space>xq',
        '<cmd>lua require("trouble").toggle { mode = "quickfix" }<CR>'
    )
end

function M.config()
    require('trouble').setup {
        fold_open = '', -- ▾
        fold_closed = '', -- ▸
        indent_lines = false,
        padding = false,
        signs = {
            error = '',
            warning = '',
            hint = '',
            information = '',
            other = '', -- 
        },
        action_keys = { jump = { '<cr>' }, toggle_fold = { '<tab>' } },
    }
    vim.cmd [[highlight link TroubleText CursorLineNr]]
end

return M
