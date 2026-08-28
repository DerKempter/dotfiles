-- Cache busting on reload so Matugen theme updates reflect immediately
package.loaded["scheme.current"] = nil
package.loaded["scheme.default"] = nil
package.loaded["variables"] = nil

local home = os.getenv("HOME")
local hypr = home .. "/.config/hypr"

-- Copy src to dst, but only if dst doesn't already exist
local function maybe_copy(src, dst)
    local out = io.open(dst)
    if out then
        out:close()
        return
    end

    local input = io.open(src, "r")
    if not input then return end

    out = io.open(dst, "w")
    if out then
        out:write(input:read("*a"))
        out:close()
    end
    input:close()
end

-- Fallback current colours to defaults if not yet generated
maybe_copy(hypr .. "/scheme/default.lua", hypr .. "/scheme/current.lua")

-- Default monitor conf
hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = 1,
})

-- Load Hyprland configuration modules
require("hyprland.env")
require("hyprland.general")
require("hyprland.input")
require("hyprland.misc")
require("hyprland.animations")
require("hyprland.decoration")
require("hyprland.group")
require("hyprland.execs")
require("hyprland.rules")
require("hyprland.gestures")
require("hyprland.keybinds")

-- HyprMod / Monitor settings
require("hyprland-gui")
