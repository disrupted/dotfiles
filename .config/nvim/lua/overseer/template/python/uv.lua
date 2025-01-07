local function is_uv_installed()
    return vim.fn.executable 'uv' == 1
end

local function is_uv_pyproject()
    return vim.uv.fs_stat 'uv.lock' ~= nil
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
                tasks = {
                    {
                        cmd = 'uv lock',
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
                    },
                    {
                        cmd = 'uv sync',
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
                    },
                },
            },
            components = { 'default' },
        }
    end,
    condition = {
        filetype = { 'toml' },
        callback = function(search)
            local fname = vim.fn.expand '%:t'
            return fname == 'pyproject.toml'
                and is_uv_installed()
                and is_uv_pyproject()
        end,
    },
}
