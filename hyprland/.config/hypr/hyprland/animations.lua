hl.config({
    animations = {
        enabled = true,
    },
})

-- Animation curves
hl.curve("specialWorkSwitch", { type = "bezier", points = { { 0.05, 0.7 }, { 0.1, 1 } } })
hl.curve("emphasizedAccel", { type = "bezier", points = { { 0.3, 0 }, { 0.8, 0.15 } } })
hl.curve("emphasizedDecel", { type = "bezier", points = { { 0.05, 0.7 }, { 0.1, 1 } } })
hl.curve("standard", { type = "bezier", points = { { 0.2, 0 }, { 0, 1 } } })
hl.curve("bouncyDecel", { type = "bezier", points = { { 0.34, 1.56 }, { 0.64, 1 } } })
hl.curve("bouncyAccel", { type = "bezier", points = { { 0.36, 0 }, { 0.66, -0.56 } } })
hl.curve("linear", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })

-- Snappy Fluid / Spring Curves
-- fluidSpring: Fast takeoff, punchy ~8% overshoot with tight recovery
hl.curve("fluidSpring", { type = "bezier", points = { { 0.22, 1.15 }, { 0.36, 1.08 } } })
-- fluidSnap: Quick launch with a lively 5% overshoot on workspaces/layers
hl.curve("fluidSnap", { type = "bezier", points = { { 0.08, 0.9 }, { 0.18, 1.05 } } })

-- Animation configs
hl.animation({ leaf = "layersIn", enabled = true, speed = 6.5, bezier = "fluidSnap", style = "popin 85%" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 5, bezier = "emphasizedAccel", style = "popin 85%" })
hl.animation({ leaf = "fadeLayers", enabled = true, speed = 6, bezier = "standard" })

-- popin 100% keeps window size fixed at 100% so shaders control the visual entrance & exit
hl.animation({ leaf = "windowsIn", enabled = true, speed = 8, bezier = "linear", style = "popin 100%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 8, bezier = "linear", style = "popin 100%" })

hl.animation({ leaf = "windowsMove", enabled = true, speed = 6, bezier = "fluidSpring" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 5.5, bezier = "fluidSnap" })

hl.animation({
    leaf    = "specialWorkspace",
    enabled = true,
    speed   = 5.5,
    bezier  = "fluidSnap",
    style   = "slidefadevert 15%"
})
hl.animation({ leaf = "fade", enabled = true, speed = 6, bezier = "standard" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 8, bezier = "linear" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 8, bezier = "linear" })
hl.animation({ leaf = "fadeDim", enabled = true, speed = 6, bezier = "standard" })
hl.animation({ leaf = "border", enabled = true, speed = 6, bezier = "standard" })
