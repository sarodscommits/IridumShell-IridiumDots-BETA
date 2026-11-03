--Sarods2D config
local appearance_ok, appearance = pcall(dofile, os.getenv("HOME") .. "/.config/hypr/appearance.lua")
if not appearance_ok or type(appearance) ~= "table" then
    appearance = {
        border_size    = 0,
        shadow_enabled = true,
        shadow_range   = 30,
        shadow_intensity = 80,
        kitty_opacity  = 1.0,
        rounding       = 20,
        layout         = "dwindle",
        all_floating   = true,
    }
end

local appearance_rounding = appearance.rounding or 20
local appearance_layout = appearance.layout or "dwindle"
local appearance_all_floating
if appearance.all_floating == nil then
    appearance_all_floating = true
else
    appearance_all_floating = appearance.all_floating
end

local appearance_shadow_intensity = appearance.shadow_intensity or 80

local shadow_alpha = math.floor(appearance_shadow_intensity * 255 / 100)
local shadow_color = string.format("rgba(000000%02x)", shadow_alpha)


local function read_cached_border_color()
    local f = io.open(os.getenv("HOME") .. "/.cache/wal/border-color.txt", "r")
    if not f then return nil end
    local hex = f:read("*l")
    f:close()
    if hex and #hex > 0 then return hex end
    return nil
end
local cached_border_hex = read_cached_border_color()
local active_border_col   = cached_border_hex and ("rgba(" .. cached_border_hex .. "cc)") or "rgba(a6a6a6ee)"
local inactive_border_col = cached_border_hex and ("rgba(" .. cached_border_hex .. "66)") or "rgba(00000000)"

hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })

local monitors_ok, monitors = pcall(dofile, os.getenv("HOME") .. "/.config/hypr/monitors.lua")
if not monitors_ok or type(monitors) ~= "table" then monitors = {} end
for _, m in ipairs(monitors) do
    if type(m) == "table" and type(m.output) == "string" and m.output ~= "" then
        -- Only pass the fields hl.monitor() knows (unknown fields are an error)
        local spec = { output = m.output }
        if m.disabled then
            spec.disabled = true
        else
            spec.mode     = (m.mode == nil or m.mode == "auto") and "preferred" or m.mode
            spec.position = m.position or "auto"
            spec.scale    = m.scale or 1
            spec.vrr      = m.vrr or 0 -- 0 = off, 1 = on, 2 = fullscreen only
            if m.mirror and m.mirror ~= "" then spec.mirror = m.mirror end
        end
        hl.monitor(spec)
    end
end


hl.on("hyprland.start", function()
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=Hyprland")
    hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")

    hl.exec_cmd("systemctl --user stop xdg-desktop-portal xdg-desktop-portal-gtk xdg-desktop-portal-hyprland")
    hl.exec_cmd("easyeffects --gapplication-service")
    hl.exec_cmd("sleep 1 && /usr/lib/xdg-desktop-portal-hyprland &")
    hl.exec_cmd("sleep 1.5 && /usr/lib/xdg-desktop-portal-gtk -r &")
    hl.exec_cmd("sleep 2 && /usr/lib/xdg-desktop-portal -r &")

    hl.exec_cmd('env MALLOC_CONF="background_thread:true,narenas:2,dirty_decay_ms:3000,muzzy_decay_ms:0" quickshell')
    hl.exec_cmd("awww-daemon")
    hl.exec_cmd("python3 ~/.config/hypr/scripts/infinite_desktop_core.py 1.6 > $XDG_RUNTIME_DIR/infinite-desktop.log 2>&1")
    hl.exec_cmd("python3 ~/.config/hypr/scripts/auto_layout_mode.py")

    hl.exec_cmd("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")
    hl.exec_cmd("gnome-keyring-daemon --start --components=secrets")
end)

hl.layer_rule({ match = { namespace = "quickshell" }, blur = true, ignore_alpha = 0.3 })
hl.layer_rule({ match = { namespace = "quickshell:toasts" }, blur = true, ignore_alpha = 0.3 })
hl.layer_rule({ match = { namespace = "quickshell:desktop-widgets" }, blur = true, ignore_alpha = 0.3, xray = false })

hl.window_rule({
    name  = "todas-flotantes",
    match = { class = ".*" },
    float = appearance_all_floating,
})

hl.window_rule({
    name    = "kitty-transparency",
    match   = { class = "kitty" },
    opacity = tostring(appearance.kitty_opacity or 1.0),
})

hl.window_rule({
    name           = "kitty-no-maximize",
    match          = { class = "kitty" },
    suppress_event = "maximize fullscreen",
})


