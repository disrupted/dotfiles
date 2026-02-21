const SYSTEM_PROMPT = "You are a shell command generator. Your ONLY job is to output a single nushell command that accomplishes the user's request. Output ONLY the raw nushell command - no markdown, no code blocks, no explanations, no comments, no backticks. Just the executable command itself on a single line. If you need to look up command syntax, you may use web search. ALWAYS prefer idiomatic native nushell best-practices over external tools (e.g. `open sqlite.db | schema`)."
const DEFAULT_API_MODEL = "google/gemini-3-flash-preview"
const DEFAULT_OPENCODE_MODEL = "openai/gpt-5.2"
const DEFAULT_OPENCODE_URL = "http://127.0.0.1:4096"

def extract-response-text [response: record]: nothing -> string {
  let completion_text = ($response.choices.0.message.content? | default "")
  if (($completion_text | describe) == "string" and (($completion_text | str length) > 0)) {
    return $completion_text
  }

  let direct = ($response.output_text? | default "")
  if (($direct | str length) > 0) {
    return $direct
  }

  let text_chunks = (
    $response.output?
    | default []
    | each {|item|
      if (($item.type? | default "") == "message") {
        $item.content?
        | default []
        | each {|chunk| $chunk.text? | default "" }
      } else {
        []
      }
    }
    | flatten
    | where {|chunk| ($chunk | str length) > 0 }
  )

  $text_chunks | str join ""
}

def ask-openai [query: string model: string api_key: string]: nothing -> string {
  let body = {
    model: $model
    messages: [
      {role: "system" content: $SYSTEM_PROMPT}
      {role: "user" content: $query}
    ]
  }

  let response = (
    http post
    --allow-errors
    --full
    --content-type application/json
    --headers {Authorization: $"Bearer ($api_key)"}
    https://openrouter.ai/api/v1/chat/completions
    $body
  )

  let response_body = ($response.body? | default $response)
  let api_error_message = ($response_body | get -o error.message | default "")
  if (($api_error_message | str length) > 0) {
    let api_error_code = ($response_body | get -o error.code | default "unknown")
    error make --unspanned {
      msg: $"API error ($api_error_code): ($api_error_message)"
    }
  }

  let text = (extract-response-text $response_body | str trim)
  if (($text | str length) == 0) {
    error make --unspanned {msg: $"API returned empty output for model: ($model)"}
  }

  $text
}

# Generate a shell command from natural language
export def ask [
  query: string # What you want to do in natural language
]: nothing -> string {
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

  let worker_id = (
    job spawn {
      let worker_result = (
        try {
          let api_key = ($env.OPENROUTER_API_KEY? | default "")

          if (($api_key | str length) > 0) {
            let model = ($env.AGENT_API_MODEL? | default $DEFAULT_API_MODEL)
            let api_result = (ask-openai $query $model $api_key)

            {
              exit_code: 0
              stdout: $api_result
              stderr: ""
            }
          } else {
            let model = ($env.AGENT_MODEL? | default $DEFAULT_OPENCODE_MODEL)
            let attach_url = ($env.AGENT_OPENCODE_URL? | default $DEFAULT_OPENCODE_URL)

            let attached = (^opencode run --attach $attach_url --model $model $prompt | complete)
            if $attached.exit_code == 0 {
              $attached
            } else {
              ^opencode run --model $model $prompt | complete
            }
          }
        } catch {|worker_err|
          let worker_err_msg = ($worker_err.msg? | default ($worker_err | to nuon))
          {
            exit_code: 1
            stdout: ""
            stderr: $worker_err_msg
          }
        }
      )

      $worker_result | job send --tag (job id) 0
    }
  )

  mut tick = 0
  let frames = ["·" "✻" "✽" "✶" "✳" "✢"]
  mut result = null
  mut spinner_shown = false
  loop {
    let msg = (
      try {
        job recv --tag $worker_id --timeout 250ms
      } catch {
        null
      }
    )

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
    error make --unspanned {msg: "ask failed: worker exited without result"}
  }

  if $result.exit_code != 0 {
    let stderr = ($result.stderr | str trim)
    error make --unspanned {
      msg: $"ask failed with exit code ($result.exit_code): ($stderr)"
    }
  }

  $result.stdout | str trim
}
