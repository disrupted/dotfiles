-- Nushell tool for maki, adapted from the bundled bash plugin
-- (~/dev/maki/plugins/bash/init.lua @ 3d6ab8aa). Keeps its streaming, output
-- limits, output logs, background moves and partial results on cancel. Drops
-- the bash-only parts: tree-sitter permission scopes (so this tool never
-- prompts; fine in yolo/sandbox), the rtk rewrite and `cd x &&` parsing.

local ToolView = require("maki.tool_view")
local output_limits = require("maki.output_limits")
local partial = require("maki.partial")
local nu_log = require("nu.log")

-- Local settings: maki rejects `plugins.<name>` for plugins it does not ship.
local opts = {
  timeout_secs = 120,
  background_on_timeout = true,
  background_log_bytes = 32 * 1024 * 1024,
  max_output_lines = nil,
  max_output_bytes = nil,
}

local NU_CONFIG = maki.fs.joinpath(assert(maki.env.config_dir()), "lua", "nu", "agent.nu")
local NU_ENV = {
  GIT_TERMINAL_PROMPT = "0",
  -- stdin is /dev/null, but an editor (nvim) still waits forever, e.g. for
  -- `git commit` without -m. `false` fails at once with git's own hint.
  EDITOR = "false",
  VISUAL = "false",
  GIT_EDITOR = "false",
  GIT_SEQUENCE_EDITOR = "false",
  NO_COLOR = "1",
  -- Without a TTY nu wraps tables at 80 columns.
  COLUMNS = "250",
}

local LOG_LINE_BYTES = 1024 * 1024
local TASK_LOGS_DIR = "tasks"
local LOG_EXT = ".log"
local NO_SESSION_ERR = "no chat session to keep the output log under"
local NO_STATE_DIR_ERR = "no state directory to keep the output log in"
local FINISHED_ERR = "the command already finished"
local RECEIPT_TAIL_LINES = 20
local FALLBACK_TAIL_LINES = 2000
local FALLBACK_TAIL_BYTES = 50 * 1024
local LOG_MAX_BYTES_CEILING = 1024 * 1024 * 1024
local FOREGROUND_NOTE = "Could not start in the background (%s). Ran in the foreground."
local EARLIER_IN_LOG = "[%d earlier lines are in the full output log]"
local EARLIER_ROTATED = "[%d earlier lines are in the full output log or %s; the oldest may be gone]"
local EARLIER_DROPPED = "[%d earlier lines dropped]"
local FULL_OUTPUT_PATTERN = "^(.*)\nFull output: ([^\n]+)$"
local FULL_OUTPUT_LINE = "Full output: %s"
local EXPIRE_BACKGROUND = { expire = "background" }

local fallback_log_seq = 0

local function normalize_sep(s)
  return s:gsub("\\", "/")
end

