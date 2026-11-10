local function is_uv_installed()
    return vim.fn.executable('uv') == 1
end

local function is_uv_pyproject()
    return vim.uv.fs_stat('uv.lock') ~= nil
end

---@param cmd string
---@return overseer.TaskDefinition
local function step(cmd)
    if require('rextask').available() then
        return {
            cmd = cmd,
            strategy = { 'rextask', minimized = true, key = 'uv' },
            components = {
                { 'rextask.window', show = 'failure', close = 'success', close_delay = 2 },
                'default',
            },
        }
    end
    return {
        cmd = cmd,
        components = {
            {
                'open_output',
                direction = 'dock',
                focus = true,
                on_start = 'never',
                on_complete = 'failure',
            },
            'default',
        },
    }
end

---@module 'overseer'
---@type overseer.TemplateFileDefinition
return {
    name = 'uv',
    builder = function()
        ---@type overseer.TaskDefinition
        return {
            cmd = 'uv',
            strategy = {
                'orchestrator',
                tasks = { step('uv lock'), step('uv sync') },
            },
            components = { 'default' },
        }
    end,
    condition = {
        filetype = { 'toml' },
        callback = function(search)
            local filepath = vim.api.nvim_buf_get_name(0)
            local fname = vim.fs.basename(filepath)
            return fname == 'pyproject.toml' and is_uv_installed() and is_uv_pyproject()
        end,
    },
}
