---@type LazeSpec
return {
    'johmsalas/text-case.nvim',
    main = 'textcase',
    module = 'textcase',
    init = function()
        require('which-key').add({
            { 'cr', mode = { 'n', 'v' }, group = 'Coerce', icon = '󰬴' },
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

        local function coerce_current(operation)
            local clients_supporting_rename = vim.lsp.get_clients({
                bufnr = 0,
                method = 'textDocument/rename',
            })
            if
                vim.tbl_isempty(clients_supporting_rename)
                or is_inside_ignored_node()
            then
                ---@diagnostic disable-next-line: need-check-nil
                require('textcase').current_word(operation)
            else
                ---@diagnostic disable-next-line: need-check-nil
                require('textcase').lsp_rename(operation)
            end
        end

        local coercions = {
            c = { 'to_camel_case', 'camelCase' },
            p = { 'to_pascal_case', 'PascalCase' },
            m = { 'to_pascal_case', 'PascalCase' },
            _ = { 'to_snake_case', 'snake_case' },
            s = { 'to_snake_case', 'snake_case' },
            u = { 'to_constant_case', 'CONSTANT_CASE' },
            U = { 'to_constant_case', 'CONSTANT_CASE' },
            k = { 'to_dash_case', 'dash-case' },
            ['-'] = { 'to_dash_case', 'dash-case' },
            ['.'] = { 'to_dot_case', 'dot.case' },
            [' '] = { 'to_lower_phrase_case', 'lower phrase case' },
        }

        for char, coercion in pairs(coercions) do
            local operation, desc = coercion[1], coercion[2]
            vim.keymap.set('n', 'cr' .. char, function()
                coerce_current(operation)
            end, { desc = 'Coerce to ' .. desc })
            vim.keymap.set('v', 'cr' .. char, function()
                ---@diagnostic disable-next-line: need-check-nil
                require('textcase').visual(operation)
            end, { desc = 'Coerce to ' .. desc })
        end
    end,
    config = function()
        require('textcase').setup({
            default_keymappings_enabled = false,
            substitude_command_name = 'Subs',
        })

        -- :Subs is redundant and inferior to :S / :Subvert (conf.subvert)
        local function drop_subs()
            pcall(vim.api.nvim_del_user_command, 'Subs')
        end
        drop_subs()
        if vim.v.vim_did_enter == 0 then
            vim.api.nvim_create_autocmd('VimEnter', {
                once = true,
                callback = drop_subs,
            })
        end
    end,
}
