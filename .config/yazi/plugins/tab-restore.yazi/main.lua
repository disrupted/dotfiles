--- @sync entry
--
-- Ranger-style tab restore for Yazi.
--
-- Yazi has no built-in tab_restore, so this plugin remembers the tabs you close
-- and recreates them on demand, including their name and working directory.
--
--   plugin tab-restore close    -> remember the current tab, then close it
--   plugin tab-restore restore  -> recreate the most recently closed tab

local closed = {}

local function close()
	-- Never quit implicitly: on the last tab, do nothing. Quitting is explicit.
	if #cx.tabs <= 1 then
		return
	end

	closed[#closed + 1] = {
		cwd = tostring(cx.active.current.cwd),
		name = tostring(cx.active.name),
	}
	ya.emit("close", {})
end

local function restore()
	local tab = table.remove(closed)
	if not tab then
		return
	end
	ya.emit("tab_create", { tab.cwd })
	ya.emit("tab_rename", { name = tab.name })
end

return {
	entry = function(_, job)
		local action = job.args[1]
		if action == "close" then
			close()
		elseif action == "restore" then
			restore()
		end
	end,
}
