local au = vim.api.nvim_create_augroup('LspAttach', { clear = true })

-- client log
vim.uv.fs_unlink(vim.lsp.log.get_filename())
vim.lsp.log.set_level(vim.log.levels.WARN)

vim.api.nvim_create_user_command('LspFormat', function()
    vim.lsp.buf.format { async = false }
end, {})

vim.api.nvim_create_autocmd('LspAttach', {
    group = au,
    desc = 'LSP tagfunc',
    callback = function(args)
        local bufnr = args.buf
        vim.api.nvim_set_option_value(
            'tagfunc',
            'v:lua.vim.lsp.tagfunc',
            { buf = bufnr }
        )
    end,
})

vim.api.nvim_create_autocmd('LspAttach', {
    group = au,
    desc = 'LSP keymaps',
    callback = function(args)
        local buffer = args.buf
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        if not client then
            return
        end

        Snacks.notify(('attached to buffer %i'):format(args.buf), {
            level = vim.log.levels.DEBUG,
            title = 'LSP: ' .. client.name,
        })

        local mappings = {
            buffer = buffer,
            { 'gt', group = 'LSP: Type hierarchy', icon = '󰙅' },
            { 'gl', group = 'LSP: List calls', icon = '󰅲' },
            { '<Leader>w', group = 'LSP workspace', icon = '' },
            {
                '<Leader>wa',
                vim.lsp.buf.add_workspace_folder,
                desc = 'Add folder',
            },
            {
                '<Leader>wr',
                vim.lsp.buf.remove_workspace_folder,
                desc = 'Remove folder',
            },
            {
                '<Leader>wl',
                function()
                    Snacks.notify.info(
                        vim.lsp.buf.list_workspace_folders(),
                        { title = 'LSP workspace folders' }
                    )
                end,
                desc = 'List folders',
            },
        }

        if client:supports_method 'textDocument/codeAction' then
            mappings[#mappings + 1] = {
                '<Leader>c',
                vim.lsp.buf.code_action,
                mode = { 'n', 'v' },
                desc = 'LSP: Code action',
                icon = { icon = '', hl = 'LightBulb' },
            }
        end

        if client:supports_method('textDocument/rename', buffer) then
            mappings[#mappings + 1] = {
                '<Leader>r',
                function()
                    require('conf.lsp.nui').rename()
                end,
                desc = 'LSP: Rename symbol',
                icon = '󰏫',
            }
        end

        if client:supports_method('textDocument/definition', buffer) then
            mappings[#mappings + 1] = {
                'gd',
                function()
                    Snacks.picker.lsp_definitions()
                end,
                desc = 'LSP: Go to definition',
            }
        end
        if client:supports_method('textDocument/declaration', buffer) then
            mappings[#mappings + 1] = {
                'gD',
                function()
                    Snacks.picker.lsp_declarations()
                end,
                desc = 'LSP: Go to declaration',
            }
        end
        if client:supports_method('textDocument/implementation', buffer) then
            mappings[#mappings + 1] = {
                'gi',
                function()
                    Snacks.picker.lsp_implementations()
                end,
                desc = 'LSP: Go to implementation',
            }
        end
        if client:supports_method('textDocument/typeDefinition', buffer) then
            mappings[#mappings + 1] = {
                'gy',
                function()
                    Snacks.picker.lsp_type_definitions()
                end,
                desc = 'LSP: Go to type definition',
            }
        end
        if client:supports_method('textDocument/references', buffer) then
            mappings[#mappings + 1] = {
                'gr',
                function()
                    Snacks.picker.lsp_references()
                end,
                desc = 'LSP: References',
            }
        end
        if client:supports_method('textDocument/hover', buffer) then
            mappings[#mappings + 1] =
                { 'K', vim.lsp.buf.hover, desc = 'LSP: Hover' }
        end

        if
            client:supports_method('textDocument/prepareCallHierarchy', buffer)
        then
            mappings[#mappings + 1] = {
                'gli',
                function()
                    Snacks.picker.lsp_incoming_calls()
                end,
                desc = 'Incoming (call sites)',
                icon = '󰃺',
            }
        end
        if
            client:supports_method('textDocument/prepareCallHierarchy', buffer)
        then
            mappings[#mappings + 1] = {
                'glo',
                function()
                    Snacks.picker.lsp_outgoing_calls()
                end,
                desc = 'Outgoing (called functions)',
                icon = '󰃷',
            }
        end
        if
            client:supports_method('textDocument/prepareTypeHierarchy', buffer)
        then
            mappings[#mappings + 1] = {
                'gts',
                function()
                    Snacks.picker.lsp_supertypes()
                end,
                desc = 'Supertypes',
                icon = '󰫧',
            }
        end
        if
            client:supports_method('textDocument/prepareTypeHierarchy', buffer)
        then
            mappings[#mappings + 1] = {
                'gtb',
                function()
                    Snacks.picker.lsp_subtypes()
                end,
                desc = 'Subtypes',
                icon = '󰫤',
            }
        end

        require('which-key').add(mappings)
        vim.opt.shortmess:append 'c'
    end,
})

-- NOTE: disabled in favor of Snacks.words
--[[ vim.api.nvim_create_autocmd('LspAttach', {
    group = au,
    desc = 'LSP highlight',
    callback = function(args)
        local bufnr = args.buf
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        if
            client
            and client:supports_method 'textDocument/documentHighlight'
        then
            local augroup_lsp_highlight = 'lsp_highlight'
            vim.api.nvim_create_augroup(
                augroup_lsp_highlight,
                { clear = false }
            )
            vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
                group = augroup_lsp_highlight,
                buffer = bufnr,
                callback = vim.lsp.buf.document_highlight,
            })
            vim.api.nvim_create_autocmd('CursorMoved', {
                group = augroup_lsp_highlight,
                buffer = bufnr,
                callback = vim.lsp.buf.clear_references,
            })
        end
    end,
}) ]]

