---@type overseer.ComponentFileDefinition
return {
    desc = 'Customize Edgy panel size',
    params = {
        height = {
            desc = 'Panel height',
            type = 'integer',
        },
    },
    constructor = function(params)
        return {
            ---@param task overseer.Task
            ---@param status overseer.Status Can be CANCELED, FAILURE, or SUCCESS
            ---@param result table A result table.
            on_complete = function(_, task, status)
                local win = vim.api.nvim_get_current_win()
                local buf = vim.api.nvim_win_get_buf(win)
                if vim.bo[buf].filetype ~= 'OverseerOutput' then
                    return
                end
                vim.w[win]['edgy_height'] = params.height
                require('edgy.layout').update()
            end,
        }
    end,
}
