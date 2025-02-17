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
    -- close all open windows of related mode
    vim.iter(modes):each(function(m)
        if m ~= mode and trouble.is_open(m) then
            trouble.close(m)
        end
    end)
    -- open selected mode
    trouble.open(mode)
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
