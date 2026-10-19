-- vim: ft=luau

local home = maki.uv.os_homedir() or ""
local cwd = maki.uv.cwd() or ""
local is_work = false
for _, dir in ipairs({ "bakdata", "spectrumk", "bayer" }) do
	local root = home .. "/" .. dir
	if cwd == root or cwd:sub(1, #root + 1) == root .. "/" then
		is_work = true
		break
	end
end

maki.setup({
	always_yolo = true,
	always_thinking = true,
	ui = {
		splash_animation = false,
		theme = "ansi",
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
	provider = is_work and {
		default_model = "anthropic/claude-sonnet-5-5",
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
		default_model = "openrouter/deepseek/deepseek-v4.1-flash",
		allowed_models = { "openrouter/*" },
		excluded_models = { "*/*:batch" },
	},
	agent = {
		rtk = false,
	},
	plugins = {
		bash = { timeout_secs = 15 },
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

local ListPicker = (require :: any)("maki.list_picker")

maki.keymap.set("n", "<M-p>", function()
	maki.ui.action("model_picker")
end, { desc = "Pick model" })

maki.keymap.set("n", "<M-r>", function()
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

maki.keymap.set("n", "<S-tab>", function()
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

maki.keymap.set("n", "<C-b>", function()
	local _, err = maki.task.focus("main")
	if err then
		maki.ui.flash(err)
	end
end, { desc = "Back to main chat" })

maki.api.set_slot("tool.bash.input", function(prev, input, ctx)
	input.command = input.command:gsub("^grep %-r ", "rg ")
	return prev(input, ctx)
end)
