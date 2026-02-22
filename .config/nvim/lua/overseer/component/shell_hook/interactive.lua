---@type overseer.ComponentFileDefinition
return {
    desc = 'Add interactive flag before task is started and remove it after completion',
    constructor = function(params)
        return {
            on_pre_start = function(self, task)
                vim.o.shellcmdflag = '-ic'
            end,
            on_exit = function(self, task, code)
                vim.o.shellcmdflag = '-c'
            end,
        }
    end,
}
