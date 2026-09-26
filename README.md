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

With `--shapes` each color also gets its own glyph, so the game stays
playable where colors are unavailable:

| Color                  | Shape glyph | ASCII glyph |
| ---------------------- | ----------- | ----------- |
| 1 red                  | ●           | O           |
| 2 green                | ◆           | D           |
| 3 yellow               | ▲           | ^           |
| 4 blue                 | ■           | #           |
| 5 magenta              | ★           | *           |
| 6 cyan                 | ✚           | %           |
| 7 white                | ✖           | X           |

(`D` is uppercase — the board columns stay lowercase `a`–`i`. `%` stands
in for `+` because `+` already marks the pending row/column.)

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
./lines [--seed N] [--moves src:dst,...] [--dump] [--ascii] [--shapes] [--no-color] [--help]
```

| Flag | Effect |
| ---- | ------ |
| `--seed N` | Deterministic random layout (for testing / replays) |
| `--moves a1:b2,...` | Headless: apply moves, print the board (implies `--dump`) |
| `--dump` | Print board as text, no TUI (combine with `--seed` to reproduce a game) |
| `--ascii` | Force ASCII glyphs (`O` / `.` instead of `●` / `·`) |
| `--shapes` | Distinct shape per color (see table above; env `LINES_SHAPES=1`) |
| `--no-color` | Emit no ANSI color escapes (env `LINES_NO_COLOR=1` or standard `NO_COLOR`) |
| `--help` | Print usage |

No-color terminals (`TERM=dumb`, or fewer than 8 colors per `tput colors`)
automatically get `--shapes --no-color`, so the game plays out of the box.
Combine the flags explicitly for the same effect on any terminal:

```sh
./lines --shapes --no-color
```

Examples:

```sh
./lines --seed 1 --dump
./lines --seed 1 --moves a7:b7
LINES_ASCII=1 ./lines
./lines --shapes --no-color
LINES_SHAPES=1 LINES_NO_COLOR=1 ./lines
```

## Requirements

- Bash 5.x, `tput`, `stty` (verified with bash 5.3)
- A terminal with at least 36x24 cells, UTF-8 locale; color terminals use
  8 colors + bold, no-color terminals play via `--shapes --no-color`
  (auto-enabled when colors are unavailable)
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
