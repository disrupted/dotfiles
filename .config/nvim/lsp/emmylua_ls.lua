---@type vim.lsp.Config
return {
    cmd = { 'emmylua_ls' },
    filetypes = { 'lua' },
    root_markers = {
        '.emmyrc.json',
        '.luarc.json',
        '.git',
    },
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

-- source: https://github.com/sudo-tee/dots/commit/71b14b537ece29eb829e785f7323c2bc2ffd5ce4
-- HACK: make it work with lazydev
-- EmmyLua does not sent the workspace/didChangeConfiguration on initialization
-- so we need to do it manually on the first attach
-- vim.api.nvim_create_autocmd('LspAttach', {
--     callback = function(args)
--         local client = vim.lsp.get_client_by_id(args.data.client_id)
--         if not client or client.name ~= 'emmylua_ls' then
--             return
--         end
--         vim.api.nvim_del_autocmd(args.id) -- only needed for first attach
--         -- set runtime path
--         vim.defer_fn(function()
--             client:notify('workspace/didChangeConfiguration', {
--                 settings = { Lua = {} },
--             })
--             vim.defer_fn(function()
--                 vim.cmd.edit()
--             end, 100)
--         end, 400)
--     end,
-- })
