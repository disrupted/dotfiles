workspace = function()
    local w = vim.lsp.buf.list_workspace_folders()
    if w[0] ~= nil then return w[0] end
    if w[1] ~= nil then return w[1] end
end

return {
    formatCommand = "cd $(~/.config/scripts/fd_project_root.sh \"${INPUT}\"); isort --profile black --quiet --stdout -",
    formatStdin = true
}
