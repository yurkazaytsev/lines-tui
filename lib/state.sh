# lib/state.sh — board model + coords + RNG (no TUI here).
# BOARD[81]: 0=empty, 1..7=color. Row 1 is top (idx = r*9+c).
# NEXT[3]: preview colors. SCORE, GAME_OVER, SEL discouraged here (SEL lives in main).

BOARD=()
NEXT=()
SCORE=0
GAME_OVER=0

SEED=""
LCG_STATE=0
RAND_VAL=0
COORD_IDX=-1
EMPTY_COUNT=0
EMPTY_CELLS=()
COLNAMES=abcdefghi

init_rng() {
  if [[ -n "${SEED:-}" ]]; then
    LCG_STATE=$(( SEED & 0x7fffffff ))
  fi
}

# rand_int n -> sets RAND_VAL in [0,n). Uses LCG when SEED set, else $RANDOM.
rand_int() {
  local n=$1
  if [[ -n "${SEED:-}" ]]; then
    LCG_STATE=$(( (1103515245 * LCG_STATE + 12345) & 0x7fffffff ))
    RAND_VAL=$(( LCG_STATE % n ))
  else
    RAND_VAL=$(( RANDOM % n ))
  fi
}

# parse_coord name -> sets COORD_IDX (or -1), returns 0/1.
# Accepts a1..i9 (case-insensitive), row 1 = top.
parse_coord() {
  local name=${1,,}
  COORD_IDX=-1
  [[ ${#name} -eq 2 || ${#name} -eq 3 ]] || return 1
  local col_c=${name:0:1} row_s=${name:1}
  [[ $col_c =~ [a-i] ]] || return 1
  [[ $row_s =~ ^[1-9]$ ]] || return 1
  local c=$(( $(printf '%d' "'$col_c") - 97 )) r=$(( row_s - 1 ))
  COORD_IDX=$(( r * 9 + c ))
  return 0
}

name_from_idx() {
  local idx=$1 r c
  r=$(( idx / 9 )); c=$(( idx % 9 ))
  printf '%s%d' "${COLNAMES:$c:1}" $(( r + 1 ))
}

collect_empties() {
  EMPTY_CELLS=()
  local i
  for (( i = 0; i < 81; i++ )); do
    [[ ${BOARD[i]:-0} -eq 0 ]] && EMPTY_CELLS+=("$i")
  done
  EMPTY_COUNT=${#EMPTY_CELLS[@]}
}

count_empty() {
  collect_empties
  printf '%s' "$EMPTY_COUNT"
}
