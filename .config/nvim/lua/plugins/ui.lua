return {
    {
        'rcarriga/nvim-notify',
        lazy = true,
        opts = {
            stages = 'static',
            render = 'minimal',
            minimum_width = 10,
        },
        config = function(_, opts)
            local notify = require 'notify'
            notify.setup(opts)
            vim.notify = notify

            vim.api.nvim_set_hl(0, 'NotifyINFOBorder', { fg = '#80ff95' })
            vim.api.nvim_set_hl(
                0,
                'NotifyINFOBody',
                { link = 'NotifyINFOBorder' }
            )
            vim.api.nvim_set_hl(0, 'NotifyWARNBorder', { fg = '#fff454' })
            vim.api.nvim_set_hl(
                0,
                'NotifyWARNBody',
                { link = 'NotifyWARNBorder' }
            )
            vim.api.nvim_set_hl(0, 'NotifyERRORBorder', { fg = '#c44323' })
            vim.api.nvim_set_hl(
                0,
                'NotifyERRORBody',
                { link = 'NotifyERRORBorder' }
            )
        end,
    },
    {
        'feline-nvim/feline.nvim',
        event = 'VeryLazy',
        opts = function()
            local lazy_require = require('feline.utils').lazy_require
            local vi_mode = lazy_require 'feline.providers.vi_mode'

            local colors = {
                bg = '#282c34',
                fg = '#abb2bf',
                section_bg = '#38393f',
                blue = '#61afef',
                green = '#98c379',
                purple = '#c678dd',
                orange = '#e5c07b',
                red = '#e06c75',
                yellow = '#e5c07b',
                darkgrey = '#2c323d',
                middlegrey = '#8791A5',
            }
            local vi_mode_colors = {
                NORMAL = 'green',
                OP = 'red',
                INSERT = 'blue',
                VISUAL = 'purple',
                LINES = 'purple',
                BLOCK = 'purple',
                REPLACE = 'red',
                ['V-REPLACE'] = 'purple',
                ENTER = 'blue',
                MORE = 'blue',
                SELECT = 'orange',
                COMMAND = 'green',
                SHELL = 'green',
                TERM = 'blue',
                NONE = 'yellow',
            }
            local mode_alias = {
                ['n'] = 'NORMAL',
                ['no'] = 'OP',
                ['nov'] = 'OP',
                ['noV'] = 'OP',
                ['no'] = 'OP',
                ['niI'] = 'NORMAL',
                ['niR'] = 'NORMAL',
                ['niV'] = 'NORMAL',
                ['v'] = 'VISUAL',
                ['V'] = 'V-LINE',
                [''] = 'V-BLOCK',
                ['s'] = 'SELECT',
                ['S'] = 'SELECT',
                [''] = 'V-BLOCK',
                ['i'] = 'INSERT',
                ['ic'] = 'INSERT',
                ['ix'] = 'INSERT',
                ['R'] = 'REPLACE',
                ['Rc'] = 'REPLACE',
                ['Rv'] = 'V-REPLACE',
                ['Rx'] = 'REPLACE',
                ['c'] = 'COMMAND',
                ['cv'] = 'COMMAND',
                ['ce'] = 'COMMAND',
                ['r'] = 'ENTER',
                ['rm'] = 'MORE',
                ['r?'] = 'CONFIRM',
                ['!'] = 'SHELL',
                ['t'] = 'TERMINAL',
                ['nt'] = 'NORMAL',
                ['null'] = 'NONE',
            }

            local components = {
                active = { {}, {} }, -- statusline sections left & right
                inactive = { {} },
            }

            local function is_file(bufnr)
                local bt = vim.api.nvim_buf_get_option(bufnr, 'buftype')
                return bt ~= 'nofile' and bt ~= 'terminal'
            end

            local function file_readonly(bufnr)
                if vim.api.nvim_buf_get_option(bufnr, 'filetype') == 'help' then
                    return false
                end
                if vim.api.nvim_buf_get_option(bufnr, 'readonly') then
                    return true
                end
                return false
            end

            local function file_modified(bufnr)
                if
                    vim.api.nvim_buf_get_option(bufnr, 'modifiable')
                    and vim.api.nvim_buf_get_option(bufnr, 'modified')
                then
                    return true
                end
                return false
            end

            local function file_name()
                local bufnr = vim.api.nvim_win_get_buf(0)
                local filename = vim.api.nvim_buf_get_name(bufnr)
                filename = vim.fn.fnamemodify(filename, ':t')

                if is_file(bufnr) and file_readonly(bufnr) then
                    return filename .. ' '
                end
                if file_modified(bufnr) then
                    return filename .. ' '
                end
                return filename
            end

            local function harpoon()
                return lazy_require('harpoon.mark').status()
            end

            local function mode()
                return mode_alias[vim.api.nvim_get_mode().mode]
            end

            table.insert(components.active[1], {
                provider = function()
                    return string.format(' %s ', mode())
                end,
                short_provider = function()
                    return string.format(' %s ', mode():sub(1, 1))
                end,
                icon = '',
                hl = function()
                    return {
                        fg = 'bg',
                        bg = vi_mode.get_mode_color(),
                        style = 'bold',
                    }
                end,
            })

            table.insert(components.active[1], {
                provider = harpoon,
                hl = function()
                    return {
                        fg = 'bg',
                        bg = 'blue',
                        style = 'bold',
                    }
                end,
                left_sep = {
                    str = ' ',
                    hl = {
                        bg = 'blue',
                    },
                },
                right_sep = {
                    str = ' ',
                    hl = {
                        bg = 'blue',
                    },
                },
            })

            local function split(str, sep)
                local res = {}
                local n = 1
                for w in str:gmatch('([^' .. sep .. ']*)') do
                    res[n] = res[n] or w -- only set once (so the blank after a string is ignored)
                    if w == '' then
                        n = n + 1
                    end -- step forwards on a blank but not a string
                end
                return res
            end

            local function file_icon()
                local icon = {
                    str = ' ',
                    always_visible = true,
                }

                local filename =
                    vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(0))
                filename = vim.fn.fnamemodify(filename, ':t')
                local extension = vim.fn.fnamemodify(filename, ':e')

                if filename == '' then
                    return icon
                end

                local icon_str, icon_hlname =
                    require('nvim-web-devicons').get_icon(
                        filename,
                        extension,
                        { default = false }
                    )

                icon.str = string.format(' %s ', icon_str or '')

                -- icon color
                -- if icon_hlname then
                --     local fg = api.nvim_get_hl_by_name(icon_hlname, true).foreground
                --     if fg then
                --         icon.hl = { fg = string.format('#%06x', fg) }
                --     end
                -- end

                return icon
            end

            table.insert(components.active[1], {
                provider = '',
                icon = file_icon,
                hl = {
                    bg = 'section_bg',
                },
            })

            local function file_path()
                local bufnr = vim.api.nvim_win_get_buf(0)
                if not is_file(bufnr) then
                    return ''
                end
                local filename = vim.api.nvim_buf_get_name(bufnr)
                local fp = vim.fn.fnamemodify(filename, ':~:.')
                if vim.fn.fnamemodify(filename, ':t') ~= '' then
                    -- not unnamed file
                    fp = vim.fn.fnamemodify(fp, ':h')
                end
                local tbl = split(fp, '/')
                local len = #tbl

                if len > 2 and not tbl[0] == '~' or len > 3 then
                    return '…/' .. table.concat(tbl, '/', len - 1) .. '/' -- shorten filepath to last 2 folders
                -- alternative: only 1 containing folder using vim builtin function
                -- return '…/' .. fn.fnamemodify(fn.expand '%', ':p:h:t') .. '/'
                else
                    return fp .. '/'
                end
            end

            table.insert(components.active[1], {
                provider = file_path,
                enabled = function()
                    return vim.api.nvim_win_get_width(0) >= 80
                end,
                hl = {
                    fg = 'middlegrey',
                    bg = 'section_bg',
                },
            })

            local function file_info()
                local bufnr = vim.api.nvim_win_get_buf(0)
                local filename = vim.api.nvim_buf_get_name(bufnr)
                filename = vim.fn.fnamemodify(filename, ':t')

                -- if filename == '' then
                --     filename = '[unnamed]'
                -- end

                local readonly_str = ''
                local modified_str = ''
                if vim.api.nvim_buf_get_option(bufnr, 'readonly') then
                    readonly_str = ' '
                end

                if vim.api.nvim_buf_get_option(bufnr, 'modified') then
                    modified_str = ' '
                end

                return readonly_str .. filename .. ' ' .. modified_str
            end

            -- File info
            table.insert(components.active[1], {
                provider = file_info,
                hl = {
                    fg = 'fg',
                    bg = 'section_bg',
                },
                left_sep = '',
                right_sep = {
                    str = 'slant_right',
                    hl = {
                        fg = 'section_bg',
                        bg = 'bg',
                    },
                },
            })

            local function lsp_check_diagnostics()
                if
                    vim.tbl_isempty(vim.lsp.get_active_clients { bufnr = 0 })
                then
                    return ''
                end
                local diagnostics = vim.diagnostic.get(
                    0,
                    { severity = { min = vim.diagnostic.severity.INFO } }
                )
                if not vim.tbl_isempty(diagnostics) then
                    return ''
                end
                return ' '
            end

            table.insert(components.active[1], {
                provider = lsp_check_diagnostics,
                hl = {
                    fg = 'middlegrey',
                    bg = 'bg',
                },
            })

            local function get_diagnostic_count(severity)
                local count = #vim.diagnostic.get(0, { severity = severity })
                return count ~= 0 and count .. ' ' or ''
            end

            table.insert(components.active[1], {
                provider = function()
                    return get_diagnostic_count(vim.diagnostic.severity.ERROR)
                end,
                icon = '  ',
                hl = {
                    fg = 'red',
                    bg = 'bg',
                },
            })
            table.insert(components.active[1], {
                provider = function()
                    return get_diagnostic_count(vim.diagnostic.severity.WARN)
                end,
                icon = '  ',
                hl = {
                    fg = 'orange',
                    bg = 'bg',
                },
            })
            table.insert(components.active[1], {
                provider = function()
                    return get_diagnostic_count(vim.diagnostic.severity.INFO)
                end,
                icon = '  ',
                hl = {
                    fg = 'blue',
                    bg = 'bg',
                },
            })

            -- RIGHT
            table.insert(components.active[2], {
                provider = 'git_diff_added',
                icon = '+',
                hl = {
                    fg = 'green',
                    bg = 'bg',
                },
                right_sep = ' ',
            })
            table.insert(components.active[2], {
                provider = 'git_diff_changed',
                icon = '~',
                hl = {
                    fg = 'orange',
                    bg = 'bg',
                },
                right_sep = ' ',
            })
            table.insert(components.active[2], {
                provider = 'git_diff_removed',
                icon = '-',
                hl = {
                    fg = 'red',
                    bg = 'bg',
                },
                right_sep = ' ',
            })
            table.insert(components.active[2], {
                provider = 'git_branch',
                -- icon = ' ',
                hl = {
                    fg = 'middlegrey',
                    bg = 'bg',
                },
                left_sep = ' ',
            })

            table.insert(components.inactive[1], {
                provider = harpoon,
                hl = function()
                    return {
                        fg = 'fg',
                        bg = 'section_bg',
                        style = 'bold',
                    }
                end,
                left_sep = {
                    str = ' ',
                    hl = {
                        bg = 'section_bg',
                    },
                },
                right_sep = {
                    str = ' ',
                    hl = {
                        bg = 'section_bg',
                    },
                },
            })
            table.insert(components.inactive[1], {
                provider = file_name,
                hl = {
                    fg = 'fg',
                    bg = 'section_bg',
                },
                right_sep = {
                    str = 'slant_right',
                    hl = {
                        fg = 'section_bg',
                        bg = 'bg',
                    },
                },
            })

            return {
                theme = colors,
                vi_mode_colors = vi_mode_colors,
                components = components,
                force_inactive = {
                    filetypes = {
                        '^qf$',
                        '^help$',
                        'Outline',
                        'Trouble',
                        'dap-repl',
                        '^dapui',
                    },
                    buftypes = {},
                    bufnames = {},
                },
                disable = {
                    filetypes = {
                        'NvimTree',
                    },
                    buftypes = {},
                    bufnames = {},
                },
            }
        end,
    },
    { 'kyazdani42/nvim-web-devicons', lazy = true },
    {
        'lukas-reineke/indent-blankline.nvim',
        event = 'BufWinEnter',
        opts = {
            char = '▏',
            context_char = '▏',
            show_first_indent_level = false,
            filetype_exclude = {
                'help',
                'markdown',
                'gitcommit',
                'packer',
            },
            buftype_exclude = { 'terminal', 'nofile' },
            use_treesitter = true,
            -- show_current_context = true,
            -- context_patterns = {
            --     'class',
            --     'function',
            --     'method',
            --     '^if',
            --     '^while',
            --     '^for',
            --     '^object',
            --     '^table',
            --     'block',
            --     'arguments',
            -- },
        },
    },
    {
        'kwkarlwang/bufresize.nvim',
        lazy = true,
        init = function()
            vim.api.nvim_create_autocmd('VimResized', {
                callback = function()
                    require('bufresize').resize()
                end,
            })
        end,
        enabled = false,
    },
    { 'MunifTanjim/nui.nvim', lazy = true },
    {
        'folke/noice.nvim',
        event = 'VeryLazy',
        opts = {
            cmdline = {
                format = {
                    cmdline = { pattern = '^:', icon = ':' },
                },
            },
            lsp = { signature = { enabled = true } },
            routes = {
                {
                    filter = {
                        event = 'cmdline',
                        find = '^%s*[/?]',
                    },
                    view = 'cmdline',
                },
            },
            presets = {
                long_message_to_split = false, -- long messages will be sent to a split
                lsp_doc_border = true, -- add a border to hover docs and signature help
            },
        },
        config = function(_, opts)
            require('noice').setup(opts)
            vim.api.nvim_set_hl(0, 'NoiceVirtualText', { link = 'NormalFloat' })
            vim.api.nvim_set_hl(
                0,
                'NoiceCmdlinePopupBorder',
                { link = 'TelescopePromptBorder' }
            )
            vim.keymap.set('n', '<M-Enter>', function() -- Alt-Enter
                require('noice').redirect 'Inspect'
            end, { desc = 'Show inspect in popup' })
        end,
    },
}
