---@type vim.lsp.Config
return {
    cmd = { 'emmylua_ls' },
    filetypes = { 'lua' },
    root_markers = {
        '.luarc.json',
        '.luarc.jsonc',
        '.stylua.toml',
        'stylua.toml',
        '.git',
    },
}

-- requires .luarc.json
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
