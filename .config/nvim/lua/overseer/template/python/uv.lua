local function is_uv_installed()
    return vim.fn.executable 'uv' == 1
end

local function is_uv_pyproject()
    if vim.uv.fs_stat 'uv.lock' then
        return true
    end
    local buf = vim.api.nvim_get_current_buf()
    local parser = assert(vim.treesitter.get_parser(buf))
    local tree = parser:parse()[1]

    -- Define the query to match TOML tables
    local query = [[
        (document 
            (table 
                (bare_key) @table
            )
        ) 
    ]]

    local ts_query = vim.treesitter.query.parse(parser:lang(), query)

    for _, matches in ts_query:iter_matches(tree:root(), buf) do
        for _, match in pairs(matches) do
            local node = match[1]
            local contents = vim.treesitter.get_node_text(node, buf)
            if contents == 'project' then
                return true
            end
        end
    end

    return false
end

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
