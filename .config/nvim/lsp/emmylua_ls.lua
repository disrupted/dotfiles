local first_attach = true

---@type vim.lsp.Config
return {
    cmd = { 'emmylua_ls' },
    filetypes = { 'lua' },
    root_markers = {
        '.emmyrc.json',
        '.luarc.json',
        '.git',
    },
    ---@param client vim.lsp.Client
    on_attach = function(client, bufnr)
        if first_attach then
            first_attach = false
            require 'lazydev'
            -- HACK: reattach first buffer, workaround for https://github.com/folke/lazydev.nvim/issues/136
            vim.defer_fn(function()
                client:on_attach(bufnr)
            end, 500)
        end
    end,
    on_exit = function()
        first_attach = true
    end,
    settings = {
        Lua = {
            -- NOTE: configured in .emmyrc.json
            -- runtime = {
            --     version = 'LuaJIT',
            -- },
            -- workspace = {
            --     ignoreGlobs = {
            --         '**/*_spec.lua', -- to avoid some weird type defs in a plugin
            --     },
            -- },
            diagnostics = {
                enable = true,
                globals = {
                    'vim',
                    'Snacks',
                    'it',
                    'describe',
                    'before_each',
                    'after_each',
                },
                disable = {
                    'unnecessary-if', -- buggy rule
                },
            },
            completion = {
                enable = true,
                -- callSnippet = true,
                callSnippet = 'Replace',
            },
            signature = {
                detailSignatureHelper = true,
            },
            strict = {
                typeCall = true,
            },
            hint = {
                metaCallHint = false,
            },
        },
    },
}

-- requires .luarc.json or .emmyrc.json
--[[ {
  "$schema": "https://raw.githubusercontent.com/LuaLS/vscode-lua/master/setting/schema.json",
  "runtime": {
    "version": "LuaJIT"
  },
  "workspace": {
    "library": [
      "$VIMRUNTIME",
      "${3rd}/luv/library",
      "$HOME/.local/share/nvim/lazy/lazy.nvim",
      "$HOME/.local/share/nvim/lazy/snacks.nvim"
    ]
  }
} ]]
