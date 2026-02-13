---@module 'lazy.types'
---@type LazySpec[]
return {
    {
        'MeanderingProgrammer/render-markdown.nvim',
        cmd = 'RenderMarkdown',
        ft = { 'markdown', 'opencode_output' },
        opts = {
            debounce = 50,
            file_types = { 'markdown', 'opencode_output' },
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
}
