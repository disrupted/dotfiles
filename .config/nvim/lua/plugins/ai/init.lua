local icons = require 'conf.icons'

---@module 'lazy.types'
---@type LazySpec[]
return {
    {
        'sudo-tee/opencode.nvim',
        lazy = true,
        name = 'opencode-native',
        cmd = 'Opencode',
        init = function()
            require('which-key').add {
                {
                    '<leader>a',
                    group = 'Agent',
                    mode = { 'n', 'x' },
                    icon = { icon = '', hl = 'DiagnosticWarn' },
                },
                {
                    '<BS>',
                    ':Opencode<CR>',
                    desc = 'Toggle Agent',
                    icon = icons.misc.window,
                },
                {
                    '<M-BS>',
                    ':Opencode quick_chat<CR>',
                    desc = 'Quick chat',
                    -- Open quick chat input with selection context in visual mode or current line context in normal mode
                    mode = { 'n', 'x' },
                    icon = { icon = '', hl = 'DiagnosticWarn' },
                },
            }
        end,
        dependencies = {
            {
                'folke/snacks.nvim',
                opts = {
                    picker = {
                        actions = {
                            opencode_send = function(picker)
                                local selected =
                                    picker:selected { fallback = true }
                                if selected and #selected > 0 then
                                    local files = {}
                                    for _, item in ipairs(selected) do
                                        if item.file then
                                            table.insert(files, item.file)
                                        end
                                    end
                                    if #files == 0 then
                                        Snacks.notify.warn(
                                            'Please select files to send as context',
                                            { title = 'Agent' }
                                        )
                                        return
                                    end
                                    picker:close()

                                    require('opencode.core').open {
                                        new_session = false,
                                        focus = 'input',
                                        start_insert = true,
                                    }

                                    local context = require 'opencode.context'
                                    for _, file in ipairs(files) do
                                        context.add_file(file)
                                    end
                                end
                            end,
                        },
                        win = {
                            input = {
                                keys = {
                                    ['<C-a>'] = {
                                        'opencode_send',
                                        mode = { 'n', 'i' },
                                    },
                                },
                            },
                        },
                    },
                },
            },
            {
                'MeanderingProgrammer/render-markdown.nvim',
                cmd = 'RenderMarkdown',
                ft = { 'opencode_output' },
                opts = {
                    debounce = 50,
                    file_types = { 'opencode_output' },
                    render_modes = { 'n', 'i', 'v', 'V', 'c', 't' },
                    anti_conceal = {
                        enabled = false,
                        disabled_modes = { 'n' },
                        ignore = {},
                    },
                    -- indent = {
                    --     enabled = true,
                    --     skip_level = 3,
                    --     skip_heading = true,
                    --     icon = ' ',
                    --     highlight = 'Whitespace',
                    -- },
                    win_options = {
                        concealcursor = {
                            rendered = 'nvc',
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
                        width = 'block',
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
        ---@module 'opencode'
        ---@type OpencodeConfig
        opts = {
            preferred_picker = 'snacks',
            preferred_completion = 'blink',
            default_global_keymaps = false,
            keymap_prefix = '<leader>a',
            keymap = {
                editor = {
                    ['<C-a>'] = { 'open_input', desc = 'Input' },
                    -- ['<leader>ao'] = { 'open_output' }, -- Opens and focuses on output window
                    -- ['<leader>at'] = { 'toggle_focus' },
                    ['<leader>aT'] = {
                        'timeline',
                        desc = 'Timeline',
                        mode = 'n',
                    }, -- Display timeline picker to navigate/undo/redo/fork messages
                    -- ['<leader>aq'] = { 'close', desc = 'Close' },
                    ['<leader>as'] = {
                        'select_session',
                        desc = 'Select session',
                        mode = 'n',
                    },
                    ['<leader>aR'] = {
                        'rename_session',
                        desc = 'Rename session',
                        mode = 'n',
                    },
                    ['<leader>an'] = {
                        'open_input_new_session',
                        desc = 'New session',
                        mode = 'n',
                    },
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
                },
                input_window = {
                    ['<leader>ai'] = false, -- FIXME
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
                    ['<C-c>'] = { 'cancel', mode = { 'n', 'i' } },
                    ['q'] = { 'toggle_pane' }, -- Toggle between input and output panes
                    ['~'] = false, -- disabled since I use Snacks file picker instead
                    -- ['~'] = { 'mention_file', mode = 'i' }, -- Pick a file and add to context. See File Mentions section
                    ['@'] = { 'mention', mode = 'i' }, -- Insert mention (file/agent)
                    ['/'] = { 'slash_commands', mode = 'i' },
                    ['#'] = { 'context_items', mode = 'i' }, -- Manage context items (current file, selection, diagnostics, mentioned files)
                    -- ['<M-v>'] = { 'paste_image', mode = 'i' }, -- Paste image from clipboard as attachment
                    -- ['<C-i>'] = { 'focus_input', mode = { 'n', 'i' } }, -- Focus on input window and enter insert mode at the end of the input from the output window
                    ['<tab>'] = false,
                    ['<S-tab>'] = { 'switch_mode', mode = { 'n', 'i' } }, -- Switch between modes (build/plan)
                    -- ['<up>'] = { 'prev_prompt_history', mode = { 'n', 'i' } }, -- Navigate to previous prompt in history
                    -- ['<down>'] = { 'next_prompt_history', mode = { 'n', 'i' } }, -- Navigate to next prompt in history
                    ['<M-r>'] = { 'cycle_variant', mode = { 'n', 'i' } }, -- Cycle through available model variants
                    ['<M-p>'] = {
                        function()
                            vim.cmd.Opencode 'models'
                        end,
                        desc = 'Pick model',
                        mode = { 'n', 'i' },
                    },
                },
                output_window = {
                    ['<leader>ai'] = false, -- FIXME
                    ['<leader>aS'] = false,
                    ['<leader>aD'] = { 'debug_message' },
                    ['<leader>aO'] = { 'debug_output' },
                    ['<leader>ads'] = { 'debug_session' },
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
                    ['a'] = { 'permission_accept', mode = 'n' },
                    ['A'] = { 'permission_accept_all', mode = 'n' },
                    ['d'] = { 'permission_deny', mode = 'n' },
                    ['<tab>'] = false,
                    ['<S-tab>'] = { 'switch_mode' }, -- Switch between modes (build/plan)
                    ['<M-r>'] = { 'cycle_variant' }, -- Cycle through available model variants
                    ['<M-p>'] = {
                        function()
                            vim.cmd.Opencode 'models'
                        end,
                        desc = 'Pick model',
                    },
                    ['S'] = { 'select_child_session' },
                    [']]'] = { 'next_message', desc = 'Next message' },
                    ['[['] = { 'prev_message', desc = 'Prev message' },
                },
            },
            ui = {
                position = 'right',
                keep_buffers_on_toggle = true,
                zoom_width = 0.6,
                input = {
                    -- min_height = 0.10,
                    -- max_height = 0.35,
                    min_height = 0.25,
                    max_height = 0.25,
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
                        header_user = '▌',
                        header_assistant = '',
                        run = '',
                        task = '',
                        read = '',
                        edit = '',
                        write = '',
                        plan = '󰝖',
                        search = '',
                        web = '󰖟',
                        list = '󱎸',
                        tool = '',
                        snapshot = '󰻛',
                        restore_point = '󱗚',
                        file = icons.documents.file,
                        folder = icons.documents.folder,
                        agent = '󰚩',
                        reference = icons.documents.file_empty .. ' ',
                        reasoning = '󱍎',
                        question = '?',
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
                        last_used = ' ',
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
                current_file = {
                    enabled = false,
                    show_full_path = false,
                },
            },
            debug = {
                enabled = true,
                capture_streamed_events = true,
                show_ids = false,
            },
            hooks = {
                on_done_thinking = function()
                    Snacks.notify('Finished', { title = 'Agent' })
                end,
            },
        },
        config = function(_, opts)
            require('opencode').setup(opts)

            require('which-key').add {
                {
                    '<leader>ap',
                    group = 'Permission',
                    icon = { icon = '󰳈' },
                },
                {
                    '<leader>an',
                    desc = 'New session',
                    icon = '󱐏',
                },
                {
                    '<S-BS>',
                    function()
                        for _, win in ipairs(vim.api.nvim_list_wins()) do
                            local buf = vim.api.nvim_win_get_buf(win)
                            if vim.bo[buf].filetype == 'opencode_output' then
                                if vim.w[win]['edgy_width'] == nil then
                                    vim.w[win]['edgy_width'] = 115
                                else
                                    vim.w[win]['edgy_width'] = nil
                                end
                                require('edgy.layout').update()
                                return
                            end
                        end
                    end,
                    desc = 'Zoom window',
                    icon = icons.misc.window,
                },
                {
                    '<leader>aR',
                    desc = 'Rename session',
                    icon = '󰑕',
                },
                {
                    '<leader>as',
                    desc = 'Select session',
                    icon = '󱅳',
                },
                {
                    '<leader>aT',
                    desc = 'Timeline',
                    icon = '󱇼',
                },
                {
                    '<C-a>',
                    desc = 'Input + selection',
                    mode = 'v',
                    icon = { icon = '󰐒', color = 'blue' },
                },
                {
                    '<C-a>',
                    desc = 'Input',
                    mode = 'n',
                    icon = '󰲔',
                },
            }

            vim.api.nvim_create_autocmd('User', {
                pattern = 'OpencodeEvent:permission.asked',
                callback = function(args)
                    -- local event = args.data.event
                    -- Snacks.notify(
                    --     { 'permission requested', vim.inspect(event) },
                    --     { title = 'Agent' }
                    -- )
                    require('which-key').add {
                        {
                            '<leader>apa',
                            '<cmd>Opencode permission accept<CR>',
                            desc = 'Accept',
                            icon = { icon = '', hl = 'DiagnosticOk' },
                        },
                        {
                            '<leader>apA',
                            '<cmd>Opencode permission accept_all<CR>',
                            desc = 'Accept all',
                            icon = { icon = '', hl = 'DiagnosticOk' },
                        },
                        {
                            '<leader>apd',
                            '<cmd>Opencode permission deny<CR>',
                            desc = 'Deny',
                            icon = { icon = '', hl = 'DiagnosticError' },
                        },
                    }
                end,
            })
            vim.api.nvim_create_autocmd('User', {
                pattern = 'OpencodeEvent:permission.replied',
                callback = function(args)
                    if
                        vim.tbl_isempty(
                            require('opencode.state').pending_permissions
                        )
                    then
                        local keymaps =
                            { '<leader>apa', '<leader>apA', '<leader>apd' }
                        for _, keymap in ipairs(keymaps) do
                            vim.keymap.del('n', keymap)
                        end
                        require('which-key').add {
                            { '<leader>apa' },
                            { '<leader>apA' },
                            { '<leader>apd' },
                            hidden = true,
                        }
                    end
                end,
            })

            vim.g.agent_follow_edits = true -- I believe ACP would make this more seamless

            vim.api.nvim_create_autocmd('User', {
                pattern = 'OpencodeEvent:file.edited',
                callback = function(args)
                    ---@type string?
                    local abspath = args.data.event.file
                    if not abspath or not vim.g.workspace_root then
                        return
                    end
                    local relpath =
                        vim.fs.relpath(vim.g.workspace_root, abspath)
                    if not relpath then
                        return
                    end
                    Snacks.notify(
                        string.format('edit %s', relpath),
                        { title = 'Agent' }
                    )
                    if not vim.g.agent_follow_edits then
                        return
                    end
                    local bufnr = vim.fn.bufnr(abspath, true)
                    if not api.nvim_buf_is_loaded(bufnr) then
                        pcall(vim.fn.bufload, bufnr)
                    end
                    -- local ok = pcall(api.nvim_win_set_buf, code_winid, bufnr)
                    -- if not ok then
                    --     return
                    -- end
                end,
            })

            -- NOTE: disabled in favor of edgy.nvim
            -- vim.api.nvim_create_autocmd('FileType', {
            --     pattern = { 'opencode' },
            --     callback = function(args)
            --         -- scheduling is necessary because on FileType event the buffer is not assigned to a window yet
            --         vim.schedule(function()
            --             for _, win in ipairs(vim.api.nvim_list_wins()) do
            --                 if vim.api.nvim_win_get_buf(win) == args.buf then
            --                     vim.wo[win].fillchars = 'eob: '
            --                     -- vim.wo[win].signcolumn = 'no'
            --                     vim.wo[win].statuscolumn = ''
            --                     vim.wo[win].cursorline = false
            --                     -- vim.wo[win].cursorlineopt = 'line'
            --                     -- vim.bo[args.buf].wrapmargin = 2
            --                     -- vim.wo[win].winhighlight = 'Normal:OpencodeInput'
            --                     return
            --                 end
            --             end
            --         end)
            --     end,
            -- })

            -- vim.api.nvim_create_autocmd('FileType', {
            --     pattern = { 'opencode_output' },
            --     callback = function(args)
            --         -- scheduling is necessary because on FileType event the buffer is not assigned to a window yet
            --         vim.schedule(function()
            --             for _, win in ipairs(vim.api.nvim_list_wins()) do
            --                 if vim.api.nvim_win_get_buf(win) == args.buf then
            --                     vim.wo[win].fillchars = 'eob: '
            --                     vim.wo[win].cursorline = false
            --                     -- vim.wo[win].wrap = false
            --                     -- vim.wo[win].conceallevel = 3
            --                     return
            --                 end
            --             end
            --         end)
            --     end,
            -- })
        end,
    },
    {
        'guill/mcp-tools.nvim',
        enabled = false,
        event = 'VeryLazy',
        build = 'bun install --cwd ./bridge',
        config = function()
            require('mcp-tools').setup {
                tools = {
                    dap = true,
                    diagnostics = true,
                    lsp = true,
                },
                integrations = {
                    opencode = true,
                },
                on_ready = function(port)
                    print('MCP bridge ready on port ' .. port)
                end,
                on_stop = function()
                    print 'MCP bridge stopped'
                end,
            }
        end,
    },
    {
        'linw1995/nvim-mcp',
        enabled = false,
        event = 'VeryLazy',
        build = 'cargo install --path .',
        opts = {},
    },
}
