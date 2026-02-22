---@module 'overseer'
---@type overseer.TemplateFileDefinition
return {
    name = 'pkl eval',
    builder = function()
        local file = vim.fn.expand '%:p:t'

        ---@type overseer.TaskDefinition
        return {
            cmd = { 'pkl', 'eval', file },
            components = {
                'on_complete_dispose',
                'open_output',
                'default',
            },
        }
    end,
    condition = {
        filetype = { 'pkl' },
    },
}
