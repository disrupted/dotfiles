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
        local bufnr = args.buf
        local function map(mode, lhs, rhs, opts)
            opts = vim.tbl_extend('force', opts or {}, { buffer = bufnr })
            vim.keymap.set(mode, lhs, rhs, opts)
        end

        -- map(
        --     'n',
        --     'gD',
        --     vim.lsp.buf.declaration,
        --     { desc = 'LSP: go to declaration' }
        -- )
        map('n', 'gd', function()
            require('trouble').open {
                mode = 'lsp_definitions',
                auto_jump = true,
            }
        end, { desc = 'LSP: go to definition' })
        map('n', 'K', vim.lsp.buf.hover, { desc = 'LSP: Hover' })
        -- map(
        --     'n',
        --     'gi',
        --     vim.lsp.buf.implementation,
        --     { desc = 'LSP: go to implementation' }
        -- )
        -- map(
        --     'n',
        --     '<C-s>',
        --     vim.lsp.buf.signature_help,
        --     { desc = 'LSP: signature help' }
        -- )
        map(
            'n',
            '<leader>wa',
            vim.lsp.buf.add_workspace_folder,
            { desc = 'LSP: add workspace folder' }
        )
        map(
            'n',
            '<leader>wr',
            vim.lsp.buf.remove_workspace_folder,
            { desc = 'LSP: remove workspace folder' }
        )
        map('n', '<leader>wl', function()
            Snacks.notify.info(
                vim.lsp.buf.list_workspace_folders(),
                { title = 'LSP workspace folders' }
            )
        end, { desc = 'LSP: list workspace folders' })
        -- map(
        --     'n',
        --     '<leader>D',
        --     vim.lsp.buf.type_definition,
        --     { desc = 'LSP: type definition' }
        -- )
        map('n', '<leader>r', function()
            require('conf.lsp.nui').rename()
        end, { desc = 'LSP: rename symbol' })
        map('n', 'gr', function()
            require('trouble').open { mode = 'lsp' }
        end, {
            desc = 'LSP: list definitions, references, implementations, type definitions, and declarations',
        })
        map(
            'n',
            '<leader>li',
            vim.lsp.buf.incoming_calls,
            { desc = 'LSP: list incoming calls (call sites)' }
        )
        map(
            'n',
            '<leader>lo',
            vim.lsp.buf.outgoing_calls,
            { desc = 'LSP: list outgoing calls (called functions)' }
        )
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
        if
            client
            and client:supports_method 'textDocument/inlayHint'
            and pcall(require, 'vim.lsp.inlay_hint') -- NOTE: check that API exists
        then
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
            vim.keymap.set(
                { 'n', 'v' },
                '<leader>a',
                vim.lsp.buf.code_action,
                { buffer = bufnr }
            )
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

local function periodic_refresh_semantic_tokens()
    Snacks.notify('periodic refresh semantic tokens', {
        level = vim.log.levels.DEBUG,
        title = 'LSP',
    })
    if not vim.api.nvim_buf_is_valid(0) then
        return
    end
    vim.lsp.semantic_tokens.force_refresh(0)
    vim.defer_fn(periodic_refresh_semantic_tokens, 30000)
end

-- TODO: refactor using Snacks.util.throttle
local function debounce(ms, fn)
    local timer = assert(vim.uv.new_timer())
    return function(...)
        local argv = { ... }
        timer:start(ms, 0, function()
            timer:stop()
            vim.schedule_wrap(fn)(unpack(argv))
        end)
    end
end

vim.api.nvim_create_autocmd({ 'TextChanged', 'InsertLeave' }, {
    callback = debounce(1000, function()
        Snacks.notify('refresh semantic tokens', {
            level = vim.log.levels.DEBUG,
            title = 'LSP',
        })
        vim.lsp.semantic_tokens.force_refresh(0)
    end),
})

vim.lsp.config('*', {
    root_markers = { '.git' },
    capabilities = require('conf.lsp.protocol').capabilties,
})

vim.lsp.enable {
    -- 'basedpyright',
    'bash_ls',
    'css_ls',
    'docker_compose_ls',
    'docker_ls',
    'gitlab_ci_ls',
    'helm_ls',
    'html_ls',
    'json_ls',
    'lua_ls',
    -- 'pylyzer',
    'taplo',
    'terraform_ls',
    'vts_ls',
    'yaml_ls',
}
