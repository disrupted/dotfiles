local function is_poetry_installed()
    return vim.fn.executable 'poetry' == 1
end

local function is_poetry_pyproject()
    return vim.uv.fs_stat 'poetry.lock' ~= nil
end

---@module 'overseer'
---@type overseer.TemplateFileDefinition
return {
    name = 'Poetry',
    builder = function()
        ---@type overseer.TaskDefinition
        return {
            cmd = 'Poetry',
            strategy = {
                'orchestrator',
                tasks = {
                    {
                        cmd = 'poetry lock',
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
                        cmd = 'poetry sync',
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
            local filepath = vim.api.nvim_buf_get_name(0)
            local fname = vim.fs.basename(filepath)
            return fname == 'pyproject.toml'
                and is_poetry_installed()
                and is_poetry_pyproject()
        end,
    },
}