local keyboard_ok, keyboard = pcall(dofile, os.getenv("HOME") .. "/.config/hypr/keyboard.lua")
if not keyboard_ok or type(keyboard) ~= "table" then
    keyboard = {}
end

hl.config({
    input = {
        follow_mouse = 1,
        sensitivity  = 0,
        kb_layout    = keyboard.layout or "us",
        kb_variant   = keyboard.variant or "",
    },
})


hl.config({
    general = {
        gaps_in          = 5,
        gaps_out         = 10,
        border_size      = appearance.border_size,
        col              = {
            active_border   = active_border_col,
            inactive_border = inactive_border_col,
        },
        layout           = appearance_layout,
        resize_on_border = true,
    },

    animations = {
        enabled = true,
    },   
})

hl.curve("elasticSmoth", { type = "spring", mass = 1, stiffness = 140, dampening = 16 })

hl.animation({ leaf = "windowsMove", enabled = true, speed = 6,  spring = "elasticSmoth" })
hl.animation({ leaf = "windows",     enabled = true, speed = 6,  spring = "elasticSmoth", style = "popin 85%" })
hl.animation({ leaf = "workspaces",  enabled = true, speed = 8,  spring = "elasticSmoth", style = "slide" })


hl.config({
    decoration = {
        rounding         = appearance_rounding,
        active_opacity   = 1.0,
        inactive_opacity = 1.0,

        shadow = {
            enabled      = appearance.shadow_enabled,
            range        = appearance.shadow_range,
            render_power = 4,
            color        = shadow_color,
        },

        blur = {
            enabled           = true,
            size              = 8,
            passes            = 4,
            new_optimizations = true,
            ignore_opacity    = true,
            xray              = true,
            noise             = 0.0117,
            contrast          = 1.0,
            brightness        = 1.0,
        },
    },
})


local mainMod = "SUPER"

hl.bind("SUPER + W", hl.dsp.global("quickshell:toggleWallpaperPicker")) -- @kb:wallpaper_picker

-- Workspaces 
hl.bind("SUPER + Z", hl.dsp.focus({ workspace = "-1" })) -- @kb:ws_prev
hl.bind("SUPER + X", hl.dsp.focus({ workspace = "+1" })) -- @kb:ws_next
hl.bind("SUPER + SHIFT + Z", hl.dsp.window.move({ workspace = "-1" })) -- @kb:ws_prev_move
hl.bind("SUPER + SHIFT + X", hl.dsp.window.move({ workspace = "+1" })) -- @kb:ws_next_move
hl.bind("SUPER + S", hl.dsp.global("quickshell:toggleLayoutMode")) -- @kb:layout_toggle

hl.bind("SUPER + 1", hl.dsp.focus({ workspace = 1 })) -- @kb:ws_focus_1
hl.bind("SUPER + 2", hl.dsp.focus({ workspace = 2 })) -- @kb:ws_focus_2
hl.bind("SUPER + 3", hl.dsp.focus({ workspace = 3 })) -- @kb:ws_focus_3
hl.bind("SUPER + 4", hl.dsp.focus({ workspace = 4 })) -- @kb:ws_focus_4
hl.bind("SUPER + 5", hl.dsp.focus({ workspace = 5 })) -- @kb:ws_focus_5

hl.bind("SUPER + SHIFT + 1", hl.dsp.window.move({ workspace = 1, follow = false })) -- @kb:ws_move_1
hl.bind("SUPER + SHIFT + 2", hl.dsp.window.move({ workspace = 2, follow = false })) -- @kb:ws_move_2
hl.bind("SUPER + SHIFT + 3", hl.dsp.window.move({ workspace = 3, follow = false })) -- @kb:ws_move_3
hl.bind("SUPER + SHIFT + 4", hl.dsp.window.move({ workspace = 4, follow = false })) -- @kb:ws_move_4
hl.bind("SUPER + SHIFT + 5", hl.dsp.window.move({ workspace = 5, follow = false })) -- @kb:ws_move_5

hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })
hl.bind("SUPER + SHIFT + mouse:272", hl.dsp.window.drag(), { mouse = true })

hl.bind("SUPER + Q", hl.dsp.exec_cmd("kitty")) -- @kb:launch_terminal
hl.bind("SUPER + C", hl.dsp.window.close()) -- @kb:close_window
hl.bind("SUPER + F", hl.dsp.exec_cmd('grim -g "$(slurp)"')) -- @kb:screenshot

hl.bind("SUPER + V", hl.dsp.window.float({ action = "toggle" })) -- @kb:float_toggle
hl.bind("SUPER + D", hl.dsp.exec_cmd("python3 ~/.config/hypr/scripts/floating_tile_toggle.py")) -- @kb:float_tile_toggle

