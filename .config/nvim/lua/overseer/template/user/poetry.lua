local function is_poetry_installed()
    return vim.fn.executable 'poetry' == 1
end

local function is_poetry_pyproject()
    -- Get the current buffer's tree
    local buf = vim.api.nvim_get_current_buf()
    local parser = assert(vim.treesitter.get_parser(buf))
    local tree = parser:parse()[1]

    -- Define the query to match TOML tables
    local query = [[
        (document 
            (table 
                (dotted_key) @table
            )
        ) 
    ]]

    local ts_query = vim.treesitter.query.parse(parser:lang(), query)

    for _, matches in ts_query:iter_matches(tree:root(), buf) do
        for _, match in pairs(matches) do
            local node = match[1]
            local contents = vim.treesitter.get_node_text(node, buf)
            if contents == 'tool.poetry' then
                return true
            end
        end
    end

    return false
end

---@type overseer.TemplateFileDefinition
return {
    name = 'Poetry lock',
    builder = function()
        ---@type overseer.TaskDefinition
        return {
            cmd = 'Poetry lock',
            strategy = {
                'orchestrator',
                tasks = {
                    {
                        cmd = 'poetry lock --no-update',
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
                        cmd = 'poetry install --sync',
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
                and is_poetry_installed()
                and is_poetry_pyproject()
        end,
    },
}
