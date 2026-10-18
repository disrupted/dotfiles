export def --wrapped pi [...args] {
  let wrapper = ($nu.home-dir | path join ".config" "pi" "safehouse_pi.sh")
  ^$wrapper ...$args
}
