local library = vim.iter(vim.pack.get(nil, { info = false }))
    :map(function(plug)
        return plug.path
    end)
    :filter(function(path)
        return vim.uv.fs_stat(path) ~= nil
    end)
    :totable()
table.insert(library, 1, vim.env.VIMRUNTIME)

---@type vim.lsp.Config
return {
    cmd = { 'emmylua_ls' },
    filetypes = { 'lua' },
    root_markers = {
        '.emmyrc.json',
        '.luarc.json',
        '.git',
    },
    workspace_required = false,
    settings = {
        emmylua = {
            workspace = { library = library },
        },
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
