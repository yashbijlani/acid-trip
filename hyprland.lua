-- Acid Trip Hyprland effects, scoped to this theme.
--
-- Omarchy loads a theme's hyprland.lua as `omarchy.current.theme.hyprland`, and
-- reloads it on `hyprctl reload`. So switching to another theme drops every
-- setting below automatically: this whole look is reversible with
-- `omarchy theme set <other>`.

local home = os.getenv("HOME")
local shader = home .. "/.config/hypr/shaders/acid-trip.frag"

-- hot-magenta -> electric-blue -> acid-green, rotating around the window.
local active_border = {
  colors = { "rgba(ff2bd6ff)", "rgba(3a5bffee)", "rgba(39ff14ee)" },
  angle = 45,
}
local inactive_border = "rgba(46325faa)"

local config = {
  general = {
    border_size = 3,
    col = {
      active_border = active_border,
      inactive_border = inactive_border,
    },
  },

  group = {
    col = {
      border_active = active_border,
      border_inactive = inactive_border,
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
}

-- Only point at the shader (and pay for damage_tracking=0) when it is present.
local shader_file = io.open(shader, "r")
local shader_present = shader_file ~= nil
if shader_file then
  shader_file:close()
end

hl.config(config)

if shader_present then
  -- ORDER MATTERS: damage tracking must be off *before* the shader is set,
  -- or Hyprland raises the "uniform 'time' requires debug:damage_tracking to
  -- be switched off" parse error (red overlay) and the animation freezes.
  hl.config({
    debug = {
      damage_tracking = 0,
      vfr = false, -- otherwise Hyprland idles and the animation stutters
    },
  })
  hl.config({ decoration = { screen_shader = shader } })
end

-- Rubbery, not corporate-snappy.
hl.curve("acidSpring", { type = "bezier", points = { { 0.34, 1.56 }, { 0.64, 1.0 } } })
hl.curve("acidElastic", { type = "bezier", points = { { 0.7, -0.4 }, { 0.2, 1.3 } } })
hl.curve("acidSmooth", { type = "bezier", points = { { 0.65, 0.05 }, { 0.36, 1.0 } } })
hl.curve("acidLinear", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })

hl.animation({ leaf = "global", enabled = true, speed = 10, bezier = "acidSmooth" })
hl.animation({ leaf = "border", enabled = true, speed = 4, bezier = "acidSpring" })
-- Slow, continuous gradient rotation. This renders a frame every refresh tick,
-- so it costs battery; acid-trip-effects can turn it off instantly.
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

