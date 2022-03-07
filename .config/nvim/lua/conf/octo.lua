local M = {}

function M.setup()
    vim.keymap.set('n', '<leader>op', function()
        __octo_open_pr()
    end)
    vim.keymap.set('n', '<leader>oi', '<cmd>Octo issue listend<cr>')

    function _G.__octo_open_pr()
        local url = vim.fn.system 'gh pr view --json url --jq .url 2>/dev/null'
        if url then
            vim.notify(url)
            local cmd = string.format('Octo %s', url)
            vim.cmd(cmd)
        else
            vim.cmd 'Octo pr list'
        end
    end
end

function M.config()
    require('octo').setup {
        date_format = '%Y %b %d %H:%M',
    }
end

return M
