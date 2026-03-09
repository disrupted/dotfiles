---@module 'overseer'
---@type overseer.TemplateFileDefinition
return {
    name = 'typst compile',
    tags = { 'BUILD' },
    builder = function()
        local file = vim.fn.expand '%:p:t'

        ---@type overseer.TaskDefinition
        return {
            cmd = { 'typst', 'compile', file },
            components = {
                'default',
            },
        }
    end,
    condition = {
        filetype = { 'typst' },
    },
}
