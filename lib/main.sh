# lib/main.sh — game flow: apply_move, headless dump, interactive loop.

MOVE_RESULT=""
SEL_SRC=-1

apply_move() {
  local src=$1 dst=$2
  MOVE_RESULT="blocked"
  [[ ${BOARD[$src]:-0} -ne 0 ]] || return 1
  [[ ${BOARD[$dst]:-0} -eq 0 ]] || return 1
  find_path "$src" "$dst" || return 1
  local color=${BOARD[$src]}
  BOARD[$src]=0
  BOARD[$dst]=$color
  if check_lines_at "$dst"; then
    MOVE_RESULT="cleared:$CLEAR_COUNT"
  else
    spawn_next_balls
    clear_after_spawn || true
    collect_empties
    if (( EMPTY_COUNT == 0 )); then GAME_OVER=1; fi
    MOVE_RESULT="moved"
  fi
  return 0
}

dump_board() {
  printf 'score:%s\n' "$SCORE"
  printf 'next:%s %s %s\n' "${NEXT[0]}" "${NEXT[1]}" "${NEXT[2]}"
  local r c idx row
  for (( r = 0; r < 9; r++ )); do
    row=""
    for (( c = 0; c < 9; c++ )); do
      idx=$(( r * 9 + c ))
      if [[ ${BOARD[$idx]:-0} -eq 0 ]]; then row+='.'
      else row+=${BOARD[$idx]}; fi
    done
    printf '%s\n' "$row"
  done
}

# run_headless "a1:b2,c3:d4" — parse + apply, echo errors to stderr.
run_headless() {
  local csv=$1 pair sname dname
  [[ -z "$csv" ]] && return 0
  local IFS=,
  for pair in $csv; do
    pair=${pair// /}
    [[ -z "$pair" ]] && continue
    sname=${pair%%:*}; dname=${pair##*:}
    if ! parse_coord "$sname"; then printf 'bad src: %s\n' "$sname" >&2; return 1; fi
    local s=$COORD_IDX
    if ! parse_coord "$dname"; then printf 'bad dst: %s\n' "$dname" >&2; return 1; fi
    local d=$COORD_IDX
    if ! apply_move "$s" "$d"; then
      printf 'blocked: %s -> %s\n' "$sname" "$dname" >&2
      return 1
    fi
    (( GAME_OVER )) && break
  done
  return 0
}

# handle_cell idx — src/dst phase logic for a fully specified cell
# (column+row in either order). Always clears pending axis.
handle_cell() {
  local idx=$1 cname
  cname=$(name_from_idx "$idx")
  if (( SEL_SRC < 0 )); then
    # Source phase.
    if [[ ${BOARD[$idx]:-0} -eq 0 ]]; then
      MSG="$cname is empty — pick a ball"
    else
      SEL_SRC=$idx
      MSG="$cname selected — dest next (column or row)?"
    fi
  else
    # Dest phase.
    if [[ $idx -eq $SEL_SRC ]]; then
      SEL_SRC=-1; MSG="deselected — pick a ball"
    elif [[ ${BOARD[$idx]:-0} -ne 0 ]]; then
      SEL_SRC=$idx
      MSG="$cname selected — dest next (column or row)?"
    else
      local sname
      sname=$(name_from_idx "$SEL_SRC")
      if apply_move "$SEL_SRC" "$idx"; then
        case $MOVE_RESULT in
          cleared:*) MSG="$sname -> $cname: cleared ${MOVE_RESULT#cleared:} balls!";;
          *) MSG="$sname -> $cname";;
        esac
      else
        MSG="no path $sname -> $cname — pick another dest"
      fi
      SEL_SRC=-1
    fi
  fi
  PENDING_COL=-1
  PENDING_ROW=-1
}

