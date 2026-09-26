export def --wrapped opencode [...args] {
  let wrapper = ($nu.home-dir | path join ".config" "opencode" "safehouse_opencode.sh")
  ^$wrapper ...$args
}
