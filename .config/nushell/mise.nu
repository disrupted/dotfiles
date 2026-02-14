# Custom mise Nushell integration.
#
# Why this exists:
# - We intentionally do not use the generated `mise activate nu` file directly.
# - The generated file embeds a static `set,PATH,...` snapshot at generation time.
# - On `exec nu`, that snapshot can reapply stale PATH ordering.
#
# How this differs from official setup:
# - Official: generate `mise.nu` from `mise activate nu` and source/use it as-is.
# - Custom: call `mise hook-env -s nu` dynamically at startup and on hooks.
# - Result: PATH/tool resolution stays current across reloads without regeneration.

def "parse vars" [] {
  $in | from csv --noheaders --no-infer | rename "op" "name" "value"
}

def --env "update-env" [] {
  for $var in $in {
    if $var.op == "set" {
      if ($var.name | str upcase) == "PATH" {
        $env.PATH = ($var.value | split row (char esep))
      } else {
        load-env {($var.name): $var.value}
      }
    } else if $var.op == "hide" and $var.name in $env {
      hide-env $var.name
    }
  }
}

def --env add-hook [field: cell-path new_hook: any] {
  let field = $field | split cell-path | update optional true | into cell-path
  let old_config = $env.config? | default {}
  let old_hooks = $old_config | get $field | default []
  $env.config = ($old_config | upsert $field ($old_hooks ++ [$new_hook]))
}

def --env mise_hook [] {
  ^mise hook-env -s nu | parse vars | update-env
}

export-env {
  $env.MISE_SHELL = "nu"
  mise_hook
  let hook = {
    condition: { "MISE_SHELL" in $env }
    code: { mise_hook }
  }
  add-hook hooks.pre_prompt $hook
  add-hook hooks.env_change.PWD $hook
}

export def --env --wrapped main [command?: string, --help, ...rest: string] {
  let commands = ["deactivate", "shell", "sh"]

  if ($command == null) {
    ^mise
  } else if ($command == "activate") {
    $env.MISE_SHELL = "nu"
  } else if ($command in $commands) {
    ^mise $command ...$rest | parse vars | update-env
  } else {
    ^mise $command ...$rest
  }
}
