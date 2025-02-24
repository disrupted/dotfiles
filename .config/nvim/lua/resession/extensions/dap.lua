local M = {}

---@module 'resession.types'

---@alias Breakpoint table

-- Get the saved data for this extension
---@param opts resession.Extension.OnSaveOpts Information about the session being saved
---@return table<string, Breakpoint>
M.on_save = function(opts)
    local breakpoints = {}
    if package.loaded.dap then
        for buf, buf_breakpoints in pairs(require('dap.breakpoints').get()) do
            breakpoints[vim.api.nvim_buf_get_name(buf)] = buf_breakpoints
        end
    end
    return breakpoints
end

-- Restore the extension state
---@param breakpoints table<string, Breakpoint> The value returned from on_save
M.on_post_load = function(breakpoints)
    -- Build lookup table of <filename, buffer number>
    local loaded_buffers = {}
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(buf) then
            local fname = vim.api.nvim_buf_get_name(buf)
            loaded_buffers[fname] = buf
        end
    end

    -- Iterate over the breakpoints and restore them
    for fname, buf_breakpoints in pairs(breakpoints) do
        local buf = loaded_buffers[fname]
        if buf ~= nil then
            for _, bp in ipairs(buf_breakpoints) do
                require('dap.breakpoints').set({
                    condition = bp.condition,
                    log_message = bp.logMessage,
                    hit_condition = bp.hitCondition,
                }, tonumber(buf), bp.line)
            end
        end
    end
end

return M
