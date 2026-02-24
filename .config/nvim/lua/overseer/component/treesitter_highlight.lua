---@type overseer.ComponentFileDefinition
return {
    desc = 'Highlight task output using TreeSitter',
    params = {
        lang = {
            desc = 'TreeSitter language',
            type = 'string',
        },
    },
    constructor = function(params)
        return {
            ---@param task overseer.Task
            ---@param status overseer.Status Can be CANCELED, FAILURE, or SUCCESS
            ---@param result table A result table.
            on_complete = function(_, task, status)
                if status ~= 'SUCCESS' then
                    return
                end
                local bufnr = task:get_bufnr()
                if not bufnr then
                    return
                end

                vim.treesitter.start(bufnr, params.lang)
            end,
        }
    end,
}