local function relative_path(p)
  local np = normalize_sep(p)
  local cwd = maki.uv.cwd()
  if cwd then
    cwd = normalize_sep(cwd)
    if np:sub(1, #cwd + 1) == cwd .. "/" then
      local rel = np:sub(#cwd + 2)
      return rel == "" and "." or rel
    end
    if np == cwd then
      return "."
    end
  end
  local home = maki.uv.os_homedir()
  if home then
    home = normalize_sep(home)
    if np:sub(1, #home + 1) == home .. "/" then
      local rel = np:sub(#home + 2)
      return rel == "" and "~" or "~/" .. rel
    end
  end
  return p
end

local function log_path(ctx, session)
  local call_id = ctx:tool_use_id()
  -- A call nested in a batch has no id of its own.
  if not call_id then
    fallback_log_seq = fallback_log_seq + 1
    call_id = ("nu-%d-%d"):format(os.time(), fallback_log_seq)
  end
  local state = maki.env.state_dir()
  if not state then
    return nil, NO_STATE_DIR_ERR
  end
  return maki.fs.joinpath(state, TASK_LOGS_DIR, session, call_id:gsub("[^%w_%-]", "_") .. LOG_EXT)
end

-- Says where the lines the tail pushed out can still be found.
local function earlier_note(log, dropped)
  if not log or log.broken or log.truncated then
    return EARLIER_DROPPED:format(dropped)
  end
  if log.rotated_path then
    return EARLIER_ROTATED:format(dropped, log.rotated_path)
  end
  return EARLIER_IN_LOG:format(dropped)
end

local function receipt(tail, path, max_bytes)
  local text, count = nu_log.tail_text(tail, RECEIPT_TAIL_LINES)
  local progress = FULL_OUTPUT_LINE:format(path)
  if count == 0 then
    return "Running in the background. No output yet.\n" .. progress
  end
  local heading = count == 1 and "Last line:" or ("Last %d lines:"):format(count)
  local shown = output_limits.cut_middle(text, RECEIPT_TAIL_LINES, max_bytes)
  return ("Running in the background. %s\n%s\n%s"):format(heading, shown, progress)
end

-- A description that is blank or just the command counts as none.
local function description_of(input)
  local description = input.description
  if not description or not description:find("%S") or description == input.command then
    return nil
  end
  return description
end

local function create_view(command, ctx)
  local tol = ctx:tool_output_lines()
  local buf = maki.ui.buf()
  local view = ToolView.new(buf, {
    max_lines = (tol and (tol.nu or tol.bash)) or 5,
    keep = "tail",
    max_line_bytes = output_limits.DEFAULT_MAX_LINE_BYTES,
  })
  view:set_header(maki.split(command, "\n"))
  maki.async.run(function()
    local highlighted = maki.ui.highlight(command, "nu")
    if highlighted then
      view:set_header(highlighted)
    end
  end)
  buf:on("click", function()
    view:toggle()
  end)
  return buf, view
end

local description = [[Execute a Nushell (nu) command, NOT bash.
Commands run in the session's working directory (see Environment) by default.

- Read, list, search, and edit files with dedicated tools. nu is for git, builds, tests, file management, and querying structured data (`open package.json | get scripts`, `ls src | where size > 10kb`, `git log -5 --format=%s | lines`).
- Nushell syntax: chain with `;` (no `&&`/`||`), `(cmd)` not `$(cmd)`, `$env.FOO = "x"`, `cmd o+e>| ...` to pipe stderr too, `^cmd` forces an external.
- Only the last pipeline's value is returned; earlier values in a `;` chain are dropped. For several results build a record: `{a: (...), b: (...)} | to nuon`.
- Flat tables print as plain columns but cut wide data; end nested or wide output with `| to nuon` for compact, exact values.
- Filter with `where`/`find`/`get`/`select`; use `fd`, `rg`, `sd` when shelling out, never `find`, `grep`, `sed`.
- Structural code search and rewrites: `ast-grep run -p 'foo($A)' -l ts` (add `-r 'bar($A)' -U` to rewrite, `--json=compact | from json` for structured output). Single quotes keep `$A` literal.
- Use `workdir` param instead of `cd`. Use batch for independent commands.
- Never use it to message the user.
- Provide a short `description` (3-5 words).
- Output sent to the model is cut beyond 2000 lines or 50KB; the reply then names a log with the full output.
- Interactive commands (sudo, ssh prompts) fail immediately.]]

maki.api.register_tool({
  name = "nu",
  kind = "execute",
  description = description,
  schema = {
    type = "object",
    properties = {
      command = { type = "string", description = "The Nushell command to execute", required = true },
      timeout = { type = "integer", description = "Timeout in seconds (default 120)" },
      workdir = { type = "string", description = "Working directory (default: cwd)" },
      description = { type = "string", description = "What the command does in 3-5 words, not the command itself" },
      background = {
        type = "boolean",
        description = "Run in the background. The result arrives as a message when it ends.",
        needs_background = true,
      },
    },
  },
  permission = "run",
  start_annotation = { field = "timeout", kind = "timeout" },

  header = function(input)
    local dir = input.workdir and relative_path(input.workdir)
    local title = description_of(input) or ""
    if dir and dir ~= "." then
      title = title == "" and "in " .. dir or title .. " in " .. dir
    end
    return title
  end,

  restore = function(input, output, is_error, ctx)
    local buf, view = create_view(input.command or "", ctx)
    local timeout_secs = output:match("^tool nu timed out after (%d+)s$")
    local text, log_file = output:match(FULL_OUTPUT_PATTERN)
    text = text or output
    if timeout_secs then
      view:append({ { "Timed out after " .. timeout_secs .. "s", "dim" } })
    elseif is_error then
      local body, code = text:match("^(.-)\nExit code: (%d+)$")
      if body then
        view:append_text(body)
        view:append({ { "Exit code: " .. code, "dim" } })
      else
        view:append_text(text)
      end
    else
      if text == "Exit code: 0" or text == "" then
        view:clear()
        view:append({ { "No output", "dim" } })
      else
        view:append_text(text)
      end
    end
    if log_file then
      view:append({ { FULL_OUTPUT_LINE:format(tostring(log_file)), "dim" } })
    end
    view:finish()
    return buf
  end,

  handler = function(input, ctx)
    if not input.command then
      return { llm_output = "error: command is required", is_error = true }
    end

    local started_at = os.time()
    local command, workdir = input.command, input.workdir
    local timeout_secs = input.timeout or opts.timeout_secs
    local max_lines, max_bytes = output_limits.resolve(opts, ctx)

    ctx:set_deadline(timeout_secs, opts.background_on_timeout and EXPIRE_BACKGROUND or nil)

    local buf, view = create_view(command, ctx)

    -- The reply comes from `collected` until the call moves to the
    -- background, and from the bounded `tail` after. The log opens once the
    -- output outgrows the reply or the call moves, and gets every line.
    local collected = output_limits.collector(max_lines, max_bytes)
    local tail, log, log_err
    local log_gate = maki.async.semaphore(1)
    local has_output = false
    local finishing, finished = false, false
    local foreground_note

    local function open_log()
      local permit = log_gate:acquire()
      if not log and not log_err then
        local session = ctx:session_id()
        local path
        if session then
          path, log_err = log_path(ctx, session)
        else
          log_err = NO_SESSION_ERR
        end
        if path then
          local opened, open_err = nu_log.open(path, math.min(opts.background_log_bytes, LOG_MAX_BYTES_CEILING))
          if opened then
            log = opened
            local lines = collected:newest()
            if #lines > 0 then
              log:push(table.concat(lines, "\n") .. "\n")
            end
          else
            log_err = "cannot open the output log: " .. open_err
          end
        end
      end
      permit:release()
      return log ~= nil, log_err
    end

    local function use_tail()
      if not collected then
        return
      end
      local newest, before = collected:newest()
      collected = nil
      tail = nu_log.new_tail(max_lines or FALLBACK_TAIL_LINES, max_bytes or FALLBACK_TAIL_BYTES, before)
      for _, line in ipairs(newest) do
        nu_log.tail_push(tail, line)
      end
    end

    local function enter_background()
      if not collected then
        return true
      end
      if finishing or finished then
        return nil, FINISHED_ERR
      end
      local opened, open_err = open_log()
      if not opened then
        return nil, open_err
      end
      if finishing or finished then
        return nil, FINISHED_ERR
      end
      use_tail()
      log:drain()
      return true
    end

    local function capture(line, bytes)
      if not has_output then
        has_output = true
        view:clear()
      end
      if collected and ctx:backgrounded() then
        local entered, enter_err = enter_background()
        if not entered then
          maki.log.warn("nu: moved without an output log: " .. enter_err)
          use_tail()
        end
      end
      if collected and not log and not log_err and not collected:fits(bytes) then
        open_log()
      end
      if collected then
        collected:append(line, bytes)
      else
        nu_log.tail_push(tail, line)
      end
      if log then
        log:push(line .. "\n")
      end
      view:append(line)
    end

    local function final_output()
      if collected then
        return collected:result()
      end
      local text = output_limits.cut_middle(nu_log.tail_text(tail), max_lines, max_bytes)
      local dropped = nu_log.tail_dropped(tail)
      if dropped == 0 then
        return text
      end
      return earlier_note(log, dropped) .. "\n" .. text
    end

    local function reply_text(llm_output)
      if log then
        local log_line = FULL_OUTPUT_LINE:format(log.path)
        view:append({ { log_line, "dim" } })
        llm_output = llm_output .. "\n" .. log_line
      end
      return foreground_note and (foreground_note .. "\n" .. llm_output) or llm_output
    end

    local function finish(exit_code)
      if finishing or finished then
        return
      end
      finishing = true
      if log then
        pcall(log.drain, log)
      end
      if finished then
        return
      end
      finished = true
      local output = final_output()
      local over_full_limit = collected ~= nil and not max_bytes and collected:truncated()

      local is_error = exit_code ~= 0 or over_full_limit
      local llm_output
      if exit_code == 0 then
        llm_output = output == "" and "Exit code: 0" or output
      else
        if output == "" then
          llm_output = "Exit code: " .. exit_code
        else
          llm_output = output .. "\nExit code: " .. exit_code
        end
      end
      if over_full_limit then
        llm_output = llm_output .. "\n" .. output_limits.FULL_LIMIT_NOTE
      end

      if output == "" then
        view:clear()
        view:append({ { "No output", "dim" } })
      end
      if exit_code ~= 0 then
        view:append({ { "Exit code: " .. exit_code, "dim" } })
      end
      if over_full_limit then
        view:append({ { output_limits.FULL_LIMIT_NOTE, "dim" } })
      end
      local reply = reply_text(llm_output)
      view:finish()

      ctx:finish({ llm_output = reply, is_error = is_error, body = buf })
    end

    view:append({ { "Waiting for output...", "dim" } })

    -- argv, not a string: a string would run through `bash -c`.
    local job, err = maki.fn.jobstart({ "nu", "--config", NU_CONFIG, "-c", command }, {
      cwd = workdir,
      env = NU_ENV,
      max_line_bytes = max_bytes and math.max(max_bytes, LOG_LINE_BYTES),
      on_stdout = function(_, line, _, bytes)
        capture(line, bytes)
      end,
      on_stderr = function(_, line, _, bytes)
        capture(line, bytes)
      end,
      on_exit = function(_, code)
        finish(code)
      end,
    })
    if not job then
      return { llm_output = "error: " .. err, is_error = true }
    end

    ctx:on_background(function()
      local entered, enter_err = enter_background()
      if not entered then
        return nil, enter_err
      end
      return receipt(tail, log.path, max_bytes)
    end)

    -- Esc or deadline: hand back the lines streamed so far.
    maki.async.on_cancel(function(reason)
      if finished then
        return
      end
      finished = true
      local cut = partial.cut(view, final_output(), reason, timeout_secs, started_at)
      cut.llm_output = reply_text(cut.llm_output)
      ctx:finish(cut)
    end)

    if input.background == true then
      local moved, move_err = ctx:background()
      if not moved then
        foreground_note = FOREGROUND_NOTE:format(tostring(move_err))
      end
    end

    return nil
  end,
})