hl.bind("SUPER + left",  hl.dsp.exec_cmd("python3 ~/.config/hypr/scripts/navigate_windows.py left")) -- @kb:nav_left
hl.bind("SUPER + right", hl.dsp.exec_cmd("python3 ~/.config/hypr/scripts/navigate_windows.py right")) -- @kb:nav_right
hl.bind("SUPER + up",    hl.dsp.exec_cmd("python3 ~/.config/hypr/scripts/navigate_windows.py up")) -- @kb:nav_up
hl.bind("SUPER + down",  hl.dsp.exec_cmd("python3 ~/.config/hypr/scripts/navigate_windows.py down")) -- @kb:nav_down

hl.bind("SUPER + ALT + left",  hl.dsp.exec_cmd("python3 ~/.config/hypr/scripts/move_window_tiled.py left"), { repeating = true }) -- @kb:move_tiled_left
hl.bind("SUPER + ALT + right", hl.dsp.exec_cmd("python3 ~/.config/hypr/scripts/move_window_tiled.py right"), {repeating = true}) -- @kb:move_tiled_right
hl.bind("SUPER + ALT + up",    hl.dsp.exec_cmd("python3 ~/.config/hypr/scripts/move_window_tiled.py up"), {repeating = true}) -- @kb:move_tiled_up
hl.bind("SUPER + ALT + down",  hl.dsp.exec_cmd("python3 ~/.config/hypr/scripts/move_window_tiled.py down"), {repeating = true}) -- @kb:move_tiled_down

hl.bind("SUPER + SHIFT + left",  hl.dsp.exec_cmd("python3 ~/.config/hypr/scripts/move_window.py left"), { repeating = true }) -- @kb:move_window_left
hl.bind("SUPER + SHIFT + right", hl.dsp.exec_cmd("python3 ~/.config/hypr/scripts/move_window.py right"), { repeating = true }) -- @kb:move_window_right
hl.bind("SUPER + SHIFT + up",    hl.dsp.exec_cmd("python3 ~/.config/hypr/scripts/move_window.py up"), { repeating = true }) -- @kb:move_window_up
hl.bind("SUPER + SHIFT + down",  hl.dsp.exec_cmd("python3 ~/.config/hypr/scripts/move_window.py down"), { repeating = true }) -- @kb:move_window_down

hl.bind("SUPER + CTRL + left",  hl.dsp.exec_cmd("python3 ~/.config/hypr/scripts/resize_window.py left"), { repeating = true }) -- @kb:resize_window_left
hl.bind("SUPER + CTRL + right", hl.dsp.exec_cmd("python3 ~/.config/hypr/scripts/resize_window.py right"), { repeating = true }) -- @kb:resize_window_right
hl.bind("SUPER + CTRL + up",    hl.dsp.exec_cmd("python3 ~/.config/hypr/scripts/resize_window.py up"), { repeating = true }) -- @kb:resize_window_up
hl.bind("SUPER + CTRL + down",  hl.dsp.exec_cmd("python3 ~/.config/hypr/scripts/resize_window.py down"), { repeating = true }) -- @kb:resize_window_down

hl.bind("SUPER + SPACE", hl.dsp.global("quickshell:toggleControlCenter")) -- @kb:control_center

hl.bind("SUPER + A", hl.dsp.submap("perfiles"), { description = "Modo perfiles" })

hl.define_submap("perfiles", "reset", function()
    hl.bind("left",          hl.dsp.global("quickshell:profilePrev"))
    hl.bind("right",         hl.dsp.global("quickshell:profileNext"))
    hl.bind("SUPER + left",  hl.dsp.global("quickshell:profilePrev"))
    hl.bind("SUPER + right", hl.dsp.global("quickshell:profileNext"))
    hl.bind("escape",        hl.dsp.submap("reset"))
    hl.bind("SUPER + A",     hl.dsp.submap("reset"))
    hl.bind("catchall",      hl.dsp.submap("reset"))
end)

hl.bind("SUPER + G",   hl.dsp.global("quickshell:toggleGamingPanel"))    -- @kb:gaming_panel
hl.bind("SUPER + Tab", hl.dsp.global("quickshell:toggleWindowSwitcher")) -- @kb:window_switcher
hl.bind("SUPER + E",   hl.dsp.global("quickshell:toggleFileExplorer"))   -- @kb:file_explorer
hl.bind("SUPER + T",   hl.dsp.global("quickshell:toggleTextEditor"))     -- @kb:text_editor
hl.bind("SUPER + M",   hl.dsp.global("quickshell:toggleMusicPlayer"))    -- @kb:music_player

--hl.config({
--    render = {
--        cm_auto_hdr = 0,
--    },
--})
