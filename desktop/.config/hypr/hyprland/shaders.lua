local home = os.getenv("HOME")
local shaderDir = home .. "/.config/hypr/shaders"
local pluginPath = home .. "/.local/share/hyprland/plugins/HyprWindowShade.so"

-- Ensure HyprWindowShade plugin is loaded
hl.exec_cmd("hyprctl plugin load " .. pluginPath)

local M = {}

-- ── Global default open & close animations ──
M.default_open_animation = {
    shader   = "ionize",
    duration = 0.5,
}

M.default_close_animation = {
    shader   = "starfield",
    duration = 0.6,
}

-- ── Optional per-app open animations override ──
M.open_animations = nil

-- ── Optional per-app close animations override ──
M.close_animations = nil

-- ── Helpers: build the tag / path strings ──
function M.open_anim_tag(entry)
    local base = entry.shader:gsub("%.glsl$", ""):gsub("_open$", "")
    local tag = "+shader_open:" .. shaderDir .. "/" .. base .. "_open.glsl"
    if entry.duration then tag = tag .. "@" .. entry.duration end
    return tag
end

function M.default_open_anim_tag(entry)
    local base = entry.shader:gsub("%.glsl$", ""):gsub("_open$", "")
    local tag = "+shader_open_default:" .. shaderDir .. "/" .. base .. "_open.glsl"
    if entry.duration then tag = tag .. "@" .. entry.duration end
    return tag
end

function M.close_anim_tag(entry)
    local base = entry.shader:gsub("%.glsl$", ""):gsub("_close$", "")
    local tag = "+shader_close:" .. shaderDir .. "/" .. base .. "_close.glsl"
    if entry.duration then tag = tag .. "@" .. entry.duration end
    return tag
end

function M.default_close_anim_tag(entry)
    local base = entry.shader:gsub("%.glsl$", ""):gsub("_close$", "")
    local tag = "+shader_close_default:" .. shaderDir .. "/" .. base .. "_close.glsl"
    if entry.duration then tag = tag .. "@" .. entry.duration end
    return tag
end

-- ── Register window rules ──
if M.open_animations then
    for _, anim in ipairs(M.open_animations) do
        hl.window_rule({
            match = { class = anim.class },
            tag   = M.open_anim_tag(anim),
        })
    end
end

if M.default_open_animation then
    hl.window_rule({
        match = { class = ".*" },
        tag   = M.default_open_anim_tag(M.default_open_animation),
    })
end

if M.close_animations then
    for _, anim in ipairs(M.close_animations) do
        hl.window_rule({
            match = { class = anim.class },
            tag   = M.close_anim_tag(anim),
        })
    end
end

if M.default_close_animation then
    hl.window_rule({
        match = { class = ".*" },
        tag   = M.default_close_anim_tag(M.default_close_animation),
    })
end

return M
