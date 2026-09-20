# lib/path.sh — BFS pathfinding over empty cells (depends on state.sh).
# find_path src dst -> return 0 iff a path exists through empty cells.

find_path() {
  local src=$1 dst=$2
  [[ $src -eq $dst ]] && return 1
  [[ ${BOARD[$dst]:-0} -ne 0 ]] && return 1
  local -a visited prev queue
  local i
  for (( i = 0; i < 81; i++ )); do visited[i]=0; prev[i]=-1; done
  queue=("$src")
  visited[$src]=1
  local head=0 cur r c nr nc ni
  while (( head < ${#queue[@]} )); do
    cur=${queue[$head]}; (( head++ ))
    [[ $cur -eq $dst ]] && return 0
    r=$(( cur / 9 )); c=$(( cur % 9 ))
    for dr_dc in "-1,0" "1,0" "0,-1" "0,1"; do
      nr=$(( r + ${dr_dc%,*} )); nc=$(( c + ${dr_dc#*,} ))
      (( nr < 0 || nr > 8 || nc < 0 || nc > 8 )) && continue
      ni=$(( nr * 9 + nc ))
      (( visited[ni] )) && continue
      if [[ $ni -ne $dst && ${BOARD[$ni]:-0} -ne 0 ]]; then continue; fi
      visited[ni]=1; prev[ni]=$cur
      queue+=("$ni")
    done
  done
  return 1
}
