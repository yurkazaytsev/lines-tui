# Lines

> Built with [opencode](https://opencode.ai) using Muse Spark
> (`opencode/muse-spark-1.3-contributor-free`).

Classic Color Lines game as a terminal UI in bare Bash. No dependencies beyond
`bash` 5.x, `tput` (ncurses) and `stty` (coreutils).

## Run

```sh
./lines
```

The game runs from any working directory. It needs a real TTY; without one it
prints the board as text and exits (see headless mode below).

## Board

```text
LINES  score: 0   next:  ● ● ●

     a  b  c  d <e> f  g  h  i
    ┌───────────────────────────┐
 1  │ ·  ·  ·  ·  ·  ·  ·  ●  · │
 2  │ ·  ·  ·  ·  ·  ·  ·  ·  · │
 3  │ ·  ●  ·  ·  ●  ·  ·  ·  · │
 4  │ ·  ·  ·  ·  ·  ·  ·  ·  · │
<5> │ ·  ·  ·  · <·> ·  ·  ·  · │
 6  │ ·  ·  ·  ●  ·  ·  ·  ·  · │
 7  │ ●  ·  ·  ·  ·  ·  ·  ·  · │
 8  │ ·  ·  ·  ·  ·  ·  ·  ·  · │
 9  │ ·  ·  ·  ·  ·  ·  ·  ·  · │
    └───────────────────────────┘
```

`●` ball (colored in the terminal), `·` empty, `<·>` cursor, `[●]` selected.

## How to play

A 9x9 board fills with colored balls. Move balls to form lines of 5 or more
of the same color (horizontal, vertical or diagonal) to clear them and score.
The game ends when the board is full.

- Each move: pick a ball, then pick an empty destination cell.
- The ball can only move if there is a path through empty cells.
- After a move that clears nothing, 3 new balls drop onto random empty cells
  (colors shown in the `next:` preview). New drops can also complete lines.
- Scoring: 1 point per cleared ball, plus 2 bonus points for each ball beyond
  5 in a single clear.

## Controls

| Key | Action |
| --- | ------ |
| Arrow keys | Move the cursor (`<●>` / `<·>`) |
| Space or Enter | Select ball / destination |
| `a`–`i` + `1`–`9` (either order) | Select cell by coordinate |
| Esc | Cancel half-typed coordinate or deselect |
| `n` | New game |
| `q` (or Ctrl-C / Ctrl-D) | Quit |

The selected ball is shown as `[●]`. The cursor starts in the center (e5).

## Options

```sh
./lines [--seed N] [--moves src:dst,...] [--dump] [--ascii] [--help]
```

| Flag | Effect |
| ---- | ------ |
| `--seed N` | Deterministic random layout (for testing / replays) |
| `--moves a1:b2,...` | Headless: apply moves, print the board (implies `--dump`) |
| `--dump` | Print board as text, no TUI (combine with `--seed` to reproduce a game) |
| `--ascii` | Force ASCII glyphs (`O` / `.` instead of `●` / `·`) |
| `--help` | Print usage |

Examples:

```sh
./lines --seed 1 --dump
./lines --seed 1 --moves a7:b7
LINES_ASCII=1 ./lines
```

## Requirements

- Bash 5.x, `tput`, `stty` (verified with bash 5.3)
- A terminal with at least 36x24 cells, UTF-8 locale, 8 colors + bold
- No Python/Go/Rust, no dialog/whiptail/fzf, no build step, no lockfiles

## Development

Syntax check (required before committing):

```sh
bash -n lines
bash -n lib/*.sh
```

`shellcheck` / `shfmt` / `bats` are not installed here — do not require them.

Interactive behavior must be tested under a pty (`expect` is installed),
since pipes can't reproduce raw-mode / `read -t` timing:

```sh
expect -f /tmp/opencode/test_cursor.exp
```

## Layout

```text
lines            executable entrypoint (no extension)
lib/state.sh     board model, coordinates, RNG
lib/spawn.sh     ball spawning
lib/path.sh      BFS pathfinding over empty cells
lib/clear.sh     line detection and scoring
lib/render.sh    terminal lifecycle + buffered rendering
lib/input.sh     single-keypress reader (arrows, space, letters, digits)
lib/main.sh      game flow: moves, headless dump, interactive loop
```

See `AGENTS.md` for the TUI rules (alt-screen handling, raw input, rendering
and Bash pitfalls) that every change must follow.
