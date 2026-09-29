# Acid Trip FX

The optional animated layer for the three [Acid Trip](../README.md) theme.
It is installed by running `install.sh` yourself; `omarchy theme install` never
executes anything from this directory.

## Why is this separate?

Omarchy stages only colour data from a theme installed from a git repository.
It drops every `*.lua` and every terminal config, because those files are code
(a theme's `hyprland.lua` runs inside Hyprland, a terminal config names a
program to launch). That is a deliberate safety property, and this project does
not try to bypass it. Instead the motion ships here as ordinary user files that
you install on purpose.

## Install

```bash
./install.sh            # asks for confirmation
./install.sh --dry-run  # show what it would do
./install.sh --yes      # non-interactive
```

It touches only:

- `~/.config/hypr/shaders/acid-trip.frag`
- `~/.local/bin/acid-trip-effects`
- a fenced block in `~/.config/hypr/looknfeel.lua`
- a fenced block in `~/.config/hypr/bindings.lua`
- a fenced block in `~/.config/foot/foot.ini` (only if foot is installed)

Every file is backed up first to `~/.local/state/acid-trip/fx-backup-<time>/`.
The blocks are fenced with `acid-trip-fx` markers, so re-running the installer
never duplicates them (idempotent), and the uninstaller can remove exactly
what was added.

## Uninstall

```bash
./uninstall.sh
```

Removes the fenced blocks and the two installed files. The theme and your other
configuration are untouched.

## Behaviour

- **Theme-gated.** The effects block checks the active theme (via
  `~/.local/state/omarchy/current/theme.name`) on every Hyprland config reload.
  Applying any theme other than `acid-trip` disables everything automatically;
  re-applying `acid-trip` brings it back.
- **Instant kill switch.** `SUPER + SHIFT + ALT + E` runs
  `acid-trip-effects toggle`: it clears the shader, restores damage tracking,
  stops the border-angle loop and disables blur. Press again to restore.
- **No strobing.** All motion is slow and continuous (a slow hue rotation and a
  sub-pixel UV warp), never fast flashing.

## Files

```
install.sh              opt-in installer (idempotent)
uninstall.sh            surgical remover
acid-trip.frag          full-screen shader source
acid-trip-effects       runtime toggle
config/looknfeel.fx.lua theme-gated effects block
config/bindings.fx.lua  toggle keybind
config/foot.fx.ini      foot transparency + blur
```
