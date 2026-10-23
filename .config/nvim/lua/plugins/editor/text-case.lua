---@type LazeSpec
return {
    'johmsalas/text-case.nvim',
    main = 'textcase',
    module = 'textcase',
    cmd = 'Subs',
    init = function()
        require('which-key').add({
            { 'zc', mode = { 'n', 'v' }, group = 'Coerce', icon = '󰬴' },
            { 'zx', group = 'Coerce (operator)', icon = '󰬴' },
        })

        local ignored_nodes = { 'string', 'comment' }
        local function is_inside_ignored_node()
            local node = vim.treesitter.get_node()
            while node do
                if vim.tbl_contains(ignored_nodes, node:type()) then
                    return true
                end
                node = node:parent()
            end
            return false
        end

        local function textcase_map(char, operation, desc)
            vim.keymap.set('n', 'zc' .. char, function()
                local clients_supporting_rename = vim.lsp.get_clients({
                    bufnr = 0,
                    method = 'textDocument/rename',
                })
                if
                    vim.tbl_isempty(clients_supporting_rename)
                    or is_inside_ignored_node()
                then
                    require('textcase').current_word(operation)
                else
                    require('textcase').lsp_rename(operation)
                end
            end, { desc = 'to ' .. desc })
            vim.keymap.set('n', 'zx' .. char, function()
                require('textcase').operator(operation)
            end, { desc = 'to ' .. desc })
            vim.keymap.set('v', 'zc' .. char, function()
                require('textcase').visual(operation)
            end, { desc = 'to ' .. desc })
        end

        textcase_map('s', 'to_snake_case', 'snake_case')
        textcase_map('d', 'to_dash_case', 'dash-case')
        textcase_map('c', 'to_camel_case', 'camelCase')
        textcase_map('p', 'to_pascal_case', 'PascalCase')
        textcase_map('v', 'to_constant_case', 'CONSTANT_CASE') -- environment variable
        textcase_map('t', 'to_title_case', 'Title Case')
        textcase_map('r', 'to_phrase_case', 'Regular phrase case')
        textcase_map('.', 'to_dot_case', 'dot.case')
    end,
    opts = {
        default_keymappings_enabled = false,
        -- substitude_command_name = 'S', -- do not overwrite vim-abolish until feature parity
    },
}
