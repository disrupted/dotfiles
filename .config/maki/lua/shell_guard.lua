-- Steer shell calls away from find/grep/sed: BSD vs GNU flags, not Git-aware,
-- and in Nushell they bypass structured data. Heuristic, not a parser: quoted
-- text and heredocs are dropped first so commit messages don't trip it, then
-- the first word of every command position is checked.

local M = {}

local HINTS = {
	bash = {
		find = "Use the glob tool, or `fd` (Git-aware).",
		grep = "Use the grep tool for files, or `rg` (also for filtering piped output).",
		sed = "Use the edit tools to change files, the read tool to view them, or `sd` for replacements.",
	},
	nu = {
		-- Nushell's builtin `find` is a filter and stays allowed; `^find` does not.
		find = "Use the glob tool, or `fd` (Git-aware).",
		grep = "Use the grep tool for files; filter output with `where`/`find`, or `rg`.",
		sed = "Use the edit tools to change files, the read tool to view them, `str replace`, or `sd`.",
	},
}

local function strip(cmd)
	cmd = cmd:gsub("<<%-?%s*['\"]?([%w_]+)['\"]?.-\n%1", "") -- bash heredocs
	cmd = cmd:gsub("r#+'.-'#+", "") -- nu raw strings
	cmd = cmd:gsub("\\.", "") -- escaped chars, incl. \" and \'
	cmd = cmd:gsub('"[^"]*"', '""')
	cmd = cmd:gsub("'[^']*'", "''")
	cmd = cmd:gsub("`[^`]*`", "``")
	return cmd
end

-- Returns a reason when the command should be blocked, else nil.
function M.check(tool, command)
	local hints = HINTS[tool]
	if not hints or not command then
		return nil
	end
	-- Command positions: start, newline, ; & | (covers && || and pipes),
	-- and openers of blocks/subexpressions/substitutions: { ( $( .
	local cmd = "\n" .. strip(command):gsub("[;&|{(]", "\n")
	for prefix, caret, word in cmd:gmatch("\n(%s*)(%^?)([%w_%-]+)") do
		local hint = hints[word]
		if hint and not (tool == "nu" and word == "find" and caret == "") then
			return ("`%s` is blocked here. %s"):format(word, hint)
		end
	end
	return nil
end

function M.setup(tools)
	for _, tool in ipairs(tools) do
		maki.api.set_slot("tool." .. tool .. ".input", function(prev, input, ctx)
			local reason = M.check(tool, input.command)
			if reason then
				return nil, reason
			end
			return prev(input, ctx)
		end)
	end
end

return M
