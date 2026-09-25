local ListPicker = require("maki.list_picker")

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

local theme_env = maki.uv.os_getenv("THEME")
local theme = theme_env == "dark" and "catppuccin_mocha" or theme_env == "light" and "catppuccin_latte" or nil

maki.setup({
	always_yolo = true,
	always_thinking = true,
	ui = {
		splash_animation = false,
		theme = theme,
	},
	provider = is_work and {
		default_model = "google/gemini-3.8-flash",
		allowed_models = {
			"openai/gpt-{5.6,6}*",
			"anthropic/claude-{haiku,sonnet,opus}-5*",
			"google/gemini-{3.7,3.8}-*",
		},
		excluded_models = { "*/*-preview", "*-image", "*-tts", "*-transcribe", "*-customtools", "*-1m" },
	} or {
		default_model = "openrouter/deepseek/deepseek-v4.1-flash",
		allowed_models = { "openrouter/*" },
		excluded_models = { "*/*:batch" },
	},
})

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
