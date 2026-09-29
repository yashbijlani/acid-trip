#!/usr/bin/env bash
#
# Acid Trip FX -- optional animated layer for the Acid Trip Omarchy theme.
#
# Omarchy deliberately stages only colour data from a theme installed from a
# git repo: it drops *.lua and terminal configs because those run code. So the
# animation lives here, outside the theme, and is installed only when you run
# this script yourself. It is never executed by `omarchy theme install`.
#
# What it does (all inside your own ~/.config, nothing under /usr or
# ~/.local/share/omarchy):
#   * installs the shader source
#   * installs the acid-trip-effects toggle
#   * adds a theme-gated effects block to ~/.config/hypr/looknfeel.lua
#   * adds a toggle keybind to ~/.config/hypr/bindings.lua
#   * if foot is installed and configured, adds transparency/blur to foot.ini
# Every change is fenced and backed up; the effects are active only while the
# acid-trip theme is applied.
#
# Usage: ./install.sh [--yes] [--dry-run] [--help]
#
set -euo pipefail

FENCE="acid-trip-fx"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOME_DIR="${HOME:?HOME is not set}"

HYPR_DIR="$HOME_DIR/.config/hypr"
LOOKNFEEL="$HYPR_DIR/looknfeel.lua"
BINDINGS="$HYPR_DIR/bindings.lua"
SHADER_DIR="$HYPR_DIR/shaders"
SHADER="$SHADER_DIR/acid-trip.frag"
TOGGLE="$HOME_DIR/.local/bin/acid-trip-effects"
FOOT_INI="$HOME_DIR/.config/foot/foot.ini"
STATE_DIR="${XDG_STATE_HOME:-$HOME_DIR/.local/state}/acid-trip"
BACKUP_DIR="$STATE_DIR/fx-backup-$(date +%Y%m%d-%H%M%S)"

SRC_LOOKNFEEL="$HERE/config/looknfeel.fx.lua"
SRC_BINDINGS="$HERE/config/bindings.fx.lua"
SRC_FOOT="$HERE/config/foot.fx.ini"
SRC_SHADER="$HERE/acid-trip.frag"
SRC_TOGGLE="$HERE/acid-trip-effects"

START_LUA="-- >>> $FENCE >>>"
END_LUA="-- <<< $FENCE <<<"
START_INI="# >>> $FENCE >>>"
END_INI="# <<< $FENCE <<<"

ASSUME_YES=0
DRY_RUN=0

usage() {
  sed -n '2,25p' "$0" | sed -E 's/^# ?//'
}

for arg in "$@"; do
  case "$arg" in
    --yes|-y) ASSUME_YES=1 ;;
    --dry-run) DRY_RUN=1 ;;
    --help|-h) usage; exit 0 ;;
    *) echo "install.sh: unknown option '$arg'" >&2; exit 2 ;;
  esac
done

log() { printf '%s\n' "$*"; }
run() { if (( DRY_RUN )); then log "would: $*"; else "$@"; fi; }

for f in "$SRC_LOOKNFEEL" "$SRC_BINDINGS" "$SRC_FOOT" "$SRC_SHADER" "$SRC_TOGGLE"; do
  [[ -f $f ]] || { echo "install.sh: missing repo file: $f" >&2; exit 1; }
done

# --- preconditions (fail before changing anything) ---
if [[ ! -d $HYPR_DIR || ! -f $HYPR_DIR/hyprland.lua ]]; then
  echo "install.sh: this FX layer needs a Hyprland Lua config (Omarchy 4.x / Hyprland 0.55+)." >&2
  echo "  Looked for: $HYPR_DIR/hyprland.lua" >&2
  exit 1
fi
[[ -f $LOOKNFEEL ]] || { echo "install.sh: $LOOKNFEEL not found; refusing to guess." >&2; exit 1; }
[[ -f $BINDINGS ]] || { echo "install.sh: $BINDINGS not found; refusing to guess." >&2; exit 1; }

