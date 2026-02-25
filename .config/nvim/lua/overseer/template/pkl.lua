---@module 'overseer'
---@type overseer.TemplateFileDefinition
return {
    name = 'pkl eval',
    tags = { 'BUILD' },
    builder = function()
        local file = vim.fn.expand '%:p:t'

        ---@type overseer.TaskDefinition
        return {
            cmd = { 'pkl', 'eval', file },
            components = {
                { 'treesitter_highlight', lang = 'pkl' },
                {
                    'open_output',
                    direction = 'vertical',
                    focus = true,
                    on_start = 'always',
                },
                { 'edgy_size', height = 35 },
                'default',
            },
            strategy = { 'jobstart_no_footer', use_terminal = false },
        }
    end,
    condition = {
        filetype = { 'pkl' },
    },
}
