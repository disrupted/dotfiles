const SYSTEM_PROMPT = "You are a shell command generator. Your ONLY job is to output a single nushell command that accomplishes the user's request. Output ONLY the raw nushell command - no markdown, no code blocks, no explanations, no comments, no backticks. Just the executable command itself on a single line. If you need to look up command syntax, you may use web search. ALWAYS prefer idiomatic native nushell best-practices over external tools (e.g. `open sqlite.db | schema`)."
const DEFAULT_MODEL = "openai/gpt-5.2"

# Generate a shell command from natural language
export def ask [
    query: string  # What you want to do in natural language
]: nothing -> string {
    let model = $env.AGENT_MODEL? | default $DEFAULT_MODEL
    let prompt = $"($SYSTEM_PROMPT) user prompt: ($query)"

    opencode run --model $model $prompt
}
