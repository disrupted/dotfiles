local trouble = require 'trouble'

local M = {}

---@param modes string[] all related modes
---@param mode string the mode to toggle
local function toggle(modes, mode)
    -- if window of selected mode is open, close it
    if trouble.is_open(mode) then
        trouble.close(mode)
        return
    end
    -- open selected mode
    local view = trouble.open(mode)
    if not view then
        return
    end
    view:wait(function()
        -- if new view has no results this will never be called
        -- close all open windows of related mode
        for _, m in ipairs(modes) do
            if m ~= mode and trouble.is_open(m) then
                trouble.close(m)
            end
        end
    end)
end

M.diagnostics = {
    modes = {
        'buffer_diagnostics',
        'workspace_diagnostics',
        'workspace_diagnostics_severe',
    },
    ---@param mode string the mode to toggle
    toggle = function(mode)
        toggle(M.diagnostics.modes, mode)
    end,
}

return M
