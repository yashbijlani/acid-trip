-- Acid Trip FX -- theme-gated Hyprland effects.
-- Appended to ~/.config/hypr/looknfeel.lua by fx/install.sh, inside fenced
-- markers. Nothing here runs unless the acid-trip Omarchy theme is the active
-- theme, so applying any other theme (which reloads this file) reverts it.

local acid_home = os.getenv("HOME") or ""
local function acid_trip_active()
  local file = io.open(acid_home .. "/.local/state/omarchy/current/theme.name", "r")
  if not file then
    return false
  end
  local name = file:read("*l") or ""
  file:close()
  return name == "acid-trip"
end

if acid_trip_active() then
  local acid_shader = acid_home .. "/.config/hypr/shaders/acid-trip.frag"

  -- hot-magenta -> electric-blue -> acid-green, rotating around the window.
  local acid_active_border = {
    colors = { "rgba(ff2bd6ff)", "rgba(3a5bffee)", "rgba(39ff14ee)" },
    angle = 45,
  }
  local acid_inactive_border = "rgba(46325faa)"

  hl.config({
    general = {
      border_size = 3,
      col = {
        active_border = acid_active_border,
        inactive_border = acid_inactive_border,
      },
    },

    group = {
      col = {
        border_active = acid_active_border,
        border_inactive = acid_inactive_border,
      },
      groupbar = {
        gradients = true,
        text_color = "rgb(f1e9ff)",
        col = {
          active = "rgba(ff2bd633)",
          inactive = "rgba(3a5bff22)",
        },
      },
    },

    decoration = {
      rounding = 12,
      rounding_power = 2.2,
      active_opacity = 1.0,
      inactive_opacity = 0.93,

      glow = {
        enabled = true,
        range = 18,
        render_power = 2,
        color = "rgba(ff2bd633)",
        color_inactive = "rgba(3a5bff22)",
      },

      shadow = {
        enabled = true,
        range = 22,
        render_power = 3,
        color = "rgba(ff2bd633)",
        color_inactive = "rgba(3a5bff22)",
      },

      -- Vibrancy/contrast cranked for the frosted, glowing panels + terminal.
      blur = {
        enabled = true,
        size = 6,
        passes = 3,
        noise = 0.025,
        contrast = 1.08,
        brightness = 1.03,
        vibrancy = 0.38,
        vibrancy_darkness = 0.0,
        popups = true,
        popups_ignorealpha = 0.1,
        special = true,
        new_optimizations = true,
      },
    },
  })

  -- The shader uses the `time` uniform, which needs damage tracking off. It
  -- must be switched off BEFORE the shader is set, or Hyprland raises a parse
  -- error (red overlay) and the animation freezes.
  local acid_shader_file = io.open(acid_shader, "r")
  if acid_shader_file then
    acid_shader_file:close()
    hl.config({ debug = { damage_tracking = 0, vfr = false } })
    hl.config({ decoration = { screen_shader = acid_shader } })
  end

  -- Rubbery, not corporate-snappy.
  hl.curve("acidSpring", { type = "bezier", points = { { 0.34, 1.56 }, { 0.64, 1.0 } } })
  hl.curve("acidElastic", { type = "bezier", points = { { 0.7, -0.4 }, { 0.2, 1.3 } } })
  hl.curve("acidSmooth", { type = "bezier", points = { { 0.65, 0.05 }, { 0.36, 1.0 } } })
  hl.curve("acidLinear", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })

  hl.animation({ leaf = "global", enabled = true, speed = 10, bezier = "acidSmooth" })
  hl.animation({ leaf = "border", enabled = true, speed = 4, bezier = "acidSpring" })
  -- Slow, continuous gradient rotation (renders a frame every refresh tick).
  hl.animation({ leaf = "borderangle", enabled = true, speed = 14, bezier = "acidLinear", style = "loop" })
  hl.animation({ leaf = "windows", enabled = true, speed = 4.5, bezier = "acidSpring" })
  hl.animation({ leaf = "windowsIn", enabled = true, speed = 5, bezier = "acidSpring", style = "popin 90%" })
  hl.animation({ leaf = "windowsOut", enabled = true, speed = 4, bezier = "acidElastic", style = "popin 82%" })
  hl.animation({ leaf = "fadeIn", enabled = true, speed = 3, bezier = "acidSmooth" })
  hl.animation({ leaf = "fadeOut", enabled = true, speed = 2.5, bezier = "acidSmooth" })
  hl.animation({ leaf = "fade", enabled = true, speed = 3.5, bezier = "acidSmooth" })
  hl.animation({ leaf = "layers", enabled = true, speed = 4, bezier = "acidSpring" })
  hl.animation({ leaf = "layersIn", enabled = true, speed = 4.5, bezier = "acidSpring", style = "popin 90%" })
  hl.animation({ leaf = "layersOut", enabled = true, speed = 3, bezier = "acidElastic", style = "fade" })
  hl.animation({ leaf = "workspaces", enabled = true, speed = 5, bezier = "acidSpring", style = "slidefade" })
  hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 4, bezier = "acidSpring", style = "slidevert" })

  -- Blur the translucent Omarchy shell surfaces (bar, notifications, menus).
  hl.layer_rule({
    match = { namespace = "^(omarchy-bar|omarchy-notifications|omarchy-menu|omarchy-launcher|omarchy-polkit)$" },
    blur = true,
    blur_popups = true,
    ignore_alpha = 0.2,
  })
end
