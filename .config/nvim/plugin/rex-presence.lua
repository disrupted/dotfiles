-- Program Status Protocol (OSC 7501) record so the terminal can tell Neovim
-- is running without relying on the process name.
if vim.env.TMUX then
    return
end

local function send(body)
    pcall(vim.api.nvim_chan_send, vim.v.stderr, '\27]7501;' .. body .. '\27\\')
end

local function announce()
    send('id=nvim:state=idle:app=nvim')
end

local function retract()
    send('id=nvim:state=clear')
end

local group = vim.api.nvim_create_augroup('rex_presence', { clear = true })
vim.api.nvim_create_autocmd(
    { 'VimEnter', 'VimResume' },
    { group = group, callback = announce }
)
vim.api.nvim_create_autocmd(
    { 'VimLeavePre', 'VimSuspend' },
    { group = group, callback = retract }
)
if vim.v.vim_did_enter == 1 then
    announce()
end
