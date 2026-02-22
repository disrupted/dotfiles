---@module 'overseer'
---@type overseer.TemplateFileDefinition
return {
    name = 'Terminal',
    builder = function()
        ---@type overseer.TaskDefinition
        return {
            cmd = { vim.o.shell },
            -- strategy = 'snacks',
            -- strategy = {
            --     'snacks',
            --     tasks = {
            --         {
            --             cmd = vim.env.SHELL,
            --             components = {
            --                 {
            --                     'open_output',
            --                     direction = 'dock',
            --                     focus = true,
            --                     -- on_start = 'never',
            --                     -- on_complete = 'failure',
            --                 },
            --                 'default',
            --             },
            --         },
            --     },
            -- },
            -- components = { 'default' },
            -- components = { 'interactive' },
        }
    end,
}
