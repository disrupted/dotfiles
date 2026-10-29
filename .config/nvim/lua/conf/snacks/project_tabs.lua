--- Open a tabpage per mise config root (backend/, frontend/, ...).
---
--- The tab gets a tab-local cwd (`:tcd`), so pickers and :e in that tab are
--- scoped to the root, while tools still derive their root from file paths.
--- Picking a root that already has a tab switches to it.
local M = {}

--- Tabpage whose cwd is `root`.
---@param root string
---@return integer?
function M.find_tab(root)
    for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
        local nr = vim.api.nvim_tabpage_get_number(tab)
        if vim.fs.normalize(vim.fn.getcwd(-1, nr)) == root then
            return tab
        end
    end
end

---@param root string
---@return string
local function label(root)
    local workspace = vim.g.workspace_root
    if root == workspace then
        return vim.fs.basename(root)
    end
    return vim.fs.relpath(workspace, root) or root
end

---@param root string
function M.open(root)
    local tab = M.find_tab(root)
    if tab then
        vim.api.nvim_set_current_tabpage(tab)
        return
    end
    vim.cmd.tabnew()
    vim.cmd.tcd(vim.fn.fnameescape(root))
    vim.t.tabname = label(root)
    vim.cmd.redrawtabline()
    require('conf.snacks.files').pick()
end

---@return snacks.Picker?
function M.pick()
    local workspace = vim.g.workspace_root
    if not workspace then
        return
    end
    local roots = { workspace }
    vim.list_extend(roots, require('conf.project').roots())
    if #roots == 1 then
        Snacks.notify.warn('No mise config roots', { title = 'Project' })
        return
    end

    local items = {}
    for idx, root in ipairs(roots) do
        items[#items + 1] = {
            idx = idx,
            text = label(root),
            file = root,
            dir = true,
            open = M.find_tab(root) ~= nil,
        }
    end

    return Snacks.picker({
        title = 'Project Tabs',
        items = items,
        format = function(item)
            local ret = {
                { item.file == workspace and '󰉋 ' or '󰉖 ', 'SnacksPickerDirectory' },
                { item.text, 'SnacksPickerFile' },
            }
            if item.open then
                ret[#ret + 1] = { '  (open)', 'SnacksPickerComment' }
            end
            return ret
        end,
        layout = { preset = 'select' },
        confirm = function(picker, item)
            picker:close()
            if item and item.file then
                M.open(item.file)
            end
        end,
    })
end

return M
