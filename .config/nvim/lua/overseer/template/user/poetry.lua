local function is_poetry_pyproject()
    -- Get the current buffer's tree
    local buf = vim.api.nvim_get_current_buf()
    local parser = vim.treesitter.get_parser(buf, 'toml')
    local tree = parser:parse()[1]
    local root = tree:root()

    -- Define the query to match TOML tables
    local query = [[
        (document 
            (table 
                (dotted_key) @table
            )
        ) 
    ]]

    local ts_query = vim.treesitter.query.parse('toml', query)

    for _, match in ts_query:iter_matches(root, buf) do
        local first_node = match[1] -- The first capture group (dotted_key)
        local contents = vim.treesitter.get_node_text(first_node, buf)
        if contents == 'tool.poetry' then
            return true
        end
    end

    return false
end

return {
    name = 'Poetry lock',
    builder = function()
        return {
            cmd = 'poetry lock --no-update && poetry install --sync',
            components = {
                { 'open_output', on_complete = 'failure' },
                -- { 'open_output', on_start = 'always' },
                'default',
            },
        }
    end,
    condition = {
        filetype = { 'toml' },
        callback = function(search)
            local fname = vim.fn.expand '%:t'
            return fname == 'pyproject.toml' and is_poetry_pyproject()
        end,
    },
}