vim.api.nvim_create_autocmd('LspAttach', {
    group = au,
    desc = 'LSP inlay hints',
    callback = function(args)
        local bufnr = args.buf
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        if client and client:supports_method 'textDocument/inlayHint' then
            Snacks.notify('registered inlay hints', {
                level = vim.log.levels.DEBUG,
                title = 'LSP: ' .. client.name,
            })
            vim.api.nvim_create_autocmd({
                'BufWritePost',
                'BufEnter',
                'FocusGained',
                'CursorHold',
            }, {
                buffer = bufnr,
                callback = function()
                    vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
                end,
            })
            vim.api.nvim_create_autocmd('ModeChanged', {
                buffer = bufnr,
                callback = function(args)
                    local _, new_mode = unpack(vim.split(args.match, ':'))
                    if

                        vim.tbl_contains(
                            { 'i', 'v', 'V', '\22', 'R' },
                            new_mode
                        )
                        and vim.lsp.inlay_hint.is_enabled { bufnr = bufnr }
                    then
                        vim.lsp.inlay_hint.enable(false, { bufnr = bufnr })
                    elseif
                        new_mode == 'n'
                        and not vim.lsp.inlay_hint.is_enabled { bufnr = bufnr }
                    then
                        vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
                    end
                end,
                desc = 'LSP inlay hints: disable for insert & visual mode',
            })
            -- initial request
            vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
        end
    end,
})

--[[ vim.api.nvim_create_autocmd('LspAttach', {
                group = au,
                desc = 'LSP signature help',
                callback = function(args)
                    local bufnr = args.buf
                    local client = vim.lsp.get_client_by_id(args.data.client_id)
                    if client:supports_method 'textDocument/signatureHelp' then
                        vim.api.nvim_create_autocmd('CursorHoldI', {
                            buffer = bufnr,
                            callback = function()
                                vim.defer_fn(vim.lsp.buf.signature_help, 200)
                            end,
                        })
                    end
                end,
            }) ]]

vim.lsp.on_type_formatting.enable()
vim.lsp.codelens.enable()

vim.lsp.config('*', {
    root_markers = { '.git' },
    capabilities = require('conf.lsp.protocol').capabilities,
})

vim.lsp.enable {
    'angular_ls',
    'astro',
    'basedpyright',
    'bash_ls',
    'css_ls',
    -- 'demo_ls',
    'docker_compose_ls',
    'docker_ls',
    'emmylua_ls',
    'expert',
    'gitlab_ci_ls',
    'helm_ls',
    'html_ls',
    'json_ls',
    -- 'lua_ls',
    'nickel_ls',
    'nushell',
    'pkl_ls',
    'pyrefly',
    'pyright',
    'ruff',
    'sourcekit',
    'svelte',
    'tailwindcss',
    'terraform_ls',
    'tombi',
    'tsgo',
    'ts_query_ls',
    'ty',
    -- 'vts_ls',
    'yaml_ls',
    -- 'zuban',
}
