local M = {}

function M.config()
    require('Comment').setup {
        ignore = '^$', -- ignore empty lines
        pre_hook = require(
            'ts_context_commentstring.integrations.comment_nvim'
        ).create_pre_hook(),
    }
end

return M
