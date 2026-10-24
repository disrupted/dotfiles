local icons = require('conf.icons')

---@type LazeSpec
return {
    'Bekaboo/dropbar.nvim',
    main = 'dropbar',
    module = 'dropbar',
    event = 'FileType',
    config = function()
        ---@module 'dropbar.configs'
        ---@type dropbar_configs_t
        local opts = {
            bar = {
                ---@type boolean|fun(buf: integer, win: integer, info: table?): boolean
                enable = function(buf, win, _)
                    if
                        not vim.api.nvim_buf_is_valid(buf)
                        or not vim.api.nvim_win_is_valid(win)
                        or vim.fn.win_gettype(win) ~= ''
                        or vim.bo[buf].filetype == ''
                        or vim.bo[buf].buftype ~= ''
                        or vim.wo[win].winbar ~= ''
                        or vim.tbl_contains(
                            { 'gitcommit', 'gitrebase' },
                            vim.bo[buf].ft
                        )
                    then
                        return false
                    end

                    local stat = vim.uv.fs_stat(vim.api.nvim_buf_get_name(buf))
                    if stat and stat.size > 1024 * 1024 then
                        return false
                    end

                    return vim.bo[buf].ft == 'markdown'
                        or pcall(vim.treesitter.get_parser, buf)
                        or not vim.tbl_isempty(vim.lsp.get_clients({
                            bufnr = buf,
                            method = 'textDocument/documentSymbol',
                        }))
                end,
                ---@type dropbar_source_t[]|fun(buf: integer, win: integer): dropbar_source_t[]
                sources = function(buf, _)
                    local sources = require('dropbar.sources')
                    if vim.bo[buf].ft == 'markdown' then
                        return {
                            sources.path,
                            sources.markdown,
                        }
                    end
                    if vim.bo[buf].buftype == 'terminal' then
                        return {
                            sources.terminal,
                        }
                    end

                    local clients = vim.lsp.get_clients({
                        bufnr = buf,
                        method = 'textDocument/documentSymbol',
                    })
                    if not vim.tbl_isempty(clients) then
                        return {
                            sources.path,
                            sources.lsp,
                        }
                    else
                        return {
                            sources.path,
                            sources.treesitter,
                        }
                    end
                end,
                update_events = {
                    buf = {
                        -- 'BufModifiedSet', -- TODO: replace with OptionSet 'modified'
                        'FileChangedShellPost',
                        'TextChanged',
                        'ModeChanged',
                        'BufWritePost', -- HACK: OptionSet 'modified' is only fired for current buffer, e.g. when running `:wa` other buffers do not get refreshed https://github.com/neovim/neovim/issues/32817
                    },
                    -- global = {
                    --     'DirChanged',
                    --     'VimResized',
                    -- },
                },
            },
            sources = {
                path = {
                    ---@type dropbar_source_t[]|fun(sym: dropbar_symbol_t): dropbar_symbol_t
                    modified = function(sym)
                        return sym:merge({
                            name = string.format(
                                '%s %s ',
                                sym.name,
                                icons.documents.file_modified
                            ),
                        })
                    end,
                },
                treesitter = {
                    valid_types = {
                        -- 'array',
                        -- 'boolean',
                        -- 'break_statement',
                        -- 'call',
                        -- 'case_statement',
                        'class',
                        -- 'constant',
                        'constructor',
                        -- 'continue_statement',
                        -- 'delete',
                        -- 'do_statement',
                        -- 'element',
                        -- 'enum',
                        -- 'enum_member',
                        'event',
                        -- 'for_statement',
                        'function',
                        'h1_marker',
                        'h2_marker',
                        'h3_marker',
                        'h4_marker',
                        'h5_marker',
                        'h6_marker',
                        -- 'if_statement',
                        'interface',
                        -- 'keyword',
                        -- 'macro',
                        'method',
                        'namespace',
                        -- 'null',
                        -- 'number',
                        -- 'operator',
                        'package',
                        -- 'pair',
                        'property',
                        -- 'reference',
                        -- 'repeat',
                        -- 'rule_set',
                        -- 'scope',
                        -- 'specifier',
                        'struct',
                        -- 'switch_statement',
                        'table',
                        -- 'type',
                        -- 'type_parameter',
                        -- 'unit',
                        -- 'value',
                        -- -- 'variable',
                        -- 'while_statement',
                        'declaration',
                        -- 'field',
                        -- 'identifier',
                        'object',
                        -- 'statement',
                    },
                },
                lsp = {
                    valid_symbols = {
                        'File',
                        -- 'Module',
                        -- 'Namespace',
                        -- 'Package',
                        'Class',
                        'Method',
                        'Constructor',
                        'Interface',
                        'Function',
                    },
                },
            },
            icons = {
                kinds = {
                    symbols = {
                        Array = '󰅪 ',
                        Boolean = '◩ ',
                        BreakStatement = '󰙧 ',
                        Call = '󰃷 ',
                        CaseStatement = '󱃙 ',
                        Class = '󰙅 ',
                        Color = '󰏘 ',
                        Constant = '󰏿 ',
                        Constructor = ' ',
                        ContinueStatement = '→ ',
                        Copilot = ' ',
                        Declaration = '󰙠 ',
                        Delete = '󰩺 ',
                        DoStatement = '󰑖 ',
                        Enum = ' ',
                        EnumMember = ' ',
                        Event = ' ',
                        Field = ' ',
                        File = '󰈙 ',
                        Folder = '󰉋 ',
                        ForStatement = '󰑖 ',
                        Function = '󰊕 ',
                        H1Marker = '󰉫 ', -- Used by markdown treesitter parser
                        H2Marker = '󰉬 ',
                        H3Marker = '󰉭 ',
                        H4Marker = '󰉮 ',
                        H5Marker = '󰉯 ',
                        H6Marker = '󰉰 ',
                        Identifier = '󰀫 ',
                        IfStatement = '󰇉 ',
                        Interface = '󰕘 ',
                        Keyword = '󰌋 ',
                        List = '󰅪 ',
                        Log = '󰦪 ',
                        Lsp = ' ',
                        Macro = '󰁌 ',
                        MarkdownH1 = '󰉫 ', -- Used by builtin markdown source
                        MarkdownH2 = '󰉬 ',
                        MarkdownH3 = '󰉭 ',
                        MarkdownH4 = '󰉮 ',
                        MarkdownH5 = '󰉯 ',
                        MarkdownH6 = '󰉰 ',
                        Method = ' ',
                        Module = ' ',
                        Namespace = '󰌗 ',
                        Null = '󰢤 ',
                        Number = '󰎠 ',
                        Object = ' ',
                        Operator = '󰆕 ',
                        Package = '󰆦 ',
                        Pair = ' ',
                        Property = ' ',
                        Reference = '󰋺 ',
                        Regex = ' ',
                        Repeat = '󰑖 ',
                        Scope = ' ', -- FIXME: 󰅩 symbol rendered incorrectly in Ghostty
                        Snippet = '󱡄 ',
                        Specifier = '󰦪 ',
                        Statement = ' ',
                        String = '󰉾 ',
                        Struct = '󱡠 ',
                        SwitchStatement = '󰺟 ',
                        Table = '󰠵 ',
                        Terminal = ' ',
                        Text = ' ',
                        Type = ' ',
                        TypeParameter = '󰊄 ',
                        Unit = ' ',
                        Value = ' ',
                        Variable = '󰀫 ',
                        WhileStatement = '󰑖 ',
                    },
                },
            },
        }
        ---@diagnostic disable-next-line: param-type-mismatch
        require('dropbar').setup(opts)
        require('which-key').add({
            {
                '<Leader>;',
                function()
                    require('dropbar.api').pick()
                end,
                desc = 'Winbar pick symbol',
                icon = '󱐀',
            },
        })

        vim.api.nvim_create_autocmd('LspAttach', {
            desc = 'Register LSP source and disable Treesitter source when an LS that supports documentSymbol attaches.',
            group = vim.api.nvim_create_augroup(
                'DropBarLspAttachRefreshSources',
                { clear = true }
            ),
            callback = function(args)
                local bufnr = args.buf
                local client = vim.lsp.get_client_by_id(args.data.client_id)
                if client and client:supports_method('textDocument/documentSymbol') then
                    local sources = require('dropbar.sources')
                    local utils = require('dropbar.utils')
                    for win in pairs(_G.dropbar.bars[bufnr]) do
                        _G.dropbar.bars[bufnr][win].sources = {
                            sources.path,
                            sources.lsp,
                        }
                        utils.bar.exec('update', { win = win })
                    end
                end
            end,
        })
    end,
}
