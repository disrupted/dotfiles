---@type vim.lsp.Config
return {
    cmd = { 'emmylua_ls' },
    filetypes = { 'lua' },
    root_markers = {
        '.emmyrc.json',
        '.luarc.json',
        '.git',
    },
    workspace_required = true,
}

-- settings: .emmyrc.json; libraries: .luarc.json (generated, see lua/conf/emmylua.lua)
