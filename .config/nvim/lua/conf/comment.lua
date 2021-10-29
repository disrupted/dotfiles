local M = {}

function M.config()
    require('Comment').setup {
        ignore = '^$', -- ignore empty lines
        pre_hook = function(_)
            if vim.bo.filetype == 'typescriptreact' then
                return require('ts_context_commentstring.internal').calculate_commentstring()
            end
        end,
    }
end

return M
