#!/usr/bin/env bash
#
# Acid Trip FX -- uninstall the optional animated layer.
#
# Removes only what fx/install.sh added: the shader, the toggle, and the
# fenced acid-trip-fx blocks in ~/.config/hypr/looknfeel.lua,
# ~/.config/hypr/bindings.lua and (if present) ~/.config/foot/foot.ini.
# It never touches unrelated configuration, and is safe to run more than once.
#
# Usage: ./uninstall.sh [--yes] [--dry-run] [--help]
#
set -euo pipefail

FENCE="acid-trip-fx"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOME_DIR="${HOME:?HOME is not set}"

HYPR_DIR="$HOME_DIR/.config/hypr"
LOOKNFEEL="$HYPR_DIR/looknfeel.lua"
BINDINGS="$HYPR_DIR/bindings.lua"
SHADER="$HYPR_DIR/shaders/acid-trip.frag"
TOGGLE="$HOME_DIR/.local/bin/acid-trip-effects"
FOOT_INI="$HOME_DIR/.config/foot/foot.ini"
STATE_DIR="${XDG_STATE_HOME:-$HOME_DIR/.local/state}/acid-trip"
BACKUP_DIR="$STATE_DIR/fx-backup-$(date +%Y%m%d-%H%M%S)"

START_LUA="-- >>> $FENCE >>>"
END_LUA="-- <<< $FENCE <<<"
START_INI="# >>> $FENCE >>>"
END_INI="# <<< $FENCE <<<"

ASSUME_YES=0
DRY_RUN=0

usage() {
  sed -n '2,12p' "$0" | sed -E 's/^# ?//'
}

for arg in "$@"; do
  case "$arg" in
    --yes|-y) ASSUME_YES=1 ;;
    --dry-run) DRY_RUN=1 ;;
    --help|-h) usage; exit 0 ;;
    *) echo "uninstall.sh: unknown option '$arg'" >&2; exit 2 ;;
  esac
done

log() { printf '%s\n' "$*"; }
run() { if (( DRY_RUN )); then log "would: $*"; else "$@"; fi; }

backup() {
  local file="$1"
  [[ -f $file ]] || return 0
  run mkdir -p "$BACKUP_DIR"
  run cp -a "$file" "$BACKUP_DIR/$(basename "$file").$(date +%s)"
}

strip_fence() { # file start end
  local file="$1" start="$2" end="$3"
  [[ -f $file ]] || return 0
  grep -qF "$start" "$file" || return 0
  if (( DRY_RUN )); then log "would: strip $FENCE block from $file"; return 0; fi
  awk -v s="$start" -v e="$end" '
    index($0, s) { skip = 1 }
    !skip { print }
    index($0, e) { skip = 0 }
  ' "$file" > "$file.acid-tmp.$$" && mv "$file.acid-tmp.$$" "$file"
}

log "Acid Trip FX uninstaller"
log "------------------------"
log "  removes fenced $FENCE blocks from:"
log "    $LOOKNFEEL"
log "    $BINDINGS"
[[ -f $FOOT_INI ]] && log "    $FOOT_INI"
log "  removes: $SHADER"
log "  removes: $TOGGLE"
log "  backups -> $BACKUP_DIR"
log ""

if (( ! ASSUME_YES )); then
  if [[ -t 0 ]]; then
    read -r -p "Proceed? [Y/n] " answer
    case "$answer" in [Nn]*) log "Aborted."; exit 0 ;; esac
  else
    echo "uninstall.sh: refusing to run non-interactively without --yes" >&2
    exit 1
  fi
fi

backup "$LOOKNFEEL"
backup "$BINDINGS"
if [[ -f $FOOT_INI ]]; then backup "$FOOT_INI"; fi

strip_fence "$LOOKNFEEL" "$START_LUA" "$END_LUA"
strip_fence "$BINDINGS" "$START_LUA" "$END_LUA"
strip_fence "$FOOT_INI" "$START_INI" "$END_INI"

run rm -f "$SHADER" "$TOGGLE"

if (( DRY_RUN )); then
  log ""
  log "Dry run complete; nothing was changed."
  exit 0
fi

if command -v hyprctl >/dev/null 2>&1; then
  hyprctl reload >/dev/null 2>&1 || true
  sleep 1
  errors="$(hyprctl configerrors 2>/dev/null || true)"
  if [[ -n $errors ]]; then
    echo "Hyprland reported config errors after uninstall:" >&2
    printf '%s\n' "$errors" >&2
  fi
fi

log ""
log "Done. The Acid Trip theme itself is untouched (remove it with"
log "  omarchy theme remove acid-trip)."
log "Backups from this run are in: $BACKUP_DIR"
