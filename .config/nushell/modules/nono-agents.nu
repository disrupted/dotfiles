export def --wrapped maki [...args] {
  ^($nu.home-dir | path join ".config" "nono" "bin" "maki.sh") ...$args
}
