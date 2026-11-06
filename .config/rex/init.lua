local TERMINAL = "com.superlogical.terminal"
local VIM = { vim = true, nvim = true, view = true, vimdiff = true }

-- Neovim reports app=nvim via OSC 7501, which survives ssh and pty wrappers
-- unlike the process name. The result shape is undocumented, hence the search.
local function has_nvim_record(t, depth)
  if type(t) ~= "table" or depth > 4 then
    return false
  end
  if t.app == "nvim" and t.state ~= "clear" then
    return true
  end
  for _, v in pairs(t) do
    if has_nvim_record(v, depth + 1) then
      return true
    end
  end
  return false
end

local function in_vim()
  local ok, status = pcall(rex.block.call, TERMINAL, "program_status", {})
  if ok and has_nvim_record(status, 0) then
    return true
  end
  local ok2, proc = pcall(rex.block.call, TERMINAL, "process", {})
  local fg = ok2 and proc and proc.foreground
  return fg ~= nil and (VIM[fg.name] or VIM[fg.argv0]) == true
end

for key, direction in pairs({
  ["ctrl+h"] = "left",
  ["ctrl+j"] = "down",
  ["ctrl+k"] = "up",
  ["ctrl+l"] = "right",
}) do
  rex.bind(key, function()
    if in_vim() then
      return false
    end
    rex.session.focus_direction{ direction = direction }
    return true
  end)
end

rex.bind("alt+z", "pane.zoom")

local function active_window(view)
  for i, w in ipairs(view.windows or {}) do
    if w.window_id == view.active_window_id then
      return w, i
    end
  end
end

local function move_tab(delta)
  local view = rex.session.view{}
  if not view then
    return
  end
  local _, idx = active_window(view)
  local target = idx and idx + delta
  if not target or target < 1 or target > #view.windows then
    return
  end
  local before = delta < 0 and view.windows[target] or view.windows[target + 1]
  rex.session.move_window{
    window_id = view.active_window_id,
    before_window_id = before and before.window_id or nil,
  }
end

rex.action{ name = "tab_move_left", title = "Move Tab Left", run = function() move_tab(-1) end }
rex.action{ name = "tab_move_right", title = "Move Tab Right", run = function() move_tab(1) end }
rex.bind("ctrl+shift+left", "tab_move_left")
rex.bind("ctrl+shift+right", "tab_move_right")

local SCRATCH = { cols = 120, rows = 30, max_w = 0.6, max_h = 0.5, margin = 0.02 }
local scratch = {} -- window_id -> block_id

local function find_block(window, block_id)
  for i, layer in ipairs(window.layers or {}) do
    local hit
    local function walk(node)
      if not node or hit then
        return
      end
      if node.block_id == block_id then
        hit = node
      elseif node.split then
        walk(node.split.before)
        walk(node.split.after)
      end
    end
    walk(layer.layout)
    if hit then
      return hit, layer, i
    end
  end
end

-- Layer bounds are window fractions, so derive the window's size in cells
-- from the focused pane's size and its share of the window.
local function scratch_bounds(window, block_id)
  local w, h = SCRATCH.max_w, SCRATCH.max_h
  local ok, size = pcall(rex.block.call, TERMINAL, "size", { block_id = block_id })
  local node = find_block(window, block_id)
  local rect = node and node.rect
  if ok and size and size.columns and size.rows then
    w = math.min(SCRATCH.cols * (rect and rect[3] or 1) / size.columns, SCRATCH.max_w)
    h = math.min(SCRATCH.rows * (rect and rect[4] or 1) / size.rows, SCRATCH.max_h)
  end
  local m = SCRATCH.margin
  return { 1 - w - m, 1 - h - m, w, h }
end

local function cwd_of(block_id)
  local ok, r = pcall(rex.block.call, TERMINAL, "pwd", { block_id = block_id })
  local url = ok and r and (r.pwd or r.url)
  return type(url) == "string" and url:gsub("^file://[^/]*", "") or nil
end

