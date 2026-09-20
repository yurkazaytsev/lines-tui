# lib/render.sh — terminal lifecycle + buffered rendering (depends on state.sh).

ORIG_STTY=""
TERM_ACTIVE=0
TERM_LINES=24
TERM_COLS=80
NEED_REDRAW=0
FRAME=""
MSG=""
PROMPT_TEXT=""
INPUT_BUF=""
SEL_SRC=-1
PENDING_COL=-1
PENDING_ROW=-1
CUR_R=4
CUR_C=4
ASCII_MODE=0

term_size() {
  TERM_LINES=$(tput lines 2>/dev/null || printf '24')
  TERM_COLS=$(tput cols 2>/dev/null || printf '80')
}

term_setup() {
  [[ -t 0 && -t 1 ]] || return 0
  ORIG_STTY=$(stty -g)
  if [[ -n "${LINES_ASCII:-}" ]]; then ASCII_MODE=1; fi
  # Force UTF-8 attempt; ASCII fallback via LINES_ASCII=1.
  export LC_ALL=${LC_ALL:-C.UTF-8}
  printf '\x1b[?1049h'  # alt screen
  tput civis 2>/dev/null || printf '\x1b[?25l'
  stty -echo -icanon min 1 time 0
  TERM_ACTIVE=1
  term_size
}

term_cleanup() {
  (( TERM_ACTIVE )) || return 0
  TERM_ACTIVE=0
  if [[ -n "$ORIG_STTY" ]]; then
    stty "$ORIG_STTY" 2>/dev/null || true
    ORIG_STTY=""
  fi
  tput cnorm 2>/dev/null || printf '\x1b[?25h'
  tput rmcup 2>/dev/null || printf '\x1b[?1049l'
  tput sgr0 2>/dev/null || printf '\x1b[0m'
}

ball_glyph() {
  (( ASCII_MODE )) && printf 'O' || printf '●'
}

empty_glyph() {
  (( ASCII_MODE )) && printf '.' || printf '·'
}

# fg code for color 1..7
color_code() {
  case $1 in
    1) printf '31';; 2) printf '32';; 3) printf '33';;
    4) printf '34';; 5) printf '35';; 6) printf '36';;
    *) printf '37';;
  esac
}

colored_ball() {
  # $1=color -> appends bold colored glyph to var named in $2
  # Bold is part of the assumed palette (8 colors + bold) and renders
  # noticeably thicker/larger than the dim 30-37 codes on most terminals.
  local code
  code=$(color_code "$1")
  printf -v "$2" '\x1b[1;%sm%s\x1b[0m' "$code" "$(ball_glyph)"
}

# build_frame — composes $FRAME (single-buffered full screen).
build_frame() {
  local out='' line cell idx v b e
  b=$(ball_glyph); e=$(empty_glyph)
  out+=$'\x1b[H\x1b[2J'
  # Header
  out+='LINES  score: '"$SCORE"'   next: '
  local k cb
  for k in 0 1 2; do
    colored_ball "${NEXT[$k]:-1}" cb
    out+=" $cb"
  done
  out+=$'\r\n\r\n'
  # Column header (pending column in brackets, cursor column in <>)
  out+='    '
  local c r hl rowlabel pend is_cur
  for (( c = 0; c < 9; c++ )); do
    if (( c == PENDING_COL )); then
      hl="[${COLNAMES:$c:1}]"
    elif (( c == CUR_C )); then
      hl="<${COLNAMES:$c:1}>"
    else
      hl=" ${COLNAMES:$c:1} "
    fi
    out+="$hl"
  done
  out+=$'\r\n'
  for (( r = 0; r < 9; r++ )); do
    if (( r == PENDING_ROW )); then
      rowlabel="[$(( r + 1 ))] "
    elif (( r == CUR_R )); then
      rowlabel="<$(( r + 1 ))> "
    else
      rowlabel=$(printf '%2d  ' $(( r + 1 )))
    fi
    out+="$rowlabel"
    for (( c = 0; c < 9; c++ )); do
      idx=$(( r * 9 + c ))
      v=${BOARD[$idx]:-0}
      pend=0
      (( c == PENDING_COL || r == PENDING_ROW )) && pend=1
      is_cur=0
      (( r == CUR_R && c == CUR_C )) && is_cur=1
      if (( v == 0 )); then
        if (( is_cur )); then
          if (( pend )); then
            cell="<+>"
          else
            cell="<${e}>"
          fi
        elif (( pend )); then
          cell=" + "
        else
          cell=" $e "
        fi
      else
        colored_ball "$v" cb
        if (( idx == SEL_SRC )); then
          cell="[$cb]"
        elif (( is_cur )); then
          cell="<${cb}>"
        elif (( pend )); then
          cell="($cb)"
        else
          cell=" $cb "
        fi
      fi
      out+="$cell"
    done
    out+=$'\r\n'
  done
  out+=$'\r\n'
  if (( TERM_LINES < 24 || TERM_COLS < 36 )); then
    out+='(terminal too small — enlarge to 36x24)'$'\r\n'
  fi
  if [[ -n "$MSG" ]]; then out+="$MSG"$'\r\n'; fi
  if (( GAME_OVER )); then
    out+='GAME OVER — score '"$SCORE"'  (n=new game, q=quit)'$'\r\n'
  fi
  out+="$PROMPT_TEXT"
  # erase to end of line in case of leftover chars
  out+=$'\x1b[K'
  FRAME=$out
}

draw_frame() {
  printf '%s' "$FRAME"
}
