# lib/input.sh — single-keypress reader (no Enter needed, no line editing).
# read_key sets KEY (raw char / direction / '', '' for Enter) and KEY_TYPE:
#   letter | digit | enter | space | backspace | esc | arrow | quit | other | eof
# For arrows KEY holds one of: up | down | left | right (other escape
# sequences fall back to KEY_TYPE="other").

KEY=""
KEY_TYPE=""

read_key() {
  KEY=""
  KEY_TYPE=""
  local rest
  if ! IFS= read -rsn1 KEY; then
    KEY_TYPE="eof"
    return 0
  fi
  case "$KEY" in
    ''|$'\r'|$'\n')
      KEY=""; KEY_TYPE="enter" ;;
    $'\x03'|$'\x04')
      KEY_TYPE="quit" ;;  # Ctrl-C / Ctrl-D (SIGINT trap also covers Ctrl-C)
    $'\x7f'|$'\b')
      KEY_TYPE="backspace" ;;
    $'\x1b')
      if IFS= read -rsn2 -t 0.05 rest; then
        case "$rest" in
          '[A') KEY="up"; KEY_TYPE="arrow" ;;
          '[B') KEY="down"; KEY_TYPE="arrow" ;;
          '[C') KEY="right"; KEY_TYPE="arrow" ;;
          '[D') KEY="left"; KEY_TYPE="arrow" ;;
          *) KEY=""; KEY_TYPE="other" ;;
        esac
      else
        KEY_TYPE="esc"    # lone Esc: cancel pending column / selection
      fi ;;
    ' ')
      KEY=" "; KEY_TYPE="space" ;;
    [a-zA-Z])
      KEY=${KEY,,}
      KEY_TYPE="letter" ;;
    [0-9])
      KEY_TYPE="digit" ;;
    *)
      KEY_TYPE="other" ;;
  esac
}
