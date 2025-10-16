local project_library_path = assert(vim.uv.cwd())

local cmd = {
    'ngserver',
    '--stdio',
    '--tsProbeLocations',
    project_library_path,
    '--ngProbeLocations',
    project_library_path,
}

---@type vim.lsp.Config
return {
    cmd = cmd,
    filetypes = {
        'typescript',
        'html',
        'typescriptreact',
        'typescript.tsx',
        'htmlangular',
    },
    root_markers = { 'angular.json', 'nx.json' },
    on_new_config = function(new_config, new_root_dir)
        new_config.cmd = cmd
    end,
}
