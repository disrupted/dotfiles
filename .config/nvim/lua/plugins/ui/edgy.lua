---@diagnostic disable: undefined-field
---@type doze.Spec
return {
    src = 'https://github.com/folke/edgy.nvim',
    event = 'VeryLazy',
    config = function()
        ---@type Edgy.Config
        local opts = {
            close_when_all_hidden = false,
            exit_when_last = false,
            animate = { enabled = false },
            icons = {
                open = '',
                closed = '',
            },
            ---@type table<Edgy.Pos, {size:integer | fun():integer, wo:vim.wo?}>
            options = {
                left = { size = 40 },
                right = { size = 78 },
            },
            wo = {
                winbar = true --[[@as string]],
                fillchars = 'eob: ,fold: ,foldopen:,foldclose:,foldsep: ,foldinner: ',
                winhighlight = 'WinBar:EdgyWinBar,WinBarNC:EdgyWinBarNC,Normal:EdgyNormal,WinSeparator:EdgyWinSeparator',
            },
            ---@type table<string, fun(win:Edgy.Window)|false>
            keys = {
                -- toggle width
                ['<S-BS>'] = function(win)
                    if vim.w[win.win]['edgy_width'] == nil then
                        vim.w[win.win]['edgy_width'] = 120
                    else
                        vim.w[win.win]['edgy_width'] = nil
                    end
                    require('edgy.layout').update()
                end,
                -- toggle height
                ['|'] = function(win)
                    if vim.w[win.win]['edgy_height'] == nil then
                        vim.w[win.win]['edgy_height'] = 80
                    else
                        vim.w[win.win]['edgy_height'] = nil
                    end
                    require('edgy.layout').update()
                end,
                -- TODO: consider using window-scoped keymaps, e.g. '<C-w>z'
            },
            left = {
                {
                    ft = 'snacks_layout_box',
                    title = 'Explorer',
                    ---@param win integer
                    filter = function(_buf, win)
                        -- exclude floating windows
                        return vim.api.nvim_win_get_config(win).relative == ''
                    end,
                    wo = {
                        winbar = false,
                    },
                } --[[@as Edgy.View.Opts]],
                {
                    ft = 'neotest-summary',
                    title = 'Tests',
                    wo = {
                        winbar = false,
                        wrap = false,
                        winhighlight = 'WinBar:EdgyWinBar,WinBarNC:EdgyWinBarNC,Normal:EdgyNormal,WinSeparator:EdgyWinSeparator,CursorLine:Visual',
                    },
                } --[[@as Edgy.View.Opts]],
                {
                    ft = 'atlas-ui.pipelines',
                    title = 'CI',
                    wo = {
                        winfixbuf = true,
                    },
                } --[[@as Edgy.View.Opts]],
                {
                    ft = 'codediff-explorer',
                    title = 'CodeDiff Explorer',
                    wo = {
                        winbar = false,
                        listchars = 'extends: ',
                    },
                } --[[@as Edgy.View.Opts]],
            },
            right = {
                {
                    ft = 'atlas-ui.detail',
                    wo = {
                        cursorline = false,
                        winbar = false,
                        winfixbuf = true,
                    },
                } --[[@as Edgy.View.Opts]],
                {
                    ft = 'help',
                    size = { height = 40 },
                    filter = function(buf)
                        return vim.bo[buf].buftype == 'help'
                    end,
                },
            },
            bottom = {
                {
                    ft = 'atlas-ui.logs',
                    size = { height = 15 },
                },
                {
                    ft = 'atlas-ui.review',
                    size = { height = 10 },
                },
                {
                    ft = 'snacks_terminal',
                    title = 'Terminal %{b:snacks_terminal.id}',
                    size = { height = 20 },
                    filter = function(_buf, win)
                        return vim.w[win].snacks_win
                            and vim.w[win].snacks_win.position == 'bottom'
                            and vim.w[win].snacks_win.relative == 'editor'
                            and not vim.w[win].trouble_preview
                    end,
                    wo = { winbar = false },
                } --[[@as Edgy.View.Opts]],
                {
                    ft = 'trouble',
                    filter = function(_buf, win)
                        return vim.w[win].trouble
                            and vim.w[win].trouble.type == 'split'
                            and vim.w[win].trouble.relative == 'editor'
                            and not vim.w[win].trouble_preview
                    end,
                    wo = { winbar = false },
                } --[[@as Edgy.View.Opts]],
                { ft = 'qf', title = 'QuickFix' } --[[@as Edgy.View.Opts]],
                {
                    ft = 'dap-view',
                    title = 'DAP',
                    size = { height = 15 },
                } --[[@as Edgy.View.Opts]],
                {
                    ft = 'OverseerList',
                    title = 'Tasks',
                    size = { width = 40 },
                    wo = {
                        winhighlight = 'WinBar:EdgyWinBar,WinBarNC:EdgyWinBarNC,Normal:EdgyNormal,WinSeparator:EdgyWinSeparator,CursorLine:Visual',
                    },
                } --[[@as Edgy.View.Opts]],
                {
                    ft = 'OverseerOutput',
                    ---@param win integer
                    filter = function(_buf, win)
                        -- exclude floating windows
                        return vim.api.nvim_win_get_config(win).relative == ''
                    end,
                    title = 'Output',
                    size = { height = 20 },
                } --[[@as Edgy.View.Opts]],
                {
                    ft = 'codediff-history',
                    title = 'Commit History',
                    wo = {
                        winbar = false,
                        listchars = 'extends: ',
                    },
                } --[[@as Edgy.View.Opts]],
            },
        }
        local edgy = require('edgy') --[[@as Edgy]]
        edgy.setup(opts)
    end,
}