rex.action{
  name = "scratch_toggle",
  title = "Toggle Scratch Terminal",
  run = function(ctx)
    local view, err = rex.session.view{}
    if err then
      error(err, 0)
    end
    local win = active_window(view)
    if not win then
      return
    end

    local id = scratch[win.window_id]
    if id then
      local _, layer, idx = find_block(win, id)
      if layer and idx > 1 then
        local _, derr = rex.session.detach_block{ block_id = id }
        if derr then
          rex.session.close_layer{ layer_id = layer.layer_id }
          scratch[win.window_id] = nil
        end
        return
      end
      local _, ferr = rex.session.float_block{
        block_id = id,
        bounds = scratch_bounds(win, win.focused_block_id or ctx.block_id),
      }
      if not ferr then
        rex.session.focus_block{ block_id = id }
        return
      end
      scratch[win.window_id] = nil
    end

    local r, nerr = rex.session.new_layer{
      window_id = win.window_id,
      bounds = scratch_bounds(win, ctx.block_id),
      focus = true,
      layout = rex.layout.block{
        flavor = "com.superlogical.terminal.shell",
        label = "scratch",
        options = { cwd = cwd_of(ctx.block_id) },
      },
    }
    if nerr then
      error(nerr, 0)
    end
    scratch[win.window_id] = r.block_ids[1]
  end,
}
rex.bind("ctrl+\\", "scratch_toggle")

-- "<repo>   󰙅 <worktree>" for <repo>.worktrees/<worktree> (see worktrunk's
-- worktree-path), else the folder name. Path only: the folder may be gone.
local function session_name_for(dir)
  dir = dir:gsub("/+$", "")
  local repo, worktree = dir:match("([^/]+)%.worktrees/([^/]+)$")
  if repo then
    -- nf-md-file_tree as UTF-8 bytes, since Lua 5.1 has no \u escapes.
    return repo .. "   \243\176\153\133 " .. worktree
  end
  return dir:match("([^/]+)$") or dir
end

-- For sessions opened by hand; the worktree picker names its own.
rex.action{
  name = "session_name_from_dir",
  title = "Name Session After Repo or Worktree",
  keywords = "rename session worktree git repo",
  run = function(ctx)
    local ok, proc = pcall(rex.block.call, TERMINAL, "process", { block_id = ctx.block_id })
    local dir = ok and proc and proc.foreground and proc.foreground.cwd or cwd_of(ctx.block_id)
    if not dir then
      error("can't tell which folder this pane is in", 0)
    end
    local _, err = rex.session.set_label{ label = session_name_for(dir) }
    if err then
      error(err, 0)
    end
  end,
}

-- Worktree pickers with a session per worktree. The label option comes from the
-- label-option branch of my fork, until https://github.com/haxybaxy/rex-worktrunk/pull/2 lands.
require("rex-worktrunk").setup{
  base = "@",
  label = session_name_for,
  script = "~/.config/rex/worktrunk-picker.sh",
  bounds = { 0.2, 0.25, 0.6, 0.5 }, -- x, y, width, height as fractions of the window
}

local WT = os.getenv("HOME") .. "/.local/share/mise/shims/wt"

rex.action{
  name = "worktree_prune",
  title = "Worktree: remove merged…",
  category = "Worktree",
  keywords = "git worktree prune merged cleanup worktrunk wt",
  run = function(ctx)
    local ok, proc = pcall(rex.block.call, TERMINAL, "process", { block_id = ctx.block_id })
    local dir = ok and proc and proc.foreground and proc.foreground.cwd or cwd_of(ctx.block_id)
    if not dir then
      error("can't tell which folder this pane is in", 0)
    end
    rex.exec({ "git", "fetch", "--prune", "--quiet" }, { cwd = dir })
    local r = rex.exec({ WT, "step", "prune", "--dry-run", "--min-age", "0", "--format", "json" }, { cwd = dir })
    if not (r and r.ok) then
      error("not in a git repository", 0)
    end
    if r.stdout:match("^%s*%[%s*%]%s*$") then
      error("no merged worktrees to remove", 0)
    end
    local _, err = rex.session.new_layer{
      bounds = { 0.2, 0.25, 0.6, 0.5 },
      focus = true,
      layout = rex.layout.block{
        flavor = "com.superlogical.terminal.shell",
        label = "worktree prune",
        options = { cwd = dir, command = { os.getenv("HOME") .. "/.config/rex/worktrunk-prune.sh" } },
      },
    }
    if err then
      error(err, 0)
    end
  end,
}

rex.bind("cmd+o", "worktree")
rex.bind("alt+cmd+o", "worktree_remove")
rex.bind("shift+cmd+o", "worktree_prune")

rex.bind("shift+cmd+r", "session_name_from_dir")

rex.mode("resize", { exclusive = true })
rex.bind("cmd+;", "client.mode.enter", { name = "resize" })
for key, direction in pairs({ h = "left", j = "down", k = "up", l = "right" }) do
  rex.bind("resize/" .. key, "pane.resize", { direction = direction })
  rex.bind("resize/shift+" .. key, "pane.resize", { direction = direction, amount = 15 })
end
rex.bind("resize/=", "pane.balance")
rex.bind("resize/enter", "client.mode.exit")
