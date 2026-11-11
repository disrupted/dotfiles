local TERMINAL = "com.superlogical.terminal"
local VIM = { vim = true, nvim = true, view = true, vimdiff = true }

-- Neovim reports app=nvim via OSC 7501, which survives ssh and pty wrappers
-- unlike the process name. The result shape is undocumented, hence the search.
local function has_app_record(t, app, depth)
	if type(t) ~= "table" or depth > 4 then
		return false
	end
	if t.app == app and t.state ~= "clear" then
		return true
	end
	for _, v in pairs(t) do
		if has_app_record(v, app, depth + 1) then
			return true
		end
	end
	return false
end

local function has_nvim_record(t, depth)
	return has_app_record(t, "nvim", depth)
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
		rex.session.focus_direction({ direction = direction })
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
	local view = rex.session.view({})
	if not view then
		return
	end
	local _, idx = active_window(view)
	local target = idx and idx + delta
	if not target or target < 1 or target > #view.windows then
		return
	end
	local before = delta < 0 and view.windows[target] or view.windows[target + 1]
	rex.session.move_window({
		window_id = view.active_window_id,
		before_window_id = before and before.window_id or nil,
	})
end

rex.action({
	name = "tab_move_left",
	title = "Move Tab Left",
	run = function()
		move_tab(-1)
	end,
})
rex.action({
	name = "tab_move_right",
	title = "Move Tab Right",
	run = function()
		move_tab(1)
	end,
})
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
local function cell_size(window, block_id, cols, rows, max_w, max_h)
	local w, h = max_w, max_h
	local ok, size = pcall(rex.block.call, TERMINAL, "size", { block_id = block_id })
	local node = find_block(window, block_id)
	local rect = node and node.rect
	if ok and size and size.columns and size.rows then
		w = math.min(cols * (rect and rect[3] or 1) / size.columns, max_w)
		h = math.min(rows * (rect and rect[4] or 1) / size.rows, max_h)
	end
	return w, h
end

local function scratch_bounds(window, block_id)
	local w, h = cell_size(window, block_id, SCRATCH.cols, SCRATCH.rows, SCRATCH.max_w, SCRATCH.max_h)
	local m = SCRATCH.margin
	return { 1 - w - m, 1 - h - m, w, h }
end

local function cwd_of(block_id)
	local ok, r = pcall(rex.block.call, TERMINAL, "pwd", { block_id = block_id })
	local url = ok and r and (r.pwd or r.url)
	return type(url) == "string" and url:gsub("^file://[^/]*", "") or nil
end

rex.action({
	name = "scratch_toggle",
	title = "Toggle Scratch Terminal",
	run = function(ctx)
		local view, err = rex.session.view({})
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
				local _, derr = rex.session.detach_block({ block_id = id })
				if derr then
					rex.session.close_layer({ layer_id = layer.layer_id })
					scratch[win.window_id] = nil
				end
				return
			end
			local _, ferr = rex.session.float_block({
				block_id = id,
				bounds = scratch_bounds(win, win.focused_block_id or ctx.block_id),
			})
			if not ferr then
				rex.session.focus_block({ block_id = id })
				return
			end
			scratch[win.window_id] = nil
		end

		local r, nerr = rex.session.new_layer({
			window_id = win.window_id,
			bounds = scratch_bounds(win, ctx.block_id),
			focus = true,
			layout = rex.layout.block({
				flavor = "com.superlogical.terminal.shell",
				label = "scratch",
				options = { cwd = cwd_of(ctx.block_id) },
			}),
		})
		if nerr then
			error(nerr, 0)
		end
		scratch[win.window_id] = r.block_ids[1]
	end,
})
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
rex.action({
	name = "session_name_from_dir",
	title = "Name Session After Repo or Worktree",
	keywords = "rename session worktree git repo",
	run = function(ctx)
		local ok, proc = pcall(rex.block.call, TERMINAL, "process", { block_id = ctx.block_id })
		local dir = ok and proc and proc.foreground and proc.foreground.cwd or cwd_of(ctx.block_id)
		if not dir then
			error("can't tell which folder this pane is in", 0)
		end
		local _, err = rex.session.set_label({ label = session_name_for(dir) })
		if err then
			error(err, 0)
		end
	end,
})

