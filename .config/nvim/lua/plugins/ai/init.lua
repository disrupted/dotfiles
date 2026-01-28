local icons = require 'conf.icons'

---@module 'lazy.types'
---@type LazySpec[]
return {
    {
        'sudo-tee/opencode.nvim',
        enabled = true,
        lazy = true,
        name = 'opencode-native',
        cmd = 'Opencode',
        init = function()
            require('which-key').add {
                {
                    '<leader>a',
                    group = 'Agent',
                    icon = { icon = '', hl = 'DiagnosticWarn' },
                },
                {
                    '<leader>ag',
                    ':Opencode<CR>',
                    desc = 'Toggle window',
                    icon = icons.misc.window,
                },
            }
        end,
        dependencies = {
            {
                'MeanderingProgrammer/render-markdown.nvim',
                enabled = true,
                lazy = false,
                cmd = 'RenderMarkdown',
                ft = { 'opencode_output' },
                opts = {
                    debounce = 50,
                    file_types = { 'markdown', 'opencode_output' },
                    render_modes = { 'n', 'i', 'v', 'V', 'c', 't' },
                    anti_conceal = {
                        enabled = true,
                        disabled_modes = { 'n' },
                        ignore = {},
                    },
                    indent = {
                        enabled = true,
                        skip_level = 2,
                        skip_heading = true,
                        icon = ' ',
                        highlight = 'Whitespace',
                    },
                    win_options = {
                        concealcursor = {
                            rendered = 'nvic',
                        },
                    },
                    heading = {
                        backgrounds = {},
                        width = 'block',
                        sign = false,
                        icons = {
                            '', -- 󰉫󰬺
                            '', -- 󰉬󰬻
                            '', -- 󰉭󰬼
                            '', -- 󰉮󰬽
                            '', -- 󰉯󰬾
                            '', -- 󰉰󰬿
                        },
                        position = 'inline',
                        -- border = {
                        --     true, -- h1
                        --     true, -- h2
                        --     false, -- h3
                        --     false, -- h4
                        --     false, -- h5
                        --     false, -- h6
                        -- },
                        border_virtual = true,
                    },
                    code = {
                        sign = false,
                        language_icon = true,
                        language_name = true,
                        language_info = true,
                    },
                    bullet = {
                        icons = {
                            '•',
                            '◦',
                            '•',
                            '◦',
                        },
                    },
                    checkbox = {
                        enabled = true,
                        unchecked = {
                            icon = '󰄱',
                            highlight = 'RenderMarkdownUnchecked',
                        },
                        checked = {
                            icon = '✔',
                            highlight = 'RenderMarkdownChecked',
                        },
                        custom = {
                            todo = {
                                raw = '[-]',
                                rendered = '󰄮',
                                highlight = 'RenderMarkdownTodo',
                            },
                        },
                    },
                },
            },
        },
        opts = {
            preferred_picker = 'snacks',
            preferred_completion = 'blink',
            default_global_keymaps = false,
            keymap_prefix = '<leader>a',
            keymap = {
                editor = {
                    -- ['<leader>ai'] = { 'open_input' }, -- Opens and focuses on input window on insert mode
                    -- ['<leader>ao'] = { 'open_output' }, -- Opens and focuses on output window
                    -- ['<leader>at'] = { 'toggle_focus' },
                    ['<leader>aT'] = { 'timeline', desc = 'Timeline' }, -- Display timeline picker to navigate/undo/redo/fork messages
                    -- ['<leader>aq'] = { 'close', desc = 'Close' },
                    ['<leader>as'] = {
                        'select_session',
                        desc = 'Select session',
                    },
                    ['<leader>aR'] = {
                        'rename_session',
                        desc = 'Rename session',
                    },
                    ['<leader>an'] = {
                        'open_input_new_session',
                        desc = 'New session',
                    },
                    ['<leader>az'] = { 'toggle_zoom', desc = 'Zoom window' },
                    -- ['<leader>ad'] = { 'diff_open', desc = 'Open diff' },
                    -- ['<leader>a]'] = { 'diff_next', desc = 'Next diff' },
                    -- ['<leader>a['] = { 'diff_prev', desc = 'Prev diff' },
                    -- ['<leader>ac'] = { 'diff_close', desc = 'Close diff' },
                    -- ['<leader>ara'] = { 'diff_revert_all_last_prompt' }, -- Revert all file changes since the last opencode prompt
                    -- ['<leader>art'] = { 'diff_revert_this_last_prompt' }, -- Revert current file changes since the last opencode prompt
                    -- ['<leader>arA'] = { 'diff_revert_all' }, -- Revert all file changes since the last opencode session
                    -- ['<leader>arT'] = { 'diff_revert_this' }, -- Revert current file changes since the last opencode session
                    -- ['<leader>arr'] = { 'diff_restore_snapshot_file' }, -- Restore a file to a restore point
                    -- ['<leader>arR'] = { 'diff_restore_snapshot_all' }, -- Restore all files to a restore point
                    ['<leader>a/'] = {
                        'quick_chat',
                        desc = 'Quick chat',
                        mode = { 'n', 'x' },
                    }, -- Open quick chat input with selection context in visual mode or current line context in normal mode
                },
                input_window = {
                    ['<leader>aS'] = false,
                    ['<leader>aD'] = false,
                    ['<leader>aO'] = false,
                    ['<leader>ads'] = false,
                    ['<leader>an'] = {
                        'open_input_new_session',
                        desc = 'New session',
                    },
                    ['<cr>'] = { 'submit_input_prompt', mode = { 'n' } },
                    ['<esc>'] = false,
                    ['<C-c>'] = { 'cancel' },
                    ['q'] = { 'close' },
                    ['~'] = { 'mention_file', mode = 'i' }, -- Pick a file and add to context. See File Mentions section
                    ['@'] = { 'mention', mode = 'i' }, -- Insert mention (file/agent)
                    ['/'] = { 'slash_commands', mode = { 'n', 'i' } },
                    ['#'] = { 'context_items', mode = 'i' }, -- Manage context items (current file, selection, diagnostics, mentioned files)
                    -- ['<M-v>'] = { 'paste_image', mode = 'i' }, -- Paste image from clipboard as attachment
                    -- ['<C-i>'] = { 'focus_input', mode = { 'n', 'i' } }, -- Focus on input window and enter insert mode at the end of the input from the output window
                    ['<tab>'] = { 'toggle_pane', mode = 'n' }, -- Toggle between input and output panes
                    ['<S-tab>'] = { 'switch_mode' }, -- Switch between modes (build/plan)
                    -- ['<up>'] = { 'prev_prompt_history', mode = { 'n', 'i' } }, -- Navigate to previous prompt in history
                    -- ['<down>'] = { 'next_prompt_history', mode = { 'n', 'i' } }, -- Navigate to next prompt in history
                    ['<M-r>'] = { 'cycle_variant', mode = { 'n', 'i' } }, -- Cycle through available model variants
                    ['<A-p>'] = {
                        function()
                            vim.cmd.Opencode 'models'
                        end,
                    },
                },
                output_window = {
                    ['<leader>aS'] = false,
                    ['<leader>aD'] = false,
                    ['<leader>aO'] = false,
                    ['<leader>ads'] = false,
                    ['<leader>at'] = {
                        'toggle_tool_output',
                        desc = 'Toggle tool visibility',
                    },
                    ['<leader>ar'] = {
                        'toggle_reasoning_output',
                        desc = 'Toggle reasoning visibility',
                    },
                    ['q'] = { 'close' },
                    ['<esc>'] = false,
                    ['<C-c>'] = { 'cancel' },
                    ['i'] = { 'focus_input' },
                    ['a'] = { 'focus_input' },
                    ['A'] = { 'focus_input' },
                    ['<S-tab>'] = { 'switch_mode' }, -- Switch between modes (build/plan)
                    ['<M-r>'] = { 'cycle_variant' }, -- Cycle through available model variants
                    ['<A-p>'] = {
                        function()
                            vim.cmd.Opencode 'models'
                        end,
                    },
                    [']a'] = { 'next_message', desc = 'Next message' },
                    ['[a'] = { 'prev_message', desc = 'Prev message' },
                },
            },
            ui = {
                position = 'right',
                input = {
                    text = {
                        wrap = true,
                    },
                    auto_hide = true,
                },
                output = {
                    tools = {
                        show_output = true,
                        show_reasoning_output = false,
                    },
                    rendering = {
                        markdown_debounce_ms = 100,
                    },
                },
                window_highlight = 'Normal:OpencodeBackground,FloatBorder:OpencodeBorder,SignColumn:OpencodeSignColumn,WinSeparator:OpencodeWinSeparator',
                icons = {
                    overrides = {
                        header_user = '▌', -- ▌❯
                        header_assistant = '',
                        run = '',
                        task = '',
                        read = '',
                        edit = '',
                        write = '',
                        plan = '󰝖',
                        search = '',
                        web = '󰖟',
                        list = '',
                        tool = '',
                        snapshot = '󰻛',
                        restore_point = '󱗚',
                        file = '',
                        folder = '',
                        attached_file = '󰌷',
                        agent = '󰚩',
                        reference = '',
                        reasoning = '󰧑',
                        question = '',
                        -- statuses
                        status_on = '',
                        status_off = '',
                        guard_on = '',
                        -- borders and misc
                        border = '▌',
                        -- context bar
                        attached_file = '󰌷 ',
                        cursor_data = '󰗧 ',
                        error = ' ',
                        warning = ' ',
                        info = ' ',
                        filter = '/',
                        selection = '󰫙 ',
                        command = ' ',
                        bash = ' ',
                        preferred = ' ',
                        last_used = '󰃰 ',
                    },
                },
            },
            context = {
                diagnostics = {
                    info = false,
                    warn = false,
                    error = true,
                    only_closest = true,
                },
            },
            debug = {
                enabled = false,
                show_ids = false,
            },
        },
        config = function(_, opts)
            require('opencode').setup(opts)

            vim.api.nvim_create_autocmd('FileType', {
                pattern = { 'opencode' },
                callback = function(args)
                    -- scheduling is necessary because on FileType event the buffer is not assigned to a window yet
                    vim.schedule(function()
                        for _, win in ipairs(vim.api.nvim_list_wins()) do
                            if vim.api.nvim_win_get_buf(win) == args.buf then
                                vim.wo[win].fillchars = 'eob: '
                                -- vim.wo[win].signcolumn = 'no'
                                vim.wo[win].statuscolumn = ''
                                vim.wo[win].cursorline = false
                                -- vim.wo[win].cursorlineopt = 'line'
                                -- vim.bo[args.buf].wrapmargin = 2
                                -- vim.wo[win].winhighlight = 'Normal:OpencodeInput'
                                return
                            end
                        end
                    end)
                end,
            })

            vim.api.nvim_create_autocmd('FileType', {
                pattern = { 'opencode_output' },
                callback = function(args)
                    -- scheduling is necessary because on FileType event the buffer is not assigned to a window yet
                    vim.schedule(function()
                        for _, win in ipairs(vim.api.nvim_list_wins()) do
                            if vim.api.nvim_win_get_buf(win) == args.buf then
                                vim.wo[win].fillchars = 'eob: '
                                vim.wo[win].cursorline = false
                                -- vim.wo[win].wrap = false
                                -- vim.wo[win].conceallevel = 3
                                return
                            end
                        end
                    end)
                end,
            })
        end,
    },
    {
        'coder/claudecode.nvim',
        enabled = false,
        name = 'claudecode-tui',
        cmd = 'ClaudeCode',
        keys = {
            {
                '<leader>ac',
                '<cmd>ClaudeCode<cr>',
                mode = { 'n', 't' },
                desc = 'Toggle Claude',
            },
        },
        opts = {
            terminal = {
                split_side = 'right',
                split_width_percentage = 0.40,
                provider = 'snacks',
                auto_close = true,
            },
        },
    },
    {
        'NickvanDyke/opencode.nvim',
        enabled = false,
        init = function()
            require('which-key').add {
                {
                    '<leader>a',
                    group = 'Agent',
                    icon = { icon = '', hl = 'DiagnosticWarn' },
                },
            }
        end,
        keys = {
            {
                '<leader>ao',
                function()
                    require('opencode').toggle()
                end,
                mode = { 'n', 't' },
                desc = 'Toggle opencode',
            },
            {
                '<leader>aa',
                function()
                    require('opencode').ask('@this: ', { submit = true })
                end,
                mode = { 'x' },
                desc = 'Ask…',
            },
            {
                '<leader>ax',
                function()
                    require('opencode').select()
                end,
                mode = { 'n', 'x' },
                desc = 'Execute action…',
            },
        },
        config = function()
            ---@module 'opencode.config'
            ---@type opencode.Opts
            vim.g.opencode_opts = {
                provider = {
                    enabled = vim.env.TMUX ~= nil and 'tmux' or 'snacks',
                },
            }

            vim.keymap.set({ 'n', 'x' }, 'go', function()
                return require('opencode').operator '@this '
            end, { desc = 'Add range to opencode', expr = true })
            vim.keymap.set('n', 'goo', function()
                return require('opencode').operator '@this ' .. '_'
            end, { desc = 'Add line to opencode', expr = true })

            vim.keymap.set('n', '<S-C-u>', function()
                require('opencode').command 'session.half.page.up'
            end, { desc = 'Opencode scroll up' })
            vim.keymap.set('n', '<S-C-d>', function()
                require('opencode').command 'session.half.page.down'
            end, { desc = 'Opencode scroll down' })

            vim.api.nvim_create_autocmd('User', {
                pattern = 'OpencodeEvent:*',
                callback = function(args)
                    ---@type opencode.cli.client.Event
                    local event = args.data.event

                    if event.type == 'session.idle' then
                        Snacks.notify('finished', {
                            title = 'opencode',
                        })
                        return
                    end
                    if
                        event.type == 'server.connected'
                        or event.type == 'server.heartbeat'
                        -- or vim.startswith(event.type, 'session.')
                        -- or vim.startswith(event.type, 'message.')
                    then
                        return
                    end
                    Snacks.notify(vim.inspect(event), {
                        level = vim.log.levels.DEBUG,
                        title = 'opencode',
                    })
                end,
            })
        end,
    },
}
