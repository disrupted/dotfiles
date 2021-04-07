local M = {}

function M.setup()
    vim.cmd [[packadd lsp-status.nvim]]
    vim.cmd [[packadd nvim-lspconfig]]
    vim.fn.sign_define("LspDiagnosticsSignError",
                       {text = "◉", texthl = "LspDiagnosticsDefaultError"})
    vim.fn.sign_define("LspDiagnosticsSignWarning",
                       {text = "●", texthl = "LspDiagnosticsDefaultWarning"})
    vim.fn.sign_define("LspDiagnosticsSignInformation", {
        text = "•",
        texthl = "LspDiagnosticsDefaultInformation"
    })
    vim.fn.sign_define("LspDiagnosticsSignHint",
                       {text = "»", texthl = "LspDiagnosticsDefaultHint"})
    vim.fn.sign_define("LightBulbSign", {
        text = "◎",
        texthl = "Number",
        linehl = "",
        numhl = ""
    })

    vim.lsp.handlers["textDocument/publishDiagnostics"] =
        vim.lsp.with(vim.lsp.diagnostic.on_publish_diagnostics, {
            underline = false,
            signs = true,
            virtual_text = {spacing = 4, prefix = ' '},
            update_in_insert = false -- delay update
        })

    -- Handle formatting in a smarter way
    -- If the buffer has been edited before formatting has completed, do not try to
    -- apply the changes, by Lukas Reineke
    vim.lsp.handlers['textDocument/formatting'] =
        function(err, _, result, _, bufnr)
            if err ~= nil or result == nil then return end

            -- If the buffer hasn't been modified before the formatting has finished,
            -- update the buffer
            if not vim.api.nvim_buf_get_option(bufnr, 'modified') then
                local view = vim.fn.winsaveview()
                vim.lsp.util.apply_text_edits(result, bufnr)
                vim.fn.winrestview(view)
                if bufnr == vim.api.nvim_get_current_buf() then
                    vim.api.nvim_command('noautocmd :update')

                    -- Trigger post-formatting autocommand which can be used to refresh gitgutter
                    vim.api.nvim_command(
                        'silent doautocmd <nomodeline> User FormatterPost')
                end
            end
        end
end

