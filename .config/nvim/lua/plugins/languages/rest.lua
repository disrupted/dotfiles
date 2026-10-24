---@type LazeSpec
return {
    'rest-nvim/rest.nvim',
    main = 'rest-nvim',
    module = 'rest-nvim',
    cmd = 'Rest',
    init = function()
        local group = vim.api.nvim_create_augroup('rest_http_keys', { clear = true })
        local function set(buf)
            local function map(lhs, rhs, desc)
                vim.keymap.set('n', lhs, rhs, {
                    buffer = buf,
                    desc = desc,
                })
            end

            -- which-key group placeholder
            map('<LocalLeader>r', function() end, 'Request (rest.nvim)')
            map('<LocalLeader>rr', '<cmd>Rest run<cr>', 'Run')
            map('<LocalLeader>rl', '<cmd>Rest run last<cr>', 'Re-run last')
        end

        vim.api.nvim_create_autocmd('FileType', {
            group = group,
            pattern = 'http',
            callback = function(ev)
                set(ev.buf)
            end,
        })

        -- command-line http buffers may already have FileType before init runs
        if vim.bo.filetype == 'http' then
            set(0)
        end
    end,
    ---@module 'rest-nvim.config'
    ---@type rest.Opts
    opts = {},
}
