const SYSTEM_PROMPT = "You are a shell command generator. Your ONLY job is to output a single nushell command that accomplishes the user's request. Output ONLY the raw nushell command - no markdown, no code blocks, no explanations, no comments, no backticks. Just the executable command itself on a single line. If you need to look up command syntax, you may use web search. ALWAYS prefer idiomatic native nushell best-practices over external tools (e.g. `open sqlite.db | schema`)."
const DEFAULT_MODEL = "openai/gpt-5.2"

# Generate a shell command from natural language
export def ask [
    query: string  # What you want to do in natural language
]: nothing -> string {
    let model = $env.AGENT_MODEL? | default $DEFAULT_MODEL
    let prompt = $"($SYSTEM_PROMPT) user prompt: ($query)"
    let loading_texts = [
        "here we go again…"
        "asking the command oracle…"
        "consulting the shell wizards…"
        "summoning the shell spirits…"
        "assembling terminal wizardry…"
        "negotiating with your dotfiles…"
        "translating vibes to Nushell…"
        "learning nu tricks…"
        "compiling shell chaos…"
        "forging command runes…"
        "making pipes behave…"
        "bending stdout to my will…"
    ]
    let loading_text = ($loading_texts | get (random int 0..(($loading_texts | length) - 1)))

    let worker_id = (job spawn {
        let result = (^opencode run --model $model $prompt | complete)
        $result | job send --tag (job id) 0
    })

    mut tick = 0
    let frames = ["·", "✻", "✽", "✶", "✳", "✢"]
    mut result = null
    mut spinner_shown = false
    loop {
        let msg = (try {
            job recv --tag $worker_id --timeout 250ms
        } catch {
            null
        })

        if ($msg != null) {
            $result = $msg
            break
        }

        if (not $spinner_shown) {
            print ""
            $spinner_shown = true
        }

        let frame = ($frames | get ($tick mod ($frames | length)))
        print -n $"\r($frame) ($loading_text)"
        $tick = $tick + 1
    }

    if $spinner_shown {
        print -n $"\r(ansi erase_entire_line)\r\n"
    }

    if ($result == null) {
        error make { msg: "ask failed: worker exited without result" }
    }

    if $result.exit_code != 0 {
        let stderr = ($result.stderr | str trim)
        error make {
            msg: $"ask failed with exit code ($result.exit_code): ($stderr)"
        }
    }

    $result.stdout | str trim
}
