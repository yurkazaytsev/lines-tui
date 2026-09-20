# lib/spawn.sh — ball spawning (depends on state.sh).

SPAWNED_LIST=()

gen_next() {
  local i
  NEXT=()
  for (( i = 0; i < 3; i++ )); do
    rand_int 7
    NEXT+=($(( RAND_VAL + 1 )))
  done
}

# Place one ball of color on a random empty cell. Sets PICK_CELL or 1 if full.
PICK_CELL=-1
pick_random_empty_cell() {
  collect_empties
  PICK_CELL=-1
  (( EMPTY_COUNT == 0 )) && return 1
  rand_int "$EMPTY_COUNT"
  PICK_CELL=${EMPTY_CELLS[$RAND_VAL]}
  return 0
}

# spawn_random n — initial drops with fully random colors.
spawn_random() {
  local n=$1 k
  for (( k = 0; k < n; k++ )); do
    pick_random_empty_cell || return 0
    rand_int 7
    BOARD[$PICK_CELL]=$(( RAND_VAL + 1 ))
  done
}

# spawn_next_balls — place NEXT colors onto random empties, then roll new NEXT.
# Fills SPAWNED_LIST with indices actually placed.
spawn_next_balls() {
  SPAWNED_LIST=()
  local k color
  for k in 0 1 2; do
    color=${NEXT[$k]}
    pick_random_empty_cell || break
    BOARD[$PICK_CELL]=$color
    SPAWNED_LIST+=("$PICK_CELL")
  done
  gen_next
}

init_board() {
  local i
  BOARD=()
  for (( i = 0; i < 81; i++ )); do BOARD+=(0); done
  SCORE=0
  GAME_OVER=0
  init_rng
  gen_next
  spawn_random 5
  gen_next
}
