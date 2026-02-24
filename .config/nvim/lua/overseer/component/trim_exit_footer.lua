---@type overseer.ComponentFileDefinition
return {
    desc = 'Trim [Process exited N] footer from output',
    constructor = function()
        return {
            ---@param task overseer.Task
            ---@param status overseer.Status Can be CANCELED, FAILURE, or SUCCESS
            ---@param result table A result table.
            on_complete = function(_, task)
                local bufnr = task:get_bufnr()
                if not bufnr then
                    return
                end

                local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

                -- Remove: trailing blank + "[Process exited N]" + trailing blank
                lines[#lines] = nil
                lines[#lines] = nil
                lines[#lines] = nil

                vim.bo[bufnr].modifiable = true
                vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
                vim.bo[bufnr].modifiable = false
                vim.bo[bufnr].modified = false
            end,
        }
    end,
}
