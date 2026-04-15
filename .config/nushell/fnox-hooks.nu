def --env _fnox_apply [json: string] {
  let changes = ($json | from json)
  if "set" in $changes and ($changes.set | is-not-empty) {
    $changes.set | load-env
  }
  if "unset" in $changes and ($changes.unset | is-not-empty) {
    for $var in $changes.unset {
      hide-env -i $var
    }
  }
}

def --env --wrapped fnox [...rest] {
  let command = ($rest | first | default "")
  match $command {
    "deactivate" => {
      let result = (do -i { ^fnox $command ...($rest | skip 1) } | complete)
      if $result.exit_code != 0 and ($result.stderr | str trim | is-not-empty) {
        print -e $result.stderr
      }
      if $result.exit_code == 0 and ($result.stdout | str trim | is-not-empty) {
        _fnox_apply $result.stdout
      }
      if $command == "deactivate" {
        export-env { ($env.config | upsert hooks.pre_prompt ($env.config.hooks.pre_prompt? | default [] | where { ($in | describe) != "closure" or (view source $in) !~ "_fnox_hook" })) }
        hide-env -i FNOX_SHELL
        hide-env -i __FNOX_SESSION
      }
    }
    _ => { ^fnox ...$rest }
  }
}

def --env _fnox_hook [] {
  let result = (do -i { ^fnox hook-env -s nu } | complete)
  if ($result.stderr | str trim | is-not-empty) {
    print -e $result.stderr
  }
  if $result.exit_code == 0 and ($result.stdout | str trim | is-not-empty) {
    _fnox_apply $result.stdout
  }
}

export-env {
  $env.FNOX_SHELL = "nu"
  $env.FNOX_SHELL_OUTPUT = "normal"
  ($env.config | upsert hooks.pre_prompt ($env.config.hooks.pre_prompt? | default [] | append {|| _fnox_hook }))
  _fnox_hook
}
