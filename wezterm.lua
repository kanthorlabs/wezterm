-- Ref: https://alexplescan.com/posts/2024/08/10/wezterm/

-- Import the wezterm module
local wezterm = require 'wezterm'
local appearance = require 'appearance'

-- Creates a config object which we will be adding our config to
local config = wezterm.config_builder()

-- (This is where our config will go)
-- config.default_domain = 'WSL:Ubuntu'
config.color_scheme = 'Tokyo Night'

config.enable_tab_bar = true
config.initial_rows = 35
config.initial_cols = 150

-- Slightly transparent and blurred background
config.window_background_opacity = 0.95
config.macos_window_background_blur = 30
-- Removes the title bar, leaving only the tab bar. Keeps
-- the ability to resize by dragging the window's edges.
-- On macOS, 'RESIZE|INTEGRATED_BUTTONS' also looks nice if
-- you want to keep the window controls visible and integrate
-- them into the tab bar.
config.window_decorations = 'RESIZE'
local function active_tab_number(window)
  for _, tab_info in ipairs(window:mux_window():tabs_with_info()) do
    if tab_info.is_active then
      return math.min(tab_info.index + 1, 8)
    end
  end
  return 1
end

local function segments_for_right_status(window, pane)
  local user_vars = pane:get_user_vars()
  local tab_number = active_tab_number(window)
  local segments = {
    "⌘⇧←→ move tab · ⌘" .. tab_number .. " go tab " .. tab_number
      .. " · ⌃⇧←↑↓→ go split · ⌘D split ⇆ · ⌘⇧D split ⇅ · ⌘W close",
  }
  if (user_vars.GIT_REPO or '') ~= '' then
    table.insert(segments, user_vars.GIT_REPO .. ':' .. user_vars.GIT_BRANCH)
  end
  if (user_vars.AWS_PROFILE or '') ~= '' then
    table.insert(segments, 'aws:' .. user_vars.AWS_PROFILE)
  end
  table.insert(segments, wezterm.strftime('%a %b %-d %H:%M'))
  return segments
end

wezterm.on('update-status', function(window, pane)
  local SOLID_LEFT_ARROW = utf8.char(0xe0b2)
  local segments = segments_for_right_status(window, pane)

  local color_scheme = window:effective_config().resolved_palette
  -- Note the use of wezterm.color.parse here, this returns
  -- a Color object, which comes with functionality for lightening
  -- or darkening the colour (amongst other things).
  local bg = wezterm.color.parse(color_scheme.background)
  local fg = color_scheme.foreground

  -- Each powerline segment is going to be coloured progressively
  -- darker/lighter depending on whether we're on a dark/light colour
  -- scheme. Let's establish the "from" and "to" bounds of our gradient.
  local gradient_to, gradient_from = bg
  if appearance.is_dark() then
    gradient_from = gradient_to:lighten(0.2)
  else
    gradient_from = gradient_to:darken(0.2)
  end

  -- Yes, WezTerm supports creating gradients, because why not?! Although
  -- they'd usually be used for setting high fidelity gradients on your terminal's
  -- background, we'll use them here to give us a sample of the powerline segment
  -- colours we need.
  local gradient = wezterm.color.gradient(
    {
      orientation = 'Horizontal',
      colors = { gradient_from, gradient_to },
    },
    #segments -- only gives us as many colours as we have segments.
  )

  -- We'll build up the elements to send to wezterm.format in this table.
  local elements = {}

  for i, seg in ipairs(segments) do
    local is_first = i == 1

    if is_first then
      table.insert(elements, { Background = { Color = 'none' } })
    end
    table.insert(elements, { Foreground = { Color = gradient[i] } })
    table.insert(elements, { Text = SOLID_LEFT_ARROW })

    table.insert(elements, { Foreground = { Color = fg } })
    table.insert(elements, { Background = { Color = gradient[i] } })
    table.insert(elements, { Text = ' ' .. seg .. ' ' })
  end

  window:set_right_status(wezterm.format(elements))
end)

config.set_environment_variables = {
  PATH = '/opt/homebrew/bin:' .. os.getenv('PATH')
}

config.keys = {
  {
    key = "LeftArrow",
    mods = "OPT",
    action = wezterm.action.SendString("\x1bb"),
  },
  {
    key = "RightArrow",
    mods = "OPT",
    action = wezterm.action.SendString("\x1bf"),
  },
  {
    key = "LeftArrow",
    mods = "CMD|SHIFT",
    action = wezterm.action.MoveTabRelative(-1),
  },
  {
    key = "RightArrow",
    mods = "CMD|SHIFT",
    action = wezterm.action.MoveTabRelative(1),
  },
  {
    key = "d",
    mods = "CMD",
    action = wezterm.action.SplitHorizontal { domain = "CurrentPaneDomain" },
  },
  {
    key = "d",
    mods = "CMD|SHIFT",
    action = wezterm.action.SplitVertical { domain = "CurrentPaneDomain" },
  },
  {
    key = "w",
    mods = "CMD",
    action = wezterm.action.CloseCurrentPane { confirm = true },
  },
}

-- Returns our config to be evaluated. We must always do this at the bottom of this file
return config
