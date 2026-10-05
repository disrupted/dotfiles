require("full-border"):setup({
	type = ui.Border.ROUNDED,
})

-- The preset renders the hovered row's leading/trailing padding with a style
-- that drops the current-line highlight, leaving a 1-cell gap on each side.
-- Draw that padding with the row's own style instead so the highlight is flush.
if Entity and Entity.padding then
	Entity.padding = function(self)
		if not self._file.is_hovered then
			return " "
		end
		return ui.Span(th.indicator.padding.open):style(self:style())
	end
end

if Linemode and Linemode.padding then
	Linemode.padding = function(self)
		if not self._file.is_hovered then
			return " "
		end
		return ui.Span(th.indicator.padding.close):style(Entity:new(self._file):style())
	end
end

-- Keep folder icons blue; render every other icon in the default (grey) color.
if Entity and Entity.icon then
	local orig_icon = Entity.icon
	Entity.icon = function(self)
		local c = self._file.cha or self._file.stat
		if self._file.is_hovered or (c and c.is_dir) then
			return orig_icon(self)
		end
		local icon = th.icon:match(self._file, { hovered = false })
		return icon and (icon.text .. " ") or ""
	end
end

-- Ranger-style status bar -------------------------------------------------
-- Left : mode  perm  owner  group  mtime
-- Right: [selected-size sum]  position  percent
if Status and Status.children_add then
	-- This Yazi build exposes file metadata as `cha`; newer builds also have `stat`.
	local function meta(h)
		return h.cha or h.stat
	end

	-- Guard each segment so a failure can't blank the whole UI.
	local function safe(fn)
		return function(self)
			local ok, res = pcall(fn, self)
			return ok and (res or "") or ""
		end
	end

	for _, id in ipairs({ 1, 2, 3 }) do
		Status:children_remove(id, Status.LEFT)
	end
	for _, id in ipairs({ 4, 5, 6 }) do
		Status:children_remove(id, Status.RIGHT)
	end

	local function hovered(self)
		return self._current.hovered
	end

	-- Left side
	Status:children_add(
		safe(function(self)
			return hovered(self) and Status.perm(self) or ""
		end),
		2000,
		Status.LEFT
	)

	Status:children_add(
		safe(function(self)
			local h = hovered(self)
			local c = h and meta(h)
			if not c then
				return ""
			end
			return " " .. (ya.user_name and ya.user_name(c.uid) or c.uid)
		end),
		4000,
		Status.LEFT
	)

	Status:children_add(
		safe(function(self)
			local h = hovered(self)
			local c = h and meta(h)
			if not c then
				return ""
			end
			return " " .. (ya.group_name and ya.group_name(c.gid) or c.gid)
		end),
		5000,
		Status.LEFT
	)

	Status:children_add(
		safe(function(self)
			local h = hovered(self)
			local c = h and meta(h)
			local t = c and c.mtime
			if not t then
				return ""
			end
			if type(t) == "number" then
				return t == 0 and "" or (" " .. os.date("%Y-%m-%d %H:%M", math.floor(t)))
			end
			return " " .. t:format("%Y-%m-%d %H:%M")
		end),
		7000,
		Status.LEFT
	)

	-- Right side
	Status:children_add(
		safe(function(self)
			if #self._tab.selected == 0 or not self._current.window then
				return ""
			end
			local total = 0
			for _, f in ipairs(self._current.window) do
				if f:is_selected() then
					local c = meta(f)
					total = total + (c and c.len or 0)
				end
			end
			return ya.readable_size(total) .. " sum "
		end),
		1000,
		Status.RIGHT
	)

	Status:children_add(
		safe(function(self)
			local cursor, length = self._current.cursor, #self._current.files
			return string.format(" %d/%d", math.min(cursor + 1, length), length)
		end),
		2000,
		Status.RIGHT
	)
end

-- Tab bar: render in the header's top-right corner (ranger style) on the same
-- line as the path, instead of as its own row below the path.
if Tabs and Header then
	Tabs.height = function()
		return 0
	end

	Header:children_add(function()
		if #cx.tabs <= 1 then
			return ""
		end

		local style = Tabs:style()
		local spans = {}
		for i = 1, #cx.tabs do
			local name = string.format(" %d %s ", i, cx.tabs[i].name)
			spans[#spans + 1] = ui.Span(name):style(i == cx.tabs.idx and style.active or style.inactive)
		end
		return ui.Line(spans)
	end, 500, Header.RIGHT)
end
