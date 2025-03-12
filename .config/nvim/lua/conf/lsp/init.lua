local au = vim.api.nvim_create_augroup('LspAttach', { clear = true })

-- client log level
vim.lsp.set_log_level(vim.log.levels.WARN)

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
        require('which-key').add {
            buffer = args.buf,
            {
                '<Leader>r',
                function()
                    require('conf.lsp.nui').rename()
                end,
                desc = 'LSP: Rename symbol',
                icon = '󰏫',
            },
            {
                'gd',
                function()
                    require('trouble').open {
                        mode = 'lsp_definitions',
                        auto_jump = true,
                    }
                end,
                desc = 'LSP: Go to definition',
            },
            {
                'gr',
                function()
                    require('trouble').open { mode = 'lsp' }
                end,
                desc = 'LSP: References, definition,…',
            },
            { 'K', vim.lsp.buf.hover, desc = 'LSP: Hover' },
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
            -- TODO: current Trouble-based solution only goes one layer deep
            -- replace with something like https://github.com/jmacadie/telescope-hierarchy.nvim
            -- hopefully for Snacks or Trouble
            { '<Leader>l', group = 'LSP: List calls', icon = '󰅲' },
            {
                '<Leader>li',
                function()
                    require('trouble').open { mode = 'lsp_incoming_calls' }
                end,
                desc = 'Incoming (call sites)',
                icon = '󰃺',
            },
            {
                '<Leader>lo',
                function()
                    require('trouble').open { mode = 'lsp_outgoing_calls' }
                end,
                desc = 'Outgoing (called functions)',
                icon = '󰃷',
            },
        }
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
                'InsertLeave',
                'FocusGained',
                'CursorHold',
            }, {
                buffer = bufnr,
                callback = function()
                    vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
                end,
            })
            vim.api.nvim_create_autocmd('InsertEnter', {
                buffer = bufnr,
                callback = function()
                    vim.lsp.inlay_hint.enable(false, { bufnr = bufnr })
                end,
            })
            -- initial request
            vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
        end
    end,
})

vim.api.nvim_create_autocmd('LspAttach', {
    group = au,
    desc = 'LSP code actions',
    callback = function(args)
        local bufnr = args.buf
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        if client and client:supports_method 'textDocument/codeAction' then
            require('which-key').add {
                {
                    '<Leader>a',
                    vim.lsp.buf.code_action,
                    buffer = bufnr,
                    mode = { 'n', 'v' },
                    desc = 'LSP: Code action',
                    icon = { icon = '', hl = 'LightBulb' },
                },
            }
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

vim.api.nvim_create_autocmd('LspAttach', {
    group = au,
    desc = 'LSP notify',
    callback = function(args)
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        if client then
            Snacks.notify(('attached to buffer %i'):format(args.buf), {
                level = vim.log.levels.DEBUG,
                title = 'LSP: ' .. client.name,
            })
        end
    end,
})

-- TODO: still needed? without it Pylance was messing up buffer highlights at some point
--[[ local function periodic_refresh_semantic_tokens()
    Snacks.notify('periodic refresh semantic tokens', {
        level = vim.log.levels.DEBUG,
        title = 'LSP',
    })
    if not vim.api.nvim_buf_is_loaded(0) then
        return
    end
    vim.lsp.semantic_tokens.force_refresh(0)
    vim.defer_fn(periodic_refresh_semantic_tokens, 30000)
end

vim.api.nvim_create_autocmd({ 'TextChanged', 'InsertLeave' }, {
    callback = Snacks.util.throttle(function()
        Snacks.notify('refresh semantic tokens', {
            level = vim.log.levels.DEBUG,
            title = 'LSP',
        })
        vim.lsp.semantic_tokens.force_refresh(0)
    end, { ms = 1000 }),
}) ]]

vim.lsp.config('*', {
    root_markers = { '.git' },
    capabilities = require('conf.lsp.protocol').capabilties,
})

vim.lsp.enable {
    'basedpyright',
    'bash_ls',
    'css_ls',
    'docker_compose_ls',
    'docker_ls',
    -- 'emmylua_ls',
    'gitlab_ci_ls',
    'helm_ls',
    'html_ls',
    'json_ls',
    'lua_ls',
    -- 'pylyzer',
    'taplo',
    'terraform_ls',
    'ts_query_ls',
    'vts_ls',
    'yaml_ls',
}
