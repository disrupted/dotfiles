local M = {}

function M.setup()
    require('nvim_comment').setup {
        -- Linters prefer comment and line to hae a space in between
        left_marker_padding = true,
        -- should comment out empty or whitespace only lines
        comment_empty = false,
        -- Should key mappings be created
        create_mappings = true,
        -- Normal mode mapping left hand side
        line_mapping = 'gcc',
        -- Visual/Operator mapping left hand side
        operator_mapping = 'gc',
    }
end

return M
