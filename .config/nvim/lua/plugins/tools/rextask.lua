---@type LazeSpec
return {
    'disrupted/rextask',
    module = 'rextask',
    keys = {
        {
            '<Bslash>',
            function()
                require('rextask').toggle()
            end,
            desc = 'Rextask: toggle latest task window',
        },
        {
            '|',
            function()
                require('rextask').select()
            end,
            desc = 'Rextask: select task window',
        },
        {
            '<M-Bslash>',
            function()
                if require('rextask').available() then
                    require('rextask').pick()
                else
                    vim.cmd.OverseerRun()
                end
            end,
            desc = 'Rextask: run mise task',
        },
    },
    config = function()
        require('rextask').setup()
    end,
}
