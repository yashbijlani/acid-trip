# Acid Trip

A blacklight-poster / liquid-light-show theme for [Omarchy](https://omarchy.org/):
near-black violet canvas, soft lavender text, hot-magenta accent, and an
acid-green / laser-cyan / electric-yellow ANSI palette.

The theme ships as two layers:

| Layer | What it is | How to install |
|---|---|---|
| **Theme** | Palette, wallpapers, shell surfaces, static gradient border | `omarchy theme install https://github.com/yashbijlani/acid-trip` |
| **FX** | The animated psychedelic motion: full-screen shader, rotating border gradient, elastic windows, blur | run `fx/install.sh` (opt-in, see below) |

## Install the theme

```bash
omarchy theme install https://github.com/yashbijlani/acid-trip
omarchy theme set acid-trip
```

This is a normal Omarchy theme. It only contributes colour data, so it is
safe: Omarchy will not run any code from it.

## Install the animated FX layer (optional)

The moving desktop is deliberately **not** part of the theme. Omarchy drops
`*.lua` and terminal configs from a theme installed from a git repo, because
those files execute code — a sensible safety rule. So the animation is a
separate, explicit step:

```bash
~/.config/omarchy/themes/acid-trip/fx/install.sh
```

Preview it first if you like:

```bash
~/.config/omarchy/themes/acid-trip/fx/install.sh --dry-run
```

What it does:

- installs `~/.config/hypr/shaders/acid-trip.frag` and
  `~/.local/bin/acid-trip-effects`
- appends a **theme-gated** effects block to `~/.config/hypr/looknfeel.lua`
  and a toggle keybind to `~/.config/hypr/bindings.lua`
- if foot is installed and configured, appends transparency/blur to
  `~/.config/foot/foot.ini`
- backs up every file it touches (`~/.local/state/acid-trip/fx-backup-<time>/`)

It installs no packages, starts no daemons, and never edits Omarchy's system
files. The effects apply **only while the acid-trip theme is active** —
switching to any other theme turns them off cleanly.

**Kill/restore the heavy effects instantly: `SUPER + SHIFT + ALT + E`.**

## Uninstall

```bash
# remove the animated layer (keeps the theme)
~/.config/omarchy/themes/acid-trip/fx/uninstall.sh

# remove the theme too
omarchy theme remove acid-trip
```

`uninstall.sh` removes only the fenced blocks and files the installer added;
it is surgical and safe to run twice.

## Requirements for the FX layer

- Omarchy 4.x / Hyprland 0.55+ (Lua configuration). The installer refuses to
  run on the older hyprlang configuration rather than guess.
- The animated shader needs `damage_tracking` disabled and renders every
  refresh tick, so it costs GPU/battery. Use the toggle key when you need to
  save power or screen-share.

## Layout

```
colors.toml            palette (incl. the static border-gradient tokens)
backgrounds/           generated kaleidoscopic plasma wallpapers
shell.*.toml           Omarchy shell surfaces (bar, menus, notifications, lock)
tools/acid_wallpaper.py  wallpaper generator (numpy + PIL)
fx/                    optional animated layer (see fx/README.md)
```

## License

MIT. Wallpapers are generated procedurally by `tools/acid_wallpaper.py`, so
there are no third-party image rights involved.
