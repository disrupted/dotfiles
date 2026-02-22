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
                    ['<C-a>'] = { 'open_input', desc = 'Input', mode = 'n' },
                    ['<C-a>'] = { -- FIXME: should not overwrite normal mode mapping
                        'add_visual_selection',
                        desc = 'Add selection',
                        mode = 'v',
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
                    ['<LocalLeader>n'] = {
                        'open_input_new_session',
                        desc = 'New session',
                    },
                    ['<LocalLeader>R'] = {
                        'rename_session',
                        desc = 'Rename session',
                        mode = 'n',
                    },
                    ['<LocalLeader>S'] = {
                        'select_session',
                        desc = 'Select session',
                        mode = 'n',
                    },
                    ['<cr>'] = { 'submit_input_prompt', mode = 'n' },
                    ['<esc>'] = false,
                    ['<C-c>'] = { 'cancel', mode = { 'n', 'i' } },
                    ['q'] = { 'toggle_pane' }, -- Toggle between input and output panes
                    ['~'] = false, -- disabled since I use Snacks file picker instead
                    ['@'] = { 'mention', mode = 'i' }, -- Insert mention (file/agent)
                    ['/'] = { 'slash_commands', mode = 'i' },
                    ['#'] = { 'context_items', mode = 'i' }, -- Manage context items (current file, selection, diagnostics, mentioned files)
                    ['<tab>'] = false,
                    ['<S-tab>'] = { 'switch_mode', mode = { 'n', 'i' } }, -- Switch between modes (build/plan)
                    ['<up>'] = { 'prev_prompt_history', mode = 'n' }, -- Navigate to previous prompt in history
                    ['<down>'] = { 'next_prompt_history', mode = 'n' }, -- Navigate to next prompt in history
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
                    ['<LocalLeader>n'] = {
                        'open_input_new_session',
                        desc = 'New session',
                    },
                    ['<LocalLeader>R'] = {
                        'rename_session',
                        desc = 'Rename session',
                        mode = 'n',
                    },
                    ['<LocalLeader>S'] = {
                        'select_session',
                        desc = 'Select session',
                        mode = 'n',
                    },
                    ['<LocalLeader>T'] = {
                        'timeline',
                        desc = 'Timeline',
                        mode = 'n',
                    }, -- Display timeline picker to navigate/undo/redo/fork messages
                    ['<LocalLeader>dm'] = { 'debug_message' },
                    ['<LocalLeader>do'] = { 'debug_output' },
                    ['<LocalLeader>ds'] = { 'debug_session' },
                    ['<LocalLeader>t'] = {
                        'toggle_tool_output',
                        desc = 'Toggle tool visibility',
                    },
                    ['<LocalLeader>r'] = {
                        'toggle_reasoning_output',
                        desc = 'Toggle reasoning visibility',
                    },
                    ['q'] = { 'close' },
                    ['<esc>'] = false,
                    ['<C-c>'] = { 'cancel', mode = 'n' },
                    ['i'] = {
                        function()
                            require('opencode.ui.ui').focus_input() -- no start_insert
                        end,
                        mode = 'n',
                    },
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
                    ['<M-i>'] = false,
                    ['<LocalLeader>s'] = {
                        'select_child_session',
                        desc = 'Select child session',
                    },
                    [']]'] = { 'next_message', desc = 'Next message' },
                    ['[['] = { 'prev_message', desc = 'Prev message' },
                },
            },
            ui = {
                position = 'right',
                keep_buffers_on_toggle = true,
                zoom_width = 0.6,
                input = {
                    min_height = 0.10,
                    max_height = 0.35,
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
                    error = false,
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
                    '<C-a>',
                    desc = 'Add selection',
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
                    require('which-key').add {
                        {
                            '<leader>aa',
                            '<cmd>Opencode permission accept<CR>',
                            desc = 'Accept',
                            icon = { icon = '', hl = 'DiagnosticOk' },
                        },
                        {
                            '<leader>aA',
                            '<cmd>Opencode permission accept_all<CR>',
                            desc = 'Accept all',
                            icon = { icon = '', hl = 'DiagnosticOk' },
                        },
                        {
                            '<leader>ad',
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
                            { '<leader>aa', '<leader>aA', '<leader>ad' }
                        for _, keymap in ipairs(keymaps) do
                            vim.keymap.del('n', keymap)
                        end
                        require('which-key').add {
                            { '<leader>aa' },
                            { '<leader>aA' },
                            { '<leader>ad' },
                            hidden = true,
                        }
                    end
                end,
            })

            vim.g.agent_follow_edits = true -- I believe ACP would make this more seamless

            local function is_main_edit_win(winid)
                if not vim.api.nvim_win_is_valid(winid) then
                    return false
                end
                local config = vim.api.nvim_win_get_config(winid)
                if config.relative ~= '' then
                    return false
                end
                return not vim.wo[winid].winfixbuf
            end

            local function get_main_edit_winid()
                local current_winid = vim.api.nvim_get_current_win()
                if is_main_edit_win(current_winid) then
                    return current_winid
                end

                for _, winid in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
                    if is_main_edit_win(winid) then
                        return winid
                    end
                end
            end

            vim.api.nvim_create_autocmd('User', {
                pattern = 'OpencodeEvent:file.edited',
                callback = function(args)
                    ---@type string
                    local abspath = args.data.event.properties.file
                    if not vim.g.workspace_root then
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
                    if not vim.api.nvim_buf_is_loaded(bufnr) then
                        pcall(vim.fn.bufload, bufnr)
                    end
                    local main_winid = get_main_edit_winid()
                    if not main_winid then
                        return
                    end
                    local ok =
                        pcall(vim.api.nvim_win_set_buf, main_winid, bufnr)
                    if not ok then
                        return
                    end
                end,
            })

            local input_window = require 'opencode.ui.input_window'
            input_window.schedule_resize = function() end

            vim.api.nvim_create_autocmd('FileType', {
                pattern = { 'opencode' },
                callback = function(args)
                    require('which-key').add {
                        buffer = args.buf,
                        {
                            '<LocalLeader>',
                            group = 'Agent',
                            icon = { icon = '', hl = 'DiagnosticWarn' },
                        },
                        {
                            '<LocalLeader>n',
                            desc = 'New session',
                            icon = '󱐏',
                        },
                        {
                            '<LocalLeader>R',
                            desc = 'Rename session',
                            icon = '󰑕',
                        },
                        {
                            '<LocalLeader>S',
                            desc = 'Select session',
                            icon = '󱅳',
                        },
                    }

                    -- TODO: auto resize input window with edgy
                    --[[ local function get_content_height(windows)
                        local line_count =
                            vim.api.nvim_buf_line_count(windows.input_buf)
                        if line_count <= 0 then
                            return 1
                        end
                        local ok, result = pcall(
                            vim.api.nvim_win_text_height,
                            windows.input_win,
                            {
                                start_row = 0,
                                end_row = math.max(0, line_count - 1),
                            }
                        )
                        if ok and result and result.all then
                            return result.all
                        end

                        return line_count
                    end
                    local function calculate_height(windows)
                        local total_height =
                            vim.api.nvim_get_option_value('lines', {})
                        local min_height = 5
                        local max_height = 40
                        local content_height = get_content_height(windows)
                        vim.print('content height', content_height)
                        local content_height = content_height + 1 -- context winbar
                        return math.min(
                            max_height,
                            math.max(min_height, content_height)
                        )
                    end

                    input_window.schedule_resize = function(windows)
                        vim.defer_fn(function()
                            local height = calculate_height(windows)
                            vim.w[windows.input_win]['edgy_height'] = height
                            vim.print('height', height)
                            require('edgy.layout').update()
                        end, 1000 / 60) -- throttle to 60 FPS
                    end ]]
                end,
            })

            vim.api.nvim_create_autocmd('FileType', {
                pattern = { 'opencode_output' },
                callback = function(args)
                    require('which-key').add {
                        buffer = args.buf,
                        {
                            '<LocalLeader>',
                            group = 'Agent',
                            icon = { icon = '', hl = 'DiagnosticWarn' },
                        },
                        {
                            '<LocalLeader>n',
                            desc = 'New session',
                            icon = '󱐏',
                        },
                        {
                            '<LocalLeader>R',
                            desc = 'Rename session',
                            icon = '󰑕',
                        },
                        {
                            '<LocalLeader>S',
                            desc = 'Select session',
                            icon = '󱅳',
                        },
                        {
                            '<LocalLeader>s',
                            desc = 'Select child session',
                            icon = '󰚩',
                        },
                        {
                            '<LocalLeader>T',
                            desc = 'Timeline',
                            icon = '󱇼',
                        },
                        {
                            '<S-BS>',
                            function()
                                local win = (
                                    require('opencode.state').windows or {}
                                ).output_win
                                if win and vim.api.nvim_win_is_valid(win) then
                                    if vim.w[win]['edgy_width'] == nil then
                                        vim.w[win]['edgy_width'] = 110
                                    else
                                        vim.w[win]['edgy_width'] = nil
                                    end
                                    require('edgy.layout').update()
                                end
                            end,
                            desc = 'Zoom window',
                            icon = icons.misc.window,
                        },
                    }

                    require('which-key').add {
                        {
                            '<S-BS>',
                            function()
                                local win = (
                                    require('opencode.state').windows or {}
                                ).output_win
                                if win and vim.api.nvim_win_is_valid(win) then
                                    if vim.w[win]['edgy_width'] == nil then
                                        vim.w[win]['edgy_width'] = 110
                                    else
                                        vim.w[win]['edgy_width'] = nil
                                    end
                                    require('edgy.layout').update()
                                end
                            end,
                            desc = 'Zoom window',
                            icon = icons.misc.window,
                        },
                    }
                end,
            })
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
