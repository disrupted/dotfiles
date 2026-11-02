-- Vim-style normal mode for the chat input.
-- Loaded from init.lua as require("vim").setup().
-- Toggle it off with VIM = false in init.lua, then /reload.

local M = {}

local function line_start(text, pos)
	return text:sub(1, pos):match(".*()\n") or 0
end

local function line_end(text, pos)
	return (text:find("\n", pos + 1, true) or (#text + 1)) - 1
end

local function char_floor(text, pos)
	if pos <= 0 or pos >= #text then
		return pos
	end
	return utf8.offset(text, 0, pos + 1) - 1
end

local function next_char(text, pos)
	if pos >= #text then
		return pos
	end
	return pos + (utf8.offset(text, 2, pos + 1) or (#text + 1)) - (pos + 1)
end

local function prev_char(text, pos)
	if pos <= 0 then
		return 0
	end
	return utf8.offset(text, 0, pos) - 1
end

local function last_char(text, pos)
	local start = line_start(text, pos)
	local stop = line_end(text, pos)
	return stop > start and prev_char(text, stop) or start
end

local function char_at(text, pos)
	if pos >= #text then
		return ""
	end
	return text:sub(pos + 1, next_char(text, pos))
end

local function char_class(c)
	if c == "\n" then
		return "newline"
	end
	if c == " " or c == "\t" then
		return "blank"
	end
	local b = c:byte()
	if c == "_" or c:match("%w") or (b and b >= 0x80) then
		return "word"
	end
	return "punct"
end

local function word_forward(text, pos)
	local n = #text
	if pos >= n then
		return pos
	end
	local class = char_class(char_at(text, pos))
	if class == "word" or class == "punct" then
		while pos < n and char_class(char_at(text, pos)) == class do
			pos = next_char(text, pos)
		end
	end
	while pos < n and char_class(char_at(text, pos)) == "blank" do
		pos = next_char(text, pos)
	end
	if pos < n and char_at(text, pos) == "\n" then
		pos = next_char(text, pos)
		while pos < n and char_class(char_at(text, pos)) == "blank" do
			pos = next_char(text, pos)
		end
	end
	return pos
end

local function word_backward(text, pos)
	if pos <= 0 then
		return 0
	end
	local p = prev_char(text, pos)
	while p > 0 and char_class(char_at(text, p)) == "blank" do
		p = prev_char(text, p)
	end
	if char_at(text, p) == "\n" then
		if p == 0 then
			return 0
		end
		p = prev_char(text, p)
		while p > 0 and char_class(char_at(text, p)) == "blank" do
			p = prev_char(text, p)
		end
		if char_at(text, p) == "\n" then
			return next_char(text, p)
		end
	end
	local class = char_class(char_at(text, p))
	while p > 0 do
		local q = prev_char(text, p)
		if char_class(char_at(text, q)) ~= class then
			break
		end
		p = q
	end
	return p
end

local function move(ev, pos)
	local st = ev.input
	if not st then
		return
	end
	maki.ui.input_edit({
		edits = {},
		cursor = char_floor(st.text, math.max(0, math.min(pos, #st.text))),
		version = st.version,
		session_id = st.session_id,
	})
end

local function vertical(ev, down)
	local st = ev.input
	if not st then
		return
	end
	local start = line_start(st.text, st.cursor)
	local col = st.cursor - start
	local target
	if down then
		local next_start = line_end(st.text, st.cursor) + 1
		if next_start > #st.text then
			return
		end
		target = math.min(next_start + col, last_char(st.text, next_start))
	else
		if start == 0 then
			return
		end
		local prev_start = line_start(st.text, start - 1)
		target = math.min(prev_start + col, last_char(st.text, prev_start))
	end
	move(ev, target)
end

function M.setup()
	maki.keymap.set("i", "<Esc>", function(ev)
		maki.ui.set_mode("n")
		local st = ev.input
		if st and st.cursor > line_start(st.text, st.cursor) then
			move(ev, prev_char(st.text, st.cursor))
		end
	end)

	maki.keymap.set("n", "i", function()
		maki.ui.set_mode("i")
	end)

	maki.keymap.set("n", "a", function(ev)
		local st = ev.input
		maki.ui.set_mode("i")
		if st and st.cursor < line_end(st.text, st.cursor) then
			move(ev, next_char(st.text, st.cursor))
		end
	end)

	maki.keymap.set("n", "A", function(ev)
		local st = ev.input
		maki.ui.set_mode("i")
		if st then
			move(ev, line_end(st.text, st.cursor))
		end
	end)

	maki.keymap.set("n", "I", function(ev)
		local st = ev.input
		maki.ui.set_mode("i")
		if st then
			local start = line_start(st.text, st.cursor)
			local lead = st.text:sub(start + 1, line_end(st.text, st.cursor)):find("%S")
			move(ev, lead and start + lead - 1 or start)
		end
	end)

	maki.keymap.set("n", "h", function(ev)
		local st = ev.input
		if st and st.cursor > line_start(st.text, st.cursor) then
			move(ev, prev_char(st.text, st.cursor))
		end
	end)

	maki.keymap.set("n", "j", function(ev)
		vertical(ev, true)
	end)

	maki.keymap.set("n", "k", function(ev)
		vertical(ev, false)
	end)

	maki.keymap.set("n", "l", function(ev)
		local st = ev.input
		if st and st.cursor < last_char(st.text, st.cursor) then
			move(ev, next_char(st.text, st.cursor))
		end
	end)

	maki.keymap.set("n", "w", function(ev)
		local st = ev.input
		if st then
			move(ev, word_forward(st.text, st.cursor))
		end
	end)

	maki.keymap.set("n", "b", function(ev)
		local st = ev.input
		if st then
			move(ev, word_backward(st.text, st.cursor))
		end
	end)

	maki.keymap.set("n", "0", function(ev)
		local st = ev.input
		if st then
			move(ev, line_start(st.text, st.cursor))
		end
	end)

	maki.keymap.set("n", "$", function(ev)
		local st = ev.input
		if st then
			move(ev, last_char(st.text, st.cursor))
		end
	end)

	maki.keymap.set("n", "x", function(ev)
		local st = ev.input
		if not st then
			return
		end
		local start = line_start(st.text, st.cursor)
		local stop = line_end(st.text, st.cursor)
		if st.cursor >= stop then
			return
		end
		local after = next_char(st.text, st.cursor)
		local cursor = st.cursor
		if after >= stop and cursor > start then
			cursor = prev_char(st.text, st.cursor)
		end
		maki.ui.input_edit({
			start = st.cursor,
			stop = after,
			text = "",
			cursor = cursor,
			version = st.version,
			session_id = st.session_id,
		})
	end)
end

return M
