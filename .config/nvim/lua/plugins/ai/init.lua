---@module 'lazy.types'
---@type LazySpec[]
return {
    {
        'sudo-tee/opencode.nvim',
        enabled = true,
        name = 'opencode-native',
        cmd = 'Opencode',
        init = function()
            require('which-key').add {
                {
                    '<Leader>a',
                    group = 'Agent',
                    icon = { icon = '', hl = 'DiagnosticWarn' },
                },
            }
        end,
        keys = {
            {
                '<Leader>ag',
                ':Opencode<CR>',
                -- mode = { 'n', 't' },
                desc = 'Opencode',
            },
        },
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
                        -- per_level = 2,
                        -- skip_level = 1,
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
                        sign = false,
                        width = 'block',
                        backgrounds = {},
                        -- position = 'overlay',
                        position = 'inline',
                        icons = {
                            '󰬺 ',
                            '󰬻 ',
                            '󰬼 ',
                            '󰬽 ',
                            '󰬾 ',
                            '󰬿 ',
                        },
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
                            icon = '✔', -- 
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
            {
                'OXY2DEV/markview.nvim',
                enabled = false,
                lazy = false,
                cmd = 'Markview',
                ft = { 'opencode_output' },
                opts = function()
                    return {
                        markdown = {
                            headings = require('markview.presets').headings.glow,
                            code_blocks = {
                                enable = true,

                                -- border_hl = 'MarkviewCode',
                                -- info_hl = 'MarkviewCodeInfo',

                                label_direction = 'right',
                                -- label_hl = nil,

                                -- min_width = 60,
                                pad_amount = 0,
                                -- pad_char = ' ',

                                -- default = {
                                --     block_hl = 'MarkviewCode',
                                --     pad_hl = 'MarkviewCode',
                                -- },

                                -- ['diff'] = {
                                --     block_hl = function(_, line)
                                --         if line:match '^%+' then
                                --             return 'MarkviewPalette4'
                                --         elseif line:match '^%-' then
                                --             return 'MarkviewPalette1'
                                --         else
                                --             return 'MarkviewCode'
                                --         end
                                --     end,
                                --     pad_hl = 'MarkviewCode',
                                -- },

                                style = 'simple',
                                sign = false,
                            },
                            tables = {
                                use_virt_lines = true,
                            },
                        },
                        preview = {
                            enable = true,
                            condition = function(buf)
                                if
                                    vim.bo[buf].filetype == 'opencode_output'
                                then
                                    return true
                                end
                                return nil -- use default filetype/buftype detection
                            end,
                        },
                    }
                end,
            },
        },
        opts = {
            preferred_picker = 'snacks',
            preferred_completion = 'blink',
            default_global_keymaps = false,
            keymap_prefix = '<Leader>a',
            keymap = {
                editor = {
                    ['<Leader>ai'] = { 'open_input' }, -- Opens and focuses on input window on insert mode
                    ['<Leader>aI'] = { 'open_input_new_session' }, -- Opens and focuses on input window on insert mode. Creates a new session
                    ['<Leader>ao'] = { 'open_output' }, -- Opens and focuses on output window
                    ['<Leader>at'] = { 'toggle_focus' }, -- Toggle focus between opencode and last window
                    ['<Leader>aT'] = { 'timeline' }, -- Display timeline picker to navigate/undo/redo/fork messages
                    ['<Leader>aq'] = { 'close' }, -- Close UI windows
                    ['<Leader>as'] = { 'select_session' }, -- Select and load a opencode session
                    ['<Leader>aR'] = { 'rename_session' }, -- Rename current session
                    ['<Leader>ap'] = { 'configure_provider' }, -- Quick provider and model switch from predefined list
                    ['<Leader>aV'] = { 'configure_variant' }, -- Switch model variant for the current model
                    ['<Leader>az'] = { 'toggle_zoom' }, -- Zoom in/out on the Opencode windows
                    ['<Leader>av'] = { 'paste_image' }, -- Paste image from clipboard into current session
                    ['<Leader>ad'] = { 'diff_open' }, -- Opens a diff tab of a modified file since the last opencode prompt
                    ['<Leader>a]'] = { 'diff_next' }, -- Navigate to next file diff
                    ['<Leader>a['] = { 'diff_prev' }, -- Navigate to previous file diff
                    ['<Leader>ac'] = { 'diff_close' }, -- Close diff view tab and return to normal editing
                    ['<Leader>ara'] = { 'diff_revert_all_last_prompt' }, -- Revert all file changes since the last opencode prompt
                    ['<Leader>art'] = { 'diff_revert_this_last_prompt' }, -- Revert current file changes since the last opencode prompt
                    ['<Leader>arA'] = { 'diff_revert_all' }, -- Revert all file changes since the last opencode session
                    ['<Leader>arT'] = { 'diff_revert_this' }, -- Revert current file changes since the last opencode session
                    ['<Leader>arr'] = { 'diff_restore_snapshot_file' }, -- Restore a file to a restore point
                    ['<Leader>arR'] = { 'diff_restore_snapshot_all' }, -- Restore all files to a restore point
                    ['<Leader>aa'] = { 'permission_accept' }, -- Accept permission request once
                    ['<Leader>aA'] = { 'permission_accept_all' }, -- Accept all (for current tool)
                    ['<Leader>ad'] = { 'permission_deny' }, -- Deny permission request once
                    -- ['<Leader>att'] = { 'toggle_tool_output' }, -- Toggle tools output (diffs, cmd output, etc.)
                    -- ['<Leader>atr'] = { 'toggle_reasoning_output' }, -- Toggle reasoning output (thinking steps)
                    ['<Leader>a/'] = { 'quick_chat', mode = { 'n', 'x' } }, -- Open quick chat input with selection context in visual mode or current line context in normal mode
                    [']a'] = { 'next_message' },
                    ['[a'] = { 'prev_message' },
                },
                input_window = {
                    ['<cr>'] = { 'submit_input_prompt', mode = { 'n' } },
                    ['<esc>'] = false,
                    ['<C-c>'] = { 'cancel' },
                    ['q'] = { 'close' },
                    ['~'] = { 'mention_file', mode = 'i' }, -- Pick a file and add to context. See File Mentions section
                    ['@'] = { 'mention', mode = 'i' }, -- Insert mention (file/agent)
                    ['/'] = { 'slash_commands', mode = { 'n', 'i' } },
                    -- ['/'] = {
                    --     function()
                    --         vim.print 'slash_commands'
                    --         -- require('opencode.api').slash_commands()

                    --         local ui = require 'opencode.ui.ui'
                    --         -- ui.focus_input {
                    --         --     restore_position = false,
                    --         --     start_insert = true,
                    --         -- }
                    --         -- if vim.fn.mode() ~= 'i' then
                    --         --     vim.api.nvim_feedkeys('a', 'n', false)
                    --         -- end
                    --         vim.api.nvim_command 'startinsert'
                    --         require('opencode.ui.completion').trigger_completion '/'()
                    --         return 'slash_commands'
                    --     end,
                    --     mode = { 'n', 'i' },
                    -- },
                    ['#'] = { 'context_items', mode = 'i' }, -- Manage context items (current file, selection, diagnostics, mentioned files)
                    -- ['<M-v>'] = { 'paste_image', mode = 'i' }, -- Paste image from clipboard as attachment
                    -- ['<C-i>'] = { 'focus_input', mode = { 'n', 'i' } }, -- Focus on input window and enter insert mode at the end of the input from the output window
                    ['<Tab>'] = { 'toggle_pane', mode = { 'n', 'i' } }, -- Toggle between input and output panes
                    ['<S-Tab>'] = { 'switch_mode' }, -- Switch between modes (build/plan)
                    -- ['<up>'] = { 'prev_prompt_history', mode = { 'n', 'i' } }, -- Navigate to previous prompt in history
                    -- ['<down>'] = { 'next_prompt_history', mode = { 'n', 'i' } }, -- Navigate to next prompt in history
                    ['<M-r>'] = { 'cycle_variant', mode = { 'n', 'i' } }, -- Cycle through available model variants
                    ['<A-p>'] = {
                        function()
                            vim.cmd 'Opencode models'
                        end,
                    },
                },
                output_window = {
                    ['q'] = { 'close' },
                    ['<esc>'] = false,
                    ['<C-c>'] = { 'cancel' },
                    ['i'] = { 'focus_input' },
                    ['a'] = { 'focus_input' },
                    ['A'] = { 'focus_input' },
                    ['<S-Tab>'] = { 'switch_mode' }, -- Switch between modes (build/plan)
                    ['<M-r>'] = { 'cycle_variant' }, -- Cycle through available model variants
                    ['<A-p>'] = {
                        function()
                            vim.cmd 'Opencode models'
                        end,
                    },
                },
            },
            ui = {
                position = 'right',
                output = {
                    tools = {
                        show_output = true,
                        show_reasoning_output = false,
                    },
                    rendering = {
                        markdown_debounce_ms = 50,
                    },
                },
                window_highlight = 'Normal:OpencodeBackground,FloatBorder:OpencodeBorder,SignColumn:OpencodeSignColumn,WinSeparator:OpencodeWinSeparator',
                icons = {
                    overrides = {
                        header_user = '▌', -- ▌❯
                        header_assistant = '',
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
                                vim.wo[win].signcolumn = 'no'
                                vim.wo[win].statuscolumn = ''
                                vim.wo[win].cursorline = false
                                -- vim.wo[win].cursorlineopt = 'line'
                                vim.bo[args.buf].wrapmargin = 2
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
                '<Leader>ac',
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
                    '<Leader>a',
                    group = 'Agent',
                    icon = { icon = '', hl = 'DiagnosticWarn' },
                },
            }
        end,
        keys = {
            {
                '<Leader>ao',
                function()
                    require('opencode').toggle()
                end,
                mode = { 'n', 't' },
                desc = 'Toggle opencode',
            },
            {
                '<Leader>aa',
                function()
                    require('opencode').ask('@this: ', { submit = true })
                end,
                mode = { 'x' },
                desc = 'Ask…',
            },
            {
                '<Leader>ax',
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
