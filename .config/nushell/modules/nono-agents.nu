# Unsandboxed: `^pi`, `^opencode`.

export def --wrapped pi [...args] {
  ^($nu.home-dir | path join ".config" "nono" "bin" "pi.sh") ...$args
}

export def --wrapped opencode [...args] {
  ^($nu.home-dir | path join ".config" "nono" "bin" "opencode.sh") ...$args
}

export def --wrapped maki [...args] {
  ^($nu.home-dir | path join ".config" "nono" "bin" "maki.sh") ...$args
}
