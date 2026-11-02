local STATUS = require('overseer.constants').STATUS

local statuses = {
    [STATUS.SUCCESS] = 'success',
    [STATUS.FAILURE] = 'failed',
    [STATUS.CANCELED] = 'cancel',
}

local function echo(self, task, status)
    self.id = vim.api.nvim_echo({ { task.name } }, false, {
        id = self.id,
        kind = 'progress',
        status = status,
        source = 'overseer',
        title = 'overseer',
        data = { program_status = true },
    })
end

---@type overseer.ComponentFileDefinition
return {
    desc = 'Report task lifecycle as a native progress-message',
    constructor = function()
        return {
            on_start = function(self, task)
                self.id = nil
                echo(self, task, 'running')
            end,
            on_complete = function(self, task, status)
                if self.id then
                    echo(self, task, statuses[status] or 'cancel')
                end
            end,
            on_dispose = function(self, task)
                if self.id and task:is_running() then
                    echo(self, task, 'cancel')
                end
            end,
        }
    end,
}
