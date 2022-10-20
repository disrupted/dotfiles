local M = {}

function M.setup()
    local function textcase_map(char, operation)
        vim.keymap.set('n', 'za' .. char, function()
            require('textcase').current_word(operation)
        end)
        local upper = char:upper()
        if upper ~= char then
            vim.keymap.set('n', 'za' .. upper, function()
                require('textcase').lsp_rename(operation)
            end)
        end
        vim.keymap.set('n', 'z' .. char, function()
            require('textcase').operator(operation)
        end)
    end

    textcase_map('s', 'to_snake_case')
    textcase_map('d', 'to_dash_case')
    textcase_map('c', 'to_camel_case')
    textcase_map('p', 'to_pascal_case')

    -- experimental
    textcase_map('t', 'to_title_case')
    textcase_map('.', 'to_dot_case')
end

return M
