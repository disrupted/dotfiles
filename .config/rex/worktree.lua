-- One Rex session per git worktree, picked with worktrunk's own picker
-- (`wt switch`). The picker runs in a float and hands its pick back with
-- `rex do worktree_go`; worktrunk's post-remove hook calls `rex do
-- worktree_close`, which goes back to the session the worktree was opened from.
local M = {}

local SHELL = "com.superlogical.terminal.shell"
local HOME = os.getenv("HOME") or ""

-- Rex keeps no data on a session, and the app and the server (`rex do`) both
-- need to know which session is whose, so it lives in a file. One line per
-- worktree: path, session, the session it was opened from, "adopted" if the
-- session existed before (those are forgotten on removal, never closed).
local state = os.getenv("XDG_STATE_HOME")
local REGISTRY = (state and state ~= "" and state or HOME .. "/.local/state") .. "/rex/worktrees"

local function fail(message)
	error("worktree: " .. tostring(message), 0)
end

local function normalize(path)
	path = (path or ""):gsub("^%s+", ""):gsub("%s+$", "")
	return #path > 1 and path:gsub("/+$", "") or path
end

local function load()
	local entries = {}
	local f = io.open(REGISTRY, "r")
	if not f then
		return entries
	end
	for line in f:lines() do
		local path, session, origin, kind = line:match("^([^\t]+)\t([^\t]+)\t([^\t]*)\t([^\t]*)$")
		if path then
			entries[path] = {
				session = session,
				origin = origin ~= "" and origin or nil,
				adopted = kind == "adopted" or nil,
			}
		end
	end
	f:close()
	return entries
end

local function save(entries)
	-- Unique per writer, so two actions saving at once can't mix their lines.
	local tmp = REGISTRY .. ".tmp." .. os.time() .. "." .. tostring({}):match("%x+$")
	local f = io.open(tmp, "w")
	if not f then
		rex.exec({ "mkdir", "-p", REGISTRY:match("^(.*)/") })
		f = io.open(tmp, "w") or fail("can't write " .. REGISTRY)
	end
	local paths = {}
	for path in pairs(entries) do
		paths[#paths + 1] = path
	end
	table.sort(paths)
	for _, path in ipairs(paths) do
		local e = entries[path]
		f:write(table.concat({ path, e.session, e.origin or "", e.adopted and "adopted" or "" }, "\t"), "\n")
	end
	f:close()
	local ok, err = os.rename(tmp, REGISTRY)
	if not ok then
		os.remove(tmp)
		fail(err)
	end
end

local function live_sessions()
	local list, err = rex.call("session.list")
	if not list then
		fail(err)
	end
	local ids = {}
	for _, s in ipairs(list.sessions or {}) do
		ids[s.session_id] = true
	end
	return ids
end

local function load_live()
	local entries, live, pruned = load(), live_sessions(), false
	for path, e in pairs(entries) do
		if not live[e.session] then
			entries[path] = nil
			pruned = true
		end
	end
	if pruned then
		save(entries)
	end
	return entries, live
end

-- Called through `rex do`, so ask the apps rather than queue on one; the app
-- only accepts this with Remote Control on (Settings → Rex Server).
local function show(ctx, session_id)
	local apps = rex.call("client.list", { kinds = { "app" }, session_id = ctx.session_id })
	if not apps or #(apps.clients or {}) == 0 then
		apps = rex.call("client.list", { kinds = { "app" } })
	end
	local last
	for _, client in ipairs(apps and apps.clients or {}) do
		local _, err = rex.call("client.perform", {
			client_id = client.client_id,
			action = "session.select",
			args = { session_id = session_id },
			origin = ctx.origin,
		})
		if not err then
			return
		end
		last = err
	end
	fail(last or "no Rex app is connected")
end

local function create_session(path)
	local created, err = rex.call("session.create", {
		label = M.options.label(path),
		initial_windows = { { layout = rex.layout.block({ flavor = SHELL, options = { cwd = path } }) } },
	})
	if not created then
		fail(err)
	end
	return created.session_id
end

local function owns_session(entries, session_id)
	for _, e in pairs(entries) do
		if e.session == session_id then
			return true
		end
	end
	return false
end

-- The session the picker was opened from becomes the session of the worktree
-- it was opened in (from), so picking that worktree later goes back there.
local function go(ctx, args)
	local path = normalize(args.path)
	local isdir = path:sub(1, 1) == "/" and rex.exec({ "test", "-d", path })
	if not (isdir and isdir.ok) then
		fail("not a worktree directory: " .. path)
	end
	local entries, live = load_live()
	local here = live[ctx.session_id] and ctx.session_id or nil
	local changed = false

	local from = args.from and normalize(args.from)
	if here and from and from ~= "" and not entries[from] and not owns_session(entries, here) then
		entries[from] = { session = here, adopted = true }
		changed = true
	end

	local entry = entries[path]
	if not entry then
		entry = { session = create_session(path), origin = here }
		entries[path] = entry
		changed = true
	elseif here and here ~= entry.session and not live[entry.origin] then
		entry.origin = here
		changed = true
	end
	if changed then
		save(entries)
	end
	show(ctx, entry.session)
end

local function way_back(entry, main, entries, live)
	local function usable(id)
		return id and id ~= entry.session and live[id] and id
	end
	return usable(entry.origin) or (main and entries[main] and usable(entries[main].session)) or nil
end

local function close(ctx, args)
	local path, main = normalize(args.path), args.main and normalize(args.main)
	local entries, live = load_live()
	local entry = entries[path]
	if not entry then
		return
	end
	if not entry.adopted then
		if ctx.session_id == entry.session then
			local back = way_back(entry, main, entries, live)
			if back then
				pcall(show, ctx, back)
			end
		end
		-- Calls only reach the session the connection is attached to.
		local _, err = rex.call("session.attach", { session_id = entry.session })
		if not err then
			_, err = rex.call("session.destroy", { session_id = entry.session })
		end
		if err and live_sessions()[entry.session] then
			fail(err)
		end
	end
	entries[path] = nil
	save(entries)
end

-- Commands started from Lua get a bare environment: no mise tools, and no
-- DELTA_FEATURES from Nushell's update-theme, so the diff preview would lose
-- the delta styles. Esc exits 0, so only a failure keeps the float open.
local PICKER = [[
export PATH="$HOME/.local/share/mise/shims:$PATH"
if [ -z "${DELTA_FEATURES:-}" ] && command -v defaults >/dev/null; then
	if defaults read -g AppleInterfaceStyle 2>/dev/null | grep -q Dark; then
		export DELTA_FEATURES=dark
	else
		export DELTA_FEATURES=light
	fi
fi
# The float starts at 80x24 until the app sizes it, and wt fixes the preview
# width at half of whatever it sees first.
for _ in $(seq 20); do
	[ "$(stty size)" != "24 80" ] && break
	sleep 0.05
done
wt switch --branches --no-cd -x rex -- do worktree_go "$@" ||
	{ printf '\npress any key to close'; read -rsn1; }
]]

local picker_layer

local function open(ctx)
	local cwd = M.options.dir_of(ctx.block_id) or fail("can't tell which folder this pane is in")
	local top = rex.exec({ "git", "rev-parse", "--show-toplevel" }, { cwd = cwd })
	local args = { "path={{ worktree_path }}" }
	if top and top.ok then
		args[#args + 1] = "from=" .. normalize(top.stdout)
	end

	if picker_layer then
		rex.session.close_layer({ layer_id = picker_layer })
	end
	local command = { "/bin/bash", "-c", PICKER, "worktree" }
	for _, arg in ipairs(args) do
		command[#command + 1] = arg
	end
	local layer, err = rex.session.new_layer({
		bounds = M.options.bounds,
		focus = true,
		layout = rex.layout.block({ flavor = SHELL, label = "worktree", options = { cwd = cwd, command = command } }),
	})
	if err then
		fail(err)
	end
	picker_layer = layer.layer_id
end

function M.setup(opts)
	M.options = opts
	rex.action({
		name = "worktree",
		title = "Worktree: switch / create / remove…",
		category = "Worktree",
		keywords = "git worktree branch switch create remove worktrunk wt",
		run = open,
	})
	rex.action({
		name = "worktree_go",
		title = "Open Worktree Session",
		category = "Worktree",
		args = { path = "string", from = "string?" },
		run = go,
	})
	rex.action({
		name = "worktree_close",
		title = "Close Worktree Session",
		category = "Worktree",
		args = { path = "string", main = "string?" },
		run = close,
	})
end

return M
