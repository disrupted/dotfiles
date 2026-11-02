-- Program Status Protocol (OSC 7501): reports Neovim itself as record "nvim"
-- and each native progress-message as a child record beneath it.
if vim.env.TMUX then
    return
end

local function send(fields)
    local pairs_ = {}
    for _, kv in ipairs(fields) do
        table.insert(pairs_, kv[1] .. '=' .. kv[2])
    end
    pcall(vim.api.nvim_ui_send, '\27]7501;' .. table.concat(pairs_, ':') .. '\27\\')
end

---@param text string|[string, any?][]
local function b64(text)
    if type(text) == 'table' then
        text = table.concat(vim.tbl_map(function(chunk)
            return chunk[1]
        end, text))
    end
    return vim.base64.encode((tostring(text):gsub('%c', ' ')))
end

local states = { running = 'working', success = 'done', failed = 'error' }

local function on_progress(ev)
    local data = ev.data
    -- opt-in, so routine progress (LSP, vim.pack) doesn't become terminal noise
    if type(data.data) ~= 'table' or not data.data.program_status then
        return
    end
    local id = 'nvim/' .. tostring(data.id):gsub('[^%w_.+-]', '_'):sub(1, 32)
    local state = states[data.status]
    if not state then
        send({ { 'id', id }, { 'state', 'clear' } })
        return
    end
    local fields = { { 'id', id }, { 'state', state } }
    if state == 'working' and data.percent then
        table.insert(fields, { 'progress', math.floor(data.percent) })
    end
    if data.title and data.title ~= '' then
        table.insert(fields, { 'title', b64(data.title) })
    end
    local msg = data.text and b64(data.text)
    if msg and msg ~= '' then
        table.insert(fields, { 'msg', msg })
    end
    send(fields)
end

local function announce()
    send({ { 'id', 'nvim' }, { 'state', 'idle' }, { 'app', 'nvim' } })
end

local function retract()
    send({ { 'id', 'nvim' }, { 'state', 'clear' } })
end

local group = vim.api.nvim_create_augroup('program_status', { clear = true })
vim.api.nvim_create_autocmd({ 'VimEnter', 'VimResume' }, { group = group, callback = announce })
vim.api.nvim_create_autocmd({ 'VimLeavePre', 'VimSuspend' }, { group = group, callback = retract })
vim.api.nvim_create_autocmd('Progress', { group = group, callback = on_progress })
if vim.v.vim_did_enter == 1 then
    announce()
end
