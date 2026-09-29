-- Acid Trip FX -- one key to kill (or restore) the heavy effects: the
-- full-screen shader, the rotating borderangle, and blur.
o.bind(
  "SUPER + SHIFT + ALT + E",
  "Acid Trip: toggle heavy effects",
  (os.getenv("HOME") or "") .. "/.local/bin/acid-trip-effects toggle"
)
