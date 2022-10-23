local M = {}

function M.setup()
    vim.keymap.set('n', '<leader>xx', function()
        require('trouble').toggle()
    end)
    vim.keymap.set('n', '<leader>xw', function()
        require('trouble').toggle { mode = 'workspace_diagnostics' }
    end)
    vim.keymap.set('n', '<leader>xb', function()
        require('trouble').toggle { mode = 'document_diagnostics' }
    end)
    vim.keymap.set('n', '<leader>xq', function()
        require('trouble').toggle { mode = 'quickfix' }
    end)
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
    vim.api.nvim_set_hl(0, 'TroubleText', { link = 'CursorLineNr' })
end

return M