function M.config()
    local lspconfig = require 'lspconfig'
    local lsp_status = require 'lsp-status'
    lsp_status.register_progress()
    -- client log level
    vim.lsp.set_log_level('info')

    local on_attach = function(client, bufnr)
        local function buf_set_keymap(...)
            vim.api.nvim_buf_set_keymap(bufnr, ...)
        end
        local function buf_set_option(...)
            vim.api.nvim_buf_set_option(bufnr, ...)
        end

        -- omni completion source
        buf_set_option('omnifunc', 'v:lua.vim.lsp.omnifunc')

        -- Mappings.
        local opts = {noremap = true, silent = true}
        buf_set_keymap('n', 'gD', '<Cmd>lua vim.lsp.buf.declaration()<CR>', opts)
        buf_set_keymap('n', 'gd', '<Cmd>lua vim.lsp.buf.definition()<CR>', opts)
        buf_set_keymap('n', 'K', '<Cmd>lua vim.lsp.buf.hover()<CR>', opts)
        buf_set_keymap('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>',
                       opts)
        buf_set_keymap('n', '<C-k>',
                       '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
        buf_set_keymap('n', '<space>wa',
                       '<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>', opts)
        buf_set_keymap('n', '<space>wr',
                       '<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>',
                       opts)
        buf_set_keymap('n', '<space>wl',
                       '<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>',
                       opts)
        buf_set_keymap('n', '<space>D',
                       '<cmd>lua vim.lsp.buf.type_definition()<CR>', opts)
        buf_set_keymap('n', '<space>r', '<cmd>lua vim.lsp.buf.rename()<CR>',
                       opts)
        buf_set_keymap('n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', opts)
        buf_set_keymap('n', '<space>d',
                       '<cmd>lua vim.lsp.diagnostic.show_line_diagnostics()<CR>',
                       opts)
        buf_set_keymap('n', '[d', '<cmd>lua vim.lsp.diagnostic.goto_prev()<CR>',
                       opts)
        buf_set_keymap('n', ']d', '<cmd>lua vim.lsp.diagnostic.goto_next()<CR>',
                       opts)
        buf_set_keymap('n', '<space>q',
                       '<cmd>lua vim.lsp.diagnostic.set_loclist()<CR>', opts)
        buf_set_keymap('n', '<leader>ls',
                       '<cmd>lua vim.lsp.buf.document_symbol()<CR>', opts)
        buf_set_keymap('n', '<leader>lS',
                       '<cmd>lua vim.lsp.buf.workspace_symbol()<CR>', opts)
        vim.o.shortmess = vim.o.shortmess .. "c"

        -- Set autocommands conditional on server_capabilities
        if client.resolved_capabilities.document_formatting then
            vim.api.nvim_exec([[
                augroup format_on_save
                  autocmd! * <buffer>
                  autocmd BufWritePost <buffer> lua vim.lsp.buf.formatting()
                augroup END
              ]], false)
        end

        if client.resolved_capabilities.document_highlight then
            vim.api.nvim_exec([[
                augroup lsp_document_highlight
                  autocmd! * <buffer>
                  autocmd CursorHold <buffer> lua vim.lsp.buf.document_highlight()
                  autocmd CursorMoved <buffer> lua vim.lsp.buf.clear_references()
                augroup END
              ]], false)
        end

        if client.resolved_capabilities.code_action then
            vim.cmd [[packadd nvim-lightbulb]]
            vim.cmd [[autocmd CursorHold,CursorHoldI * lua require'nvim-lightbulb'.update_lightbulb()]]
            buf_set_keymap('n', '<leader>a',
                           '<cmd>lua require\'telescope.builtin\'.lsp_code_actions()<CR>',
                           opts)
        end

        vim.cmd [[autocmd CursorHold * lua vim.lsp.diagnostic.show_line_diagnostics()]]
        vim.cmd [[autocmd CursorHoldI * silent! lua vim.lsp.buf.signature_help()]]

        print("LSP attached.")
    end
    -- define language servers
    -- https://github.com/palantir/python-language-server
    -- lspconfig.pyls.setup {
    --     on_attach = on_attach,
    --     cmd = {"pyls", "--log-file", "/tmp/pyls.log", "--verbose"},
    --     settings = {
    --         pyls = {
    --             configurationSources = {"pycodestyle", "flake8"},
    --             plugins = {
    --                 yapf = {enabled = false},
    --                 pylint = {enabled = false},
    --                 pycodestyle = {enabled = false},
    --                 pyflakes = {enabled = false},
    --                 pydocstyle = {enabled = false},
    --                 flake8 = {enabled = true},
    --                 pyls_mypy = {enabled = true}
    --             }
    --         }
    --     }
    -- }
    lspconfig.pyright.setup {on_attach = on_attach}
    -- lspconfig.vimls.setup {}
    -- lspconfig.jdtls.setup{}
    -- lspconfig.jsonls.setup {}
    -- lspconfig.dockerls.setup {}
    lspconfig.yamlls.setup {
        settings = {
            yaml = {
                customTags = {
                    "!secret", "!include_dir_named", "!include_dir_list",
                    "!include_dir_merge_named", "!include_dir_merge_list",
                    "!lambda", "!input"
                }
            }
        }
    }

    -- https://github.com/theia-ide/typescript-language-server
    lspconfig.tsserver.setup {
        on_attach = function(client)
            client.resolved_capabilities.document_formatting = false
            on_attach(client)
        end
    }

    -- EFM Universal Language Server
    -- https://github.com/mattn/efm-langserver
    local efm_config = os.getenv('HOME') ..
                           '/.config/efm-langserver/config.yaml'
    local log_dir = "/tmp/"
    local black = require "efm/black"
    local isort = require "efm/isort"
    local mypy = require "efm/mypy"
    local lua_format = require "efm/lua-format"
    local prettier = require "efm/prettier"
    local eslint = require "efm/eslint"
    local eslint_d = require "efm/eslint_d"
    local rustfmt = require "efm/rustfmt"
    local gofmt = require "efm/gofmt"

    lspconfig.efm.setup {
        cmd = {
            "efm-langserver", "-c", efm_config, "-logfile", log_dir .. "efm.log"
        },
        on_attach = on_attach,
        filetypes = {
            "python", "lua", "yaml", "json", "markdown", "rst", "html", "css",
            "javascript", "typescript", "javascriptreact", "typescriptreact",
            "dockerfile"
        },
        -- Fallback to .bashrc as a project root to enable LSP on loose files
        root_dir = function(fname)
            return lspconfig.util.root_pattern("tsconfig.json")(fname) or
                       lspconfig.util
                           .root_pattern(".eslintrc.js", ".git")(fname) or
                       lspconfig.util.root_pattern("package.json", ".git/",
                                                   ".zshrc")(fname);
        end,
        init_options = {documentFormatting = true},
        settings = {
            rootMarkers = {"package.json", "go.mod", ".git/", ".zshrc"},
            languages = {
                python = {isort, black},
                lua = {lua_format},
                yaml = {prettier},
                json = {prettier},
                markdown = {prettier},
                html = {prettier},
                css = {prettier},
                javascript = {prettier, eslint_d},
                typescript = {prettier, eslint_d},
                javascriptreact = {prettier, eslint_d},
                typescriptreact = {prettier, eslint_d}
                -- rust = {rustfmt}, -- not needed with rust_analyzer
                -- go = {gofmt}, -- not needed with gopls
            }
        }
    }

    lspconfig.rust_analyzer.setup {on_attach = on_attach}

    lspconfig.gopls.setup {on_attach = on_attach}
end

return M