require("rex-worktrunk").setup({
	base = "@",
	label = session_name_for,
	script = "~/.config/rex/worktrunk-picker.sh",
	bounds = { 0.2, 0.25, 0.6, 0.5 }, -- x, y, width, height as fractions of the window
})

local WT = os.getenv("HOME") .. "/.local/share/mise/shims/wt"

rex.action({
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
		local _, err = rex.session.new_layer({
			bounds = { 0.2, 0.25, 0.6, 0.5 },
			focus = true,
			layout = rex.layout.block({
				flavor = "com.superlogical.terminal.shell",
				label = "worktree prune",
				options = { cwd = dir, command = { os.getenv("HOME") .. "/.config/rex/worktrunk-prune.sh" } },
			}),
		})
		if err then
			error(err, 0)
		end
	end,
})

rex.bind("cmd+o", "worktree")
rex.bind("alt+cmd+o", "worktree_remove")
rex.bind("shift+cmd+o", "worktree_prune")

rex.bind("shift+cmd+r", "session_name_from_dir")

-- Neovim calls `rex do rextask_pick`, keep the name
local REXTASK = {
	bin = os.getenv("HOME") .. "/.local/share/mise/cargo/bin/rextask",
	size = "100x30",
}

local function pane_dir(block_id)
	local ok, proc = pcall(rex.block.call, TERMINAL, "process", { block_id = block_id })
	return ok and proc and proc.foreground and proc.foreground.cwd or cwd_of(block_id)
end

rex.action({
	name = "rextask_pick",
	title = "Tasks: Run mise Task…",
	category = "Tasks",
	keywords = "mise task run rextask jobs",
	args = { cwd = "string?", mode = "string?" },
	run = function(ctx, args)
		args = args or {}
		local dir = args.cwd or pane_dir(ctx.block_id) or os.getenv("HOME")
		local cmd = { REXTASK.bin, "pick", "--dir", dir, "--size", REXTASK.size }
		if args.mode == "running" then
			table.insert(cmd, "--running")
		end
		local r = rex.exec(cmd, {
			env = { REX_SESSION = ctx.session_id, REX_BLOCK = ctx.block_id or "" },
		})
		if r and not r.ok then
			error((r.stderr or ""):gsub("^rextask: ", ""):gsub("%s+$", ""), 0)
		end
	end,
})

rex.action({
	name = "rextask_toggle",
	title = "Tasks: Toggle Latest Task Window",
	category = "Tasks",
	keywords = "rextask minimize restore show hide",
	run = function(ctx)
		local r = rex.exec({ REXTASK.bin, "toggle" }, {
			env = { REX_SESSION = ctx.session_id, REX_BLOCK = ctx.block_id or "" },
		})
		if r and not r.ok then
			error((r.stderr or ""):gsub("^rextask: ", ""):gsub("%s+$", ""), 0)
		end
	end,
})

rex.bind("cmd+j", "rextask_pick")
rex.bind("shift+cmd+j", "rextask_pick", { mode = "running" })
rex.bind("alt+cmd+j", "rextask_toggle")
-- bound here, not in rextask: exec only reads keys once the task exits
rex.bind("\\", function(ctx)
	local ok, status = pcall(rex.block.call, TERMINAL, "program_status", {})
	if not (ok and has_app_record(status, "rextask", 0)) then
		return false
	end
	local view = rex.session.view({})
	local win = view and active_window(view)
	local id = ctx and ctx.block_id or (win and win.focused_block_id)
	local _, layer, idx = find_block(win or {}, id)
	if not (layer and idx > 1) then
		return false
	end
	rex.session.set_layer_state({ layer_id = layer.layer_id, state = "minimized" })
	return true
end)

rex.mode("resize", { exclusive = true })
rex.bind("cmd+;", "client.mode.enter", { name = "resize" })
for key, direction in pairs({ h = "left", j = "down", k = "up", l = "right" }) do
	rex.bind("resize/" .. key, "pane.resize", { direction = direction })
	rex.bind("resize/shift+" .. key, "pane.resize", { direction = direction, amount = 15 })
end
rex.bind("resize/=", "pane.balance")
rex.bind("resize/enter", "client.mode.exit")
