local function subvert(opts)
    require('conf.subvert').command(opts)
end

local command_opts = {
    nargs = 1,
    range = true,
    bang = true,
    desc = 'Subvert: case-preserving substitution with brace variants',
}
if vim.fn.exists(':S') ~= 2 then
    vim.api.nvim_create_user_command('S', subvert, command_opts)
end
vim.api.nvim_create_user_command('Subvert', subvert, command_opts)
