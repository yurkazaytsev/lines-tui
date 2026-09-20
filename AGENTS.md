# AGENTS.md — TUI Lines game in bare bash

## Stack
- Bash 5.x only. Stdlib is `tput`, `stty`, ANSI escapes. No Python/Go/Rust, no dialog/whiptail/fzf, no new deps without asking.
- Entrypoint: `./lines` (executable, no extension, `chmod +x`). Lib/helpers as `lib/*.sh` sourced with `source "$(dirname "${BASH_SOURCE[0]}")/..."` so game runs from any cwd.
- Verified env: `bash 5.3`, `tput` (ncurses), `stty` (coreutils). `shellcheck`/`shfmt`/`bats` are NOT installed here — do not require them.

## Commands
- Run: `./lines`
- Syntax check: `bash -n lines` (and every `lib/*.sh`); this is the required pre-commit check.
- No build step, no lockfiles, no CI.

## Bash pitfalls (both have crashed the game before)
- `set -u` is on: `"$var_text"` parses as `${var_text}` → unbound-variable abort. Always write `"${var}_text"`.
- Never compute from a var assigned in the same `local` statement (`local idx=$1 r=$((idx/9))` silently uses the outer `idx`). Split: `local idx=$1 r c` then assign.

## TUI rules (agent will break terminal otherwise)
- Wrap everything: save state (`orig_stty=$(stty -g)`), enter alt-screen + hide cursor on start, and restore on `EXIT INT TERM` via single `trap cleanup` — restore `stty`, `tput cnorm`, `tput rmcup`, `tput sgr0`.
- Input: put terminal in raw-ish mode once (`stty -echo -icanon min 1 time 0`), read with `IFS= read -rsn1 key` + handle `\x1b[` escape sequences for arrows; never `read -p` / line-buffered `read`.
- Rendering: build frame in var, single `printf '%s'` per frame. No `clear` in loop, no `echo -e` (use `printf`), no per-cell `tput` calls in hot path.
- Resize: trap `WINCH`, re-read `lines cols` via `tput lines/cols`, re-clamp cursor and redraw; never cache size at startup only.
- Assume only 8 colors + bold; no truecolor, no mouse, no reverse video (broken on some terms — signal selection with bracket glyphs `[●]`/`(●)`/`+`, never `\x1b[7m`), no unicode beyond `●○│─┌┐└┘` with `LC_ALL=C.UTF-8` fallback to ASCII if garbled.
- Test interactively under a pty: `expect` is installed — drive `./lines` with `send`/`expect` (pipes can't reproduce raw-mode/`read -t` timing bugs).
