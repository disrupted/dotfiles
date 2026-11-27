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
			bash = 0, -- nu tool
			task = 5,
			grep = 0,
			read = 0,
			write = 1,
			web = 1,
			other = 1,
		},
	},
	provider = WORK and {
		default_model = "anthropic/claude-opus-5-5",
		allowed_models = {
			"openai/gpt-6*-{luna,sol}",
			"anthropic/claude-{haiku,sonnet,opus}-5-5",
			"google/gemini-4-neon",
		},
		excluded_models = {
			"openai/gpt-6-sol",
		},
	} or {
		default_model = "claude-code/claude-opus-5-5",
		allowed_models = {
			"claude-code/claude-{haiku,sonnet,opus}-5-5",
		},
	},
	agent = {
		rtk = false,
	},
	plugins = {
		bash = { enabled = false, timeout_secs = 120 },
		code_execution = { enabled = true },
		task = { max_concurrent = 4 },
		-- code_execution's os.listdir, glob, stat and mkdir only work while list is enabled
		list = { enabled = true },
		index = { enabled = false },
		edit = { edit_lines = true, insert_lines = false, multiedit = true },
		view_image = { enabled = false },
		memory = { enabled = false },
		skill = { enabled = false },
		question = { enabled = true },
		websearch = { enabled = false },
	},
})

require("nu")

-- tree-sitter highlighting for Nushell (needs the prototype/treesitter-highlight build)
do
	local site = "~/.local/share/nvim/site"
	local ok, added = pcall(maki.treesitter.language.add, "nu", { path = site .. "/parser/nu.so" })
	local query = ok and added and maki.fs.read(site .. "/queries/nu/highlights.scm")
	if query then
		maki.treesitter.query.set("nu", "highlights", query)
		maki.treesitter.language.register("nu", { "nushell" })
	end
end

maki.api.set_prompt({
	prompt = "system",
	content = [[
You are an interactive coding agent running inside maki. Use the tools available to assist the user with software engineering tasks. Get the task right first, then keep context lean: read and fetch only what you need, but verify rather than guess.

# Tool usage
- Use **batch** for independent calls. Use **task** for broad or parallel work (several tasks in one batch), not for single lookups you can do directly.
- Prefer edits over full file writes.
- Read, search and edit files with **read**, **grep**, **glob** and the edit tools, even outside cwd.
- The shell is **nu** (Nushell, not bash): git, builds, tests, file management, and querying structured data, including `rg`/`fd` output you want to shape in the same command.
- **code_execution** runs a sandboxed Python subset that calls these tools, **nu** included, as async functions. Intermediate results stay out of your context, so it fits fan-out, multi-step searches and digesting large output such as logs, docs or issues.
- For library behavior, read the installed dependency source (matches the lockfile). For docs, use **webfetch**, which asks for markdown and converts HTML. For files in a GitHub repo, use `gh api repos/<owner>/<repo>/contents/<path> -H 'Accept: application/vnd.github.raw'`.
- Use todo_write for multi-step tasks (3+ steps) and update it after each step.

# Conventions
- Match existing code style, naming conventions, and patterns.

{environment}
{{instructions}}{{after_instructions}}
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

maki.keymap.set({ "n", "i" }, "<Tab>", function() end) -- disable plan mode toggle

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

local function session_picker()
	local ok, err = maki.api.run_command("/sessions")
	if not ok then
		maki.ui.flash("sessions: " .. tostring(err))
	end
end
maki.keymap.set({ "n", "i" }, "<C-s>", session_picker, { desc = "Session picker" })
maki.keymap.set({ "n", "i" }, "<M-s>", session_picker, { desc = "Session picker" })

maki.keymap.set({ "n", "i" }, "<C-f>", function()
	maki.ui.action("file_picker")
end, { desc = "File picker" })

maki.keymap.set("n", "/", function()
	maki.ui.action("search")
end, { desc = "Search messages" })

maki.keymap.set({ "n", "i" }, "<C-b>", function()
	local _, err = maki.task.focus("main")
	if err then
		maki.ui.flash(err)
	end
end, { desc = "Back to main chat" })

require("shell_guard").setup({ "bash", "nu" })

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

-- Trial: model-callable compaction, https://github.com/tontinton/maki/pull/1660
-- Guarded because it needs a build newer than 0.7.1.
if maki.session.request_compact then
	local MAIN_TASK = "main"

	maki.api.register_tool({
		name = "compact",
		audiences = { "main", "research_sub", "general_sub" },
		description = [[Compact this session's history now. Call it at a natural boundary, for example after finishing a task, or when the context runs high. `instructions` say what the summary must keep.

Never batch this call with others: the summary swallows their results before you can read them.]],
		schema = {
			type = "object",
			properties = {
				instructions = {
					type = "string",
					description = "What the summary must keep (open questions, decisions, failing test names).",
				},
			},
		},
		handler = function(input, ctx)
			local task = ctx:task_id()
			local ok, err = maki.session.request_compact({
				session = ctx:session_id(),
				task = task ~= MAIN_TASK and task or nil,
				instructions = input.instructions,
			})
			if not ok then
				return { llm_output = "Error: " .. err, is_error = true }
			end
			return "Compaction queued. Your next request runs on the summary."
		end,
	})
end
