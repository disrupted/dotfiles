local icons = require 'conf.icons'

---@type zpack.Spec[]
return {
    'disrupted/pi.nvim',
    -- 'gilad-hecht-cyera/pi.nvim',
    cond = vim.env.ANTHROPIC_API_KEY == nil,
    cmd = 'Pi',
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
                ':Pi<CR>',
                desc = 'Toggle Agent',
                icon = icons.misc.window,
            },
        }
    end,
    dependencies = {
        {
            'disrupted/snacks.nvim',
            opts = {
                picker = {
                    actions = {
                        pi_send = function(picker)
                            local selected = picker:selected { fallback = true }
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
                                        { title = 'Agent', icon = '' }
                                    )
                                    return
                                end
                                picker:close()

                                require('pi.services.session_runtime').open {
                                    new_session = false,
                                    focus = 'input',
                                    start_insert = true,
                                }

                                local context = require 'pi.context'
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
                                    'pi_send',
                                    mode = { 'n', 'i' },
                                },
                            },
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
            input_window = {
                ['<C-a>'] = {
                    function()
                        local enabled =
                            require('pi.context').toggle_context 'current_file'
                        Snacks.notify(
                            'current file context: '
                                .. (enabled and 'on' or 'off'),
                            {
                                id = 'agent-context-current-file',
                                title = 'Agent',
                                icon = '',
                            }
                        )
                    end,
                    desc = 'Toggle current file context',
                    mode = { 'n', 'i' },
                },
                ['<LocalLeader>n'] = {
                    'open_input_new_session',
                    desc = 'New session',
                },
                ['<LocalLeader>R'] = {
                    'rename_session',
                    desc = 'Rename session',
                    mode = 'n',
                },
                ['<LocalLeader>s'] = {
                    'select_session',
                    desc = 'Select session',
                    mode = 'n',
                },
                ['<cr>'] = false, -- use <S-CR> instead
                ['<esc>'] = false,
                ['<C-c>'] = { 'cancel', mode = { 'n', 'i' } },
                ['q'] = { 'toggle_pane' }, -- Toggle between input and output panes
                ['~'] = false, -- disabled since I use Snacks file picker instead
                ['@'] = { 'mention', mode = 'i' }, -- Insert mention (file/agent)
                ['/'] = { 'slash_commands', mode = 'i' },
                ['#'] = { 'context_items', mode = 'i' }, -- Manage context items (current file, selection, diagnostics, mentioned files)
                ['<tab>'] = false,
                ['<S-tab>'] = { 'switch_mode', mode = { 'n', 'i' } }, -- Switch between modes (build/plan)
                ['<M-m>'] = {
                    function()
                        require('pi.api').agent.select_agent()
                    end,
                    mode = { 'n', 'i' },
                }, -- Select agent
                ['<up>'] = { 'prev_prompt_history', mode = 'n' }, -- Navigate to previous prompt in history
                ['<down>'] = { 'next_prompt_history', mode = 'n' }, -- Navigate to next prompt in history
                ['<M-r>'] = { 'cycle_variant', mode = { 'n', 'i' } }, -- Cycle through available model variants
                ['<M-p>'] = {
                    function()
                        require('pi.api').configure_provider()
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
                ['<LocalLeader>s'] = {
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
                        require('pi.ui.ui').focus_input() -- no start_insert
                    end,
                    mode = 'n',
                },
                ['<tab>'] = false,
                ['<S-tab>'] = { 'switch_mode' }, -- Switch between modes (build/plan)
                ['<M-r>'] = { 'cycle_variant' }, -- Cycle through available model variants
                ['<M-p>'] = { 'configure_provider', desc = 'Pick model' },
                ['<M-i>'] = false,
                ['<LocalLeader>S'] = {
                    'navigate_session_tree',
                    { 'child', 'picker' },
                    desc = 'Select child session',
                },
                [']]'] = { 'next_message', desc = 'Next message' },
                ['[['] = { 'prev_message', desc = 'Prev message' },
            },
        },
        ui = {
            position = 'right',
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
                    markdown_on_idle = true,
                    markdown_on_idle_threshold = 100,
                    markdown_debounce_ms = 300,
                },
            },
            picker = {
                ---@module 'snacks'
                ---@type snacks.picker.layout.Config?
                snacks_layout = {
                    preset = 'dropdown',
                    preview = false,
                    layout = {
                        row = 0.2,
                        width = 105,
                        height = 0.4,
                    },
                },
            },
            window_highlight = 'Normal:PiBackground,FloatBorder:PiBorder,SignColumn:PiSignColumn,WinSeparator:PiWinSeparator',
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
                    search = icons.misc.search,
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
            show_ids = true,
        },
    },
    config = function(_, opts)
        require('pi').setup(opts)

        -- HACK: monkeypatch for compatibility with edgy.nvim
        local input_window = require 'pi.ui.input_window'
        input_window.schedule_resize = function() end

        local function add_quickfix_to_context()
            local context = require 'pi.context'

            if not context.is_context_enabled 'selection' then
                Snacks.notify.warn(
                    'Selection context is disabled (context.selection)',
                    { title = 'Agent', icon = '' }
                )
                return
            end

            local items = vim.fn.getqflist()
            if #items == 0 then
                Snacks.notify.warn('Quickfix list is empty', {
                    title = 'Agent',
                    icon = '',
                })
                return
            end

            -- Seed with selections already attached so re-running the
            -- keymap does not report duplicates as new additions.
            local seen = {}
            for _, sel in ipairs(context.get_context().selections or {}) do
                if sel.file and sel.file.path then
                    seen[sel.file.path .. ':' .. (sel.lines or '')] = true
                end
            end

            local added, skipped = 0, 0
            for _, item in ipairs(items) do
                local path = item.bufnr > 0
                        and vim.api.nvim_buf_get_name(item.bufnr)
                    or item.filename
                local last = (item.end_lnum or 0) > item.lnum and item.end_lnum
                    or item.lnum
                local range = item.lnum .. ', ' .. last
                local key = (path or '') .. ':' .. range

                local lines
                if item.lnum < 1 or not path or path == '' then
                    lines = nil
                elseif
                    item.bufnr > 0
                    and vim.api.nvim_buf_is_loaded(item.bufnr)
                then
                    lines = vim.api.nvim_buf_get_lines(
                        item.bufnr,
                        item.lnum - 1,
                        last,
                        false
                    )
                elseif vim.fn.filereadable(path) == 1 then
                    lines = vim.list_slice(
                        vim.fn.readfile(path, '', last),
                        item.lnum,
                        last
                    )
                end
                lines = lines
                    or vim.split(item.text or '', '\n', { plain = true })

                local content = table.concat(lines, '\n')
                if not content:match '%S' or seen[key] then
                    skipped = skipped + 1
                else
                    seen[key] = true
                    context.add_selection(context.new_selection({
                        path = path,
                        name = vim.fn.fnamemodify(path, ':t'),
                        extension = vim.fn.fnamemodify(path, ':e'),
                    }, content, range))
                    added = added + 1
                end
            end

            if added == 0 then
                Snacks.notify.warn(
                    'No new quickfix entries to add to context',
                    { title = 'Agent', icon = '' }
                )
                return
            end

            require('pi.services.session_runtime').open {
                new_session = false,
                focus = 'input',
                start_insert = true,
            }

            Snacks.notify(
                string.format(
                    'Added %d quickfix location(s) to context%s',
                    added,
                    skipped > 0 and (' (' .. skipped .. ' skipped)') or ''
                ),
                { title = 'Agent', icon = '' }
            )
        end

        require('which-key').add {
            {
                '<C-a>',
                function()
                    require('pi.api').open_input()
                end,
                desc = 'Agent input',
                mode = 'n',
                icon = '󰲔',
            },
            {
                '<C-a>',
                function()
                    require('pi.api').add_visual_selection()
                end,
                desc = 'Agent add selection',
                mode = 'v',
                icon = { icon = '󰐒', color = 'blue' },
            },
            {
                '<leader>aq',
                add_quickfix_to_context,
                desc = 'Add quickfix list to context',
                icon = { icon = icons.misc.quickfix, hl = 'DiagnosticInfo' },
            },
        }

        vim.api.nvim_create_autocmd('FileType', {
            pattern = { 'qf' },
            callback = function(args)
                require('which-key').add {
                    buffer = args.buf,
                    remap = true,
                    {
                        '<C-a>',
                        add_quickfix_to_context,
                        desc = 'Add quickfix list to context',
                        icon = {
                            icon = icons.misc.quickfix,
                            hl = 'DiagnosticInfo',
                        },
                    },
                }
            end,
        })

        vim.api.nvim_create_autocmd('User', {
            pattern = 'PiEvent:session.idle',
            callback = function(args)
                Snacks.notify('Finished', { title = 'Pi', icon = '' })
            end,
        })
    end,
}
