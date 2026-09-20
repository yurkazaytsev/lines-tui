# lib/clear.sh — line detection + scoring (depends on state.sh).
# After a move or spawn, call the check fns; they clear and bump SCORE.

CLEAR_COUNT=0

# check_lines_at idx -> detect 5+ in any of 4 dirs, clear them, set CLEAR_COUNT.
check_lines_at() {
  local idx=$1
  local color=${BOARD[$idx]:-0}
  CLEAR_COUNT=0
  (( color == 0 )) && return 1
  local -a mark
  local i
  for (( i = 0; i < 81; i++ )); do mark[i]=0; done
  local r=$(( idx / 9 )) c=$(( idx % 9 ))
  local dir dr dc step nr nc ni neg pos k total
  local -a run
  for dir in "0,1" "1,0" "1,1" "1,-1"; do
    dr=${dir%,*}; dc=${dir#*,}
    run=("$idx")
    # negative side
    nr=$r; nc=$c
    while true; do
      nr=$(( nr - dr )); nc=$(( nc - dc ))
      (( nr < 0 || nr > 8 || nc < 0 || nc > 8 )) && break
      ni=$(( nr * 9 + nc ))
      [[ ${BOARD[$ni]:-0} -eq $color ]] || break
      run+=("$ni")
    done
    # positive side
    nr=$r; nc=$c
    while true; do
      nr=$(( nr + dr )); nc=$(( nc + dc ))
      (( nr < 0 || nr > 8 || nc < 0 || nc > 8 )) && break
      ni=$(( nr * 9 + nc ))
      [[ ${BOARD[$ni]:-0} -eq $color ]] || break
      run+=("$ni")
    done
    if (( ${#run[@]} >= 5 )); then
      for k in "${run[@]}"; do mark[$k]=1; done
    fi
  done
  local cleared=0
  for (( i = 0; i < 81; i++ )); do
    if (( mark[i] )); then BOARD[i]=0; (( cleared++ )); fi
  done
  CLEAR_COUNT=$cleared
  if (( cleared > 0 )); then
    local gained=$cleared
    (( cleared > 5 )) && gained=$(( cleared + (cleared - 5) * 2 ))
    SCORE=$(( SCORE + gained ))
    return 0
  fi
  return 1
}

# clear_after_spawn — union-check every cell in SPAWNED_LIST (dedupes overlaps).
clear_after_spawn() {
  local -a mark
  local i
  for (( i = 0; i < 81; i++ )); do mark[i]=0; done
  local s color r c dir dr dc nr nc ni total
  local -a run
  local any=0
  for s in "${SPAWNED_LIST[@]}"; do
    color=${BOARD[$s]:-0}
    (( color == 0 )) && continue
    r=$(( s / 9 )); c=$(( s % 9 ))
    for dir in "0,1" "1,0" "1,1" "1,-1"; do
      dr=${dir%,*}; dc=${dir#*,}
      run=("$s")
      nr=$r; nc=$c
      while true; do
        nr=$(( nr - dr )); nc=$(( nc - dc ))
        (( nr < 0 || nr > 8 || nc < 0 || nc > 8 )) && break
        ni=$(( nr * 9 + nc ))
        [[ ${BOARD[$ni]:-0} -eq $color ]] || break
        run+=("$ni")
      done
      nr=$r; nc=$c
      while true; do
        nr=$(( nr + dr )); nc=$(( nc + dc ))
        (( nr < 0 || nr > 8 || nc < 0 || nc > 8 )) && break
        ni=$(( nr * 9 + nc ))
        [[ ${BOARD[$ni]:-0} -eq $color ]] || break
        run+=("$ni")
      done
      if (( ${#run[@]} >= 5 )); then
        for k2 in "${run[@]}"; do mark[$k2]=1; done
      fi
    done
  done
  CLEAR_COUNT=0
  for (( i = 0; i < 81; i++ )); do
    if (( mark[i] )); then BOARD[i]=0; (( CLEAR_COUNT++ )); fi
  done
  if (( CLEAR_COUNT > 0 )); then
    local gained=$CLEAR_COUNT
    (( CLEAR_COUNT > 5 )) && gained=$(( CLEAR_COUNT + (CLEAR_COUNT - 5) * 2 ))
    SCORE=$(( SCORE + gained ))
    return 0
  fi
  return 1
}
