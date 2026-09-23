local M = {}

local async = vim.async

--- Run a command asynchronously and return its result.
---
--- `vim.system` invokes its callback in a fast event context. Re-enter the main
--- loop after awaiting it so callers can safely make API calls afterwards.
---@async
---@param cmd string[]
---@param opts? vim.SystemOpts
---@return vim.SystemCompleted
function M.system(cmd, opts)
    local out = async.await(3, vim.system, cmd, opts)
    async.await(vim.schedule)
    return out
end

return M
