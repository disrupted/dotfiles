-- vim: ft=luau

local WORK = maki.uv.os_getenv("WORK")

if not WORK then
	maki.pack.add({
		{
			src = assert(maki.uv.os_getenv("HOME")) .. "/dev/maki-claude-code",
			name = "maki-claude-code",
		},
	}, { confirm = false })
end

maki.setup({
	always_yolo = true,
	always_thinking = true,
	ui = {
		splash_animation = false,
		flash_duration_ms = 5000,
		theme = { light = "catppuccin_latte", dark = "catppuccin_macchiato" },
		thinking_lines = 0,
		tool_output_lines = {
			bash = 1,
			code_execution = 1,
			task = 5,
			index = 1,
			grep = 1,
			read = 1,
			write = 1,
			web = 1,
			other = 1,
		},
	},
	provider = WORK and {
		default_model = maki.uv.os_getenv("ANTHROPIC_API_KEY") and "anthropic/claude-sonnet-5-5" or nil,
		allowed_models = {
			"openai/gpt-6*-{luna,sol}",
			"anthropic/claude-{haiku,sonnet,opus}-5-5",
			"google/gemini-3.8-*",
		},
		excluded_models = {
			"openai/gpt-6-sol",
			"*/*-preview",
			"*-image",
			"*-tts",
			"*-transcribe",
			"*-customtools",
			"*-1m",
		},
	} or {
		default_model = "opencode-go/deepseek-v4.1-flash",
		allowed_models = { "opencode-go/*", "claude-code/*" },
		-- excluded_models = { "*/*:batch" },
	},
	agent = {
		rtk = false,
	},
	plugins = {
		bash = { timeout_secs = 10 }, -- background_on_timeout = true
		task = { max_concurrent = 4 },
		list = { enabled = false },
		edit = { edit_lines = true, insert_lines = false, multiedit = true },
		view_image = { enabled = false },
		memory = { enabled = false },
		skill = { enabled = false },
		question = { enabled = false },
		webfetch = { enabled = false },
		websearch = { enabled = false },
	},
})

maki.api.set_prompt({
	prompt = "system",
	content = [[
You are Maki, an interactive CLI coding agent. Use the tools available to assist the user with software engineering tasks. Complete tasks successfully while minimizing token usage and tool calls to avoid context bloat.

# Tool usage
- Use **batch** for parallel calls, **code_execution** for chained/filtered calls, **task** for delegation.
- Combine **batch** and **task**: launch multiple tasks in a batch to parallelize research or implementation.
- Prefer edits over full file writes.
- Search, read and edit files with dedicated tools, even outside cwd. bash is for git, builds, tests, and file management (mv, cp, rm, mkdir).
- Use the **grep** tool when searching for specific content across files.
- Use the **index** tool first on individual files to get their skeleton, then use the **read** tool with offset/limit for the specific section you need.
- When using the **read** tool, only read the sections you actually need.
- Use `wc -l` to check total number of lines before reading to decide a reasonable **read** tool limit.
- Use todo_write for multi-step tasks (3+ steps); update **after EACH step** (done + next in_progress), never batched at the end.

Most efficient tools: batch, code_execution, task, index.

# Conventions
- Match existing code style, naming conventions, and patterns.
- Be concise in your responses.
]],
})

maki.ui.input_rules({
	ns = "md",
	treesitter = {
		lang = "markdown",
		query = { markdown_inline = [[ (strong_emphasis (emphasis_delimiter) @hidden) @strong ]] },
		captures = {
			hidden = { conceal = "", reveal = "cursor" },
			strong = { hl = { bold = true } },
		},
	},
})

local VIM = true

maki.keymap.set({ "n", "i" }, "<M-i>", function()
	maki.ui.set_mode("i")
end, { desc = "Force insert mode" })

if VIM then
	-- cursor shape per mode: block in normal, bar in insert
	-- (guarded: maki builds before #1479 lack set_cursor_shape)
	if (maki.ui :: any).set_cursor_shape then
		maki.ui.set_cursor_shape("bar")
		maki.api.create_autocmd("ModeChanged", {
			callback = function(ev)
				maki.ui.set_cursor_shape(ev.data.new_mode == "n" and "block" or "bar")
			end,
		})
	end

	local ok, err = pcall(function()
		require("vim").setup()
	end)
	if not ok then
		maki.log.error("vim: " .. tostring(err))
	end
end

local ListPicker = (require :: any)("maki.list_picker")

maki.keymap.set({ "n", "i" }, "<M-p>", function()
	maki.ui.action("model_picker")
end, { desc = "Pick model" })

maki.keymap.set({ "n", "i" }, "<M-r>", function()
	local m, err = maki.model.get()
	if err then
		maki.ui.flash("thinking: " .. err)
		return
	end
	local options = m.thinking_options
	if not options or #options == 0 then
		maki.ui.flash("model does not support thinking")
		return
	end
	local items, cursor = {}, 1
	for i, opt in ipairs(options) do
		table.insert(items, {
			label = opt.name,
			detail = opt.tokens and tostring(opt.tokens),
		})
		if opt.name == m.thinking then
			cursor = i
		end
	end
	local picked = ListPicker.open(items, {
		title = "Thinking level",
		cursor = cursor,
	})
	if picked.type ~= "choice" then
		return
	end
	local _, set_err = maki.model.set({ thinking = picked.item.label })
	if set_err then
		maki.ui.flash("thinking: " .. set_err)
	end
end, { desc = "Pick thinking level" })

maki.keymap.set({ "n", "i" }, "<S-tab>", function()
	local s, err = maki.session.read()
	if err then
		maki.ui.flash("mode: " .. err)
		return
	end
	local mode = s.mode == "plan" and "build" or "plan"
	local _, set_err = maki.session.set_mode(mode)
	if set_err then
		maki.ui.flash("mode: " .. set_err)
	end
end, { desc = "Toggle plan/build mode" })

maki.keymap.set({ "n", "i" }, "<C-b>", function()
	local _, err = maki.task.focus("main")
	if err then
		maki.ui.flash(err)
	end
end, { desc = "Back to main chat" })

maki.api.set_slot("tool.bash.input", function(prev, input, ctx)
	input.command = input.command:gsub("^grep %-r ", "rg ")
	return prev(input, ctx)
end)

-- window title: "maki - <session title>"
local function update_title(session_title: string?)
	if session_title == nil then
		local s = maki.session.read()
		session_title = s and s.title
	end
	local title = "maki"
	if session_title and session_title ~= "" and session_title ~= "New session" then
		title ..= " - " .. session_title
	end
	maki.ui.set_window_title(title)
end

maki.api.create_autocmd("SessionFocusChanged", {
	callback = function()
		update_title()
	end,
})

maki.api.create_autocmd("SessionTitleChanged", {
	callback = function(ev)
		if ev.data.focused then
			update_title(ev.data.title)
		end
	end,
})