game_interactive() {
  SEL_SRC=-1
  PENDING_COL=-1
  PENDING_ROW=-1
  CUR_R=4
  CUR_C=4
  GAME_OVER=0
  MSG="arrows move, space selects — or column a-i + row 1-9  (q=quit n=new)"
  tput civis 2>/dev/null || printf '\x1b[?25l'
  while true; do
    if (( NEED_REDRAW )); then
      NEED_REDRAW=0
      term_size
      (( CUR_R < 0 )) && CUR_R=0
      (( CUR_R > 8 )) && CUR_R=8
      (( CUR_C < 0 )) && CUR_C=0
      (( CUR_C > 8 )) && CUR_C=8
    fi
    if (( GAME_OVER )); then
      PROMPT_TEXT="game over, score $SCORE — n=new q=quit "
      MSG=""
      build_frame; draw_frame
      read_key
      case "$KEY_TYPE" in
        quit) return 0;;
        *) case "${KEY,,}" in
          n) init_board; SEL_SRC=-1; PENDING_COL=-1; PENDING_ROW=-1
             MSG="new game — arrows+space or column a-i + row 1-9";;
          q) return 0;;
        esac;;
      esac
      continue
    fi
    # Prompt reflects state: pending column/row or not, src vs dst phase.
    local pcol="" prow="" sname_p
    (( PENDING_COL >= 0 )) && pcol=${COLNAMES:$PENDING_COL:1}
    (( PENDING_ROW >= 0 )) && prow=$(( PENDING_ROW + 1 ))
    if (( SEL_SRC < 0 )); then
      if (( PENDING_COL >= 0 )); then
        PROMPT_TEXT="from: ${pcol}_ row (1-9)? "
      elif (( PENDING_ROW >= 0 )); then
        PROMPT_TEXT="from: row ${prow}, column (a-i)? "
      else
        PROMPT_TEXT="from: arrows+space or column/row? "
      fi
    else
      sname_p=$(name_from_idx "$SEL_SRC")
      if (( PENDING_COL >= 0 )); then
        PROMPT_TEXT="$sname_p to: ${pcol}_ row (1-9)? "
      elif (( PENDING_ROW >= 0 )); then
        PROMPT_TEXT="$sname_p to: row ${prow}, column (a-i)? "
      else
        PROMPT_TEXT="$sname_p to: arrows+space or column/row? "
      fi
    fi
    build_frame; draw_frame
    read_key
    case "$KEY_TYPE" in
      quit) return 0;;
      eof) return 0;;
      other) continue;;
      arrow)
        case "$KEY" in
          up) (( CUR_R > 0 )) && CUR_R=$(( CUR_R - 1 )) ;;
          down) (( CUR_R < 8 )) && CUR_R=$(( CUR_R + 1 )) ;;
          left) (( CUR_C > 0 )) && CUR_C=$(( CUR_C - 1 )) ;;
          right) (( CUR_C < 8 )) && CUR_C=$(( CUR_C + 1 )) ;;
        esac
        if (( PENDING_COL >= 0 || PENDING_ROW >= 0 )); then
          PENDING_COL=-1; PENDING_ROW=-1
          MSG="cancelled — arrows move, space selects"
        fi
        continue;;
      space|enter)
        handle_cell $(( CUR_R * 9 + CUR_C ))
        continue;;
      backspace|esc)
        if (( PENDING_COL >= 0 || PENDING_ROW >= 0 )); then
          PENDING_COL=-1; PENDING_ROW=-1; MSG="cancelled — pick column or row"
        elif (( SEL_SRC >= 0 )); then
          SEL_SRC=-1; MSG="deselected — pick a ball"
        fi
        continue;;
    esac
    # q/n single-key commands (columns are a-i so no clash).
    if [[ "$KEY_TYPE" == "letter" ]]; then
      case "$KEY" in
        q) return 0;;
        n) init_board; SEL_SRC=-1; PENDING_COL=-1; PENDING_ROW=-1
           MSG="new game — arrows+space or column a-i + row 1-9"; continue;;
      esac
    fi
    if [[ "$KEY_TYPE" == "letter" ]]; then
      if [[ $KEY =~ [a-i] ]]; then
        local cc=$(( $(printf '%d' "'$KEY") - 97 ))
        if (( PENDING_ROW >= 0 )); then
          handle_cell $(( PENDING_ROW * 9 + cc ))
        else
          PENDING_COL=$cc
          MSG="column $KEY — now row 1-9 (or Esc)"
        fi
      else
        MSG="'$KEY' is no column — use a-i (Esc cancels)"
      fi
      continue
    fi
    if [[ "$KEY_TYPE" == "digit" ]]; then
      if [[ $KEY == 0 ]]; then MSG="rows are 1-9 — no row 0"; continue; fi
      local rr=$(( KEY - 1 ))
      if (( PENDING_COL >= 0 )); then
        handle_cell $(( rr * 9 + PENDING_COL ))
      else
        PENDING_ROW=$rr
        MSG="row $KEY — now column a-i (or Esc)"
      fi
      continue
    fi
  done
}