have_foot=0
if command -v foot >/dev/null 2>&1 && [[ -f $FOOT_INI ]]; then
  have_foot=1
fi

# --- plan ---
log "Acid Trip FX installer"
log "----------------------"
log "  shader        -> $SHADER"
log "  toggle        -> $TOGGLE  (also bound to SUPER + SHIFT + ALT + E)"
log "  fenced block  -> $LOOKNFEEL  (theme-gated effects)"
log "  fenced block  -> $BINDINGS"
if (( have_foot )); then
  log "  fenced block  -> $FOOT_INI  (foot transparency + blur)"
else
  log "  foot          -> skipped (foot not installed or not configured)"
fi
log "  backups       -> $BACKUP_DIR"
log ""
log "No packages, daemons, services or Omarchy system files are touched."
log ""

if (( ! ASSUME_YES )); then
  if [[ -t 0 ]]; then
    read -r -p "Proceed? [Y/n] " answer
    case "$answer" in [Nn]*) log "Aborted."; exit 0 ;; esac
  else
    echo "install.sh: refusing to run non-interactively without --yes" >&2
    exit 1
  fi
fi

backup() {
  local file="$1"
  [[ -f $file ]] || return 0
  run mkdir -p "$BACKUP_DIR"
  run cp -a "$file" "$BACKUP_DIR/$(basename "$file").$(date +%s)"
}

strip_fence() { # file start end
  local file="$1" start="$2" end="$3"
  [[ -f $file ]] || return 0
  if (( DRY_RUN )); then log "would: strip existing $FENCE block from $file"; return 0; fi
  awk -v s="$start" -v e="$end" '
    index($0, s) { skip = 1 }
    !skip { print }
    index($0, e) { skip = 0 }
  ' "$file" > "$file.acid-tmp.$$" && mv "$file.acid-tmp.$$" "$file"
}

apply_fence() { # file start end bodyfile
  local file="$1" start="$2" end="$3" body="$4"
  strip_fence "$file" "$start" "$end"
  if (( DRY_RUN )); then log "would: append $FENCE block to $file"; return 0; fi
  mkdir -p "$(dirname "$file")"
  {
    printf '\n%s\n' "$start"
    cat "$body"
    printf '%s\n' "$end"
  } >> "$file"
}

# --- back up, then install ---
backup "$LOOKNFEEL"
backup "$BINDINGS"
if (( have_foot )); then backup "$FOOT_INI"; fi

run mkdir -p "$SHADER_DIR" "$(dirname "$TOGGLE")"
run install -m 0644 "$SRC_SHADER" "$SHADER"
run install -m 0755 "$SRC_TOGGLE" "$TOGGLE"

apply_fence "$LOOKNFEEL" "$START_LUA" "$END_LUA" "$SRC_LOOKNFEEL"
apply_fence "$BINDINGS" "$START_LUA" "$END_LUA" "$SRC_BINDINGS"
if (( have_foot )); then apply_fence "$FOOT_INI" "$START_INI" "$END_INI" "$SRC_FOOT"; fi

if (( DRY_RUN )); then
  log ""
  log "Dry run complete; nothing was changed."
  exit 0
fi

# --- reload + verify ---
if command -v hyprctl >/dev/null 2>&1; then
  hyprctl reload >/dev/null 2>&1 || true
  sleep 1
  errors="$(hyprctl configerrors 2>/dev/null || true)"
  if [[ -n $errors ]]; then
    echo "" >&2
    echo "Hyprland reported config errors after install:" >&2
    printf '%s\n' "$errors" >&2
    echo "Revert with: $HERE/uninstall.sh" >&2
    exit 1
  fi
fi

log ""
log "Done. Effects are active only while the acid-trip theme is applied."
log "Kill/restore the heavy effects with SUPER + SHIFT + ALT + E."
log "Uninstall with: $HERE/uninstall.sh"
