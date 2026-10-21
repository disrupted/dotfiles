---@type LazeSpec[]
return {
    {
        'MeanderingProgrammer/render-markdown.nvim',
        main = 'render-markdown',
        module = 'render-markdown',
        cmd = 'RenderMarkdown',
        ft = { 'opencode_output' },
        opts = {
            debounce = 50,
            file_types = { 'opencode_output' },
            -- don't attach to LSP floating previews (hover, etc.)
            ignore = function(buf)
                local win = vim.fn.bufwinid(buf)
                return win ~= -1 and vim.w[win].lsp_floating_bufnr ~= nil
            end,
            render_modes = { 'n', 'c', 't' },
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
                language_icon = false,
                language_name = false,
                language_info = true,
                width = 'block',
                disable_background = { 'diff', 'box' },
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
            yaml = { enabled = false },
        },
    },
}
