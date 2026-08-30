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

-- Glitch / Matrix kinetic curves
hl.curve("glitchStep", { type = "bezier", points = { { 0.85, 0 }, { 0.15, 1 } } })
hl.curve("glitchSnap", { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1.15 } } })

-- Animation configs
hl.animation({ leaf = "layersIn", enabled = true, speed = 6, bezier = "glitchSnap", style = "popin 80%" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 5, bezier = "glitchStep", style = "popin 80%" })
hl.animation({ leaf = "fadeLayers", enabled = true, speed = 6, bezier = "standard" })

hl.animation({ leaf = "windowsIn", enabled = true, speed = 8, bezier = "glitchStep", style = "popin 40%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 7, bezier = "glitchStep", style = "popin 40%" })

hl.animation({ leaf = "windowsMove", enabled = true, speed = 7, bezier = "glitchStep" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 6, bezier = "glitchStep" })

hl.animation({
    leaf    = "specialWorkspace",
    enabled = true,
    speed   = 5,
    bezier  = "glitchSnap",
    style   = "slidefadevert 15%"
})
hl.animation({ leaf = "fade", enabled = true, speed = 6, bezier = "standard" })
hl.animation({ leaf = "fadeDim", enabled = true, speed = 6, bezier = "standard" })
hl.animation({ leaf = "border", enabled = true, speed = 6, bezier = "standard" })
