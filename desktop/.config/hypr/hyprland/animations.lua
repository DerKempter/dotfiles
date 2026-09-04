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

-- Option A: Cyber Glitch / Kinetic Recoil Curves
hl.curve("cyberRecoil", { type = "bezier", points = { { 0.68, -0.4 }, { 0.27, 1.45 } } })
hl.curve("cyberSnap", { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1.15 } } })

-- Animation configs
hl.animation({ leaf = "layersIn", enabled = true, speed = 6, bezier = "cyberSnap", style = "popin 85%" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 5, bezier = "emphasizedAccel", style = "popin 85%" })
hl.animation({ leaf = "fadeLayers", enabled = true, speed = 6, bezier = "standard" })

-- popin 100% keeps window size fixed at 100% so shaders control the visual entrance & exit
hl.animation({ leaf = "windowsIn", enabled = true, speed = 8, bezier = "linear", style = "popin 100%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 8, bezier = "linear", style = "popin 100%" })

hl.animation({ leaf = "windowsMove", enabled = true, speed = 6, bezier = "cyberRecoil" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 6, bezier = "cyberSnap" })

hl.animation({
    leaf    = "specialWorkspace",
    enabled = true,
    speed   = 5,
    bezier  = "cyberSnap",
    style   = "slidefadevert 15%"
})
hl.animation({ leaf = "fade", enabled = true, speed = 6, bezier = "standard" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 8, bezier = "linear" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 8, bezier = "linear" })
hl.animation({ leaf = "fadeDim", enabled = true, speed = 6, bezier = "standard" })
hl.animation({ leaf = "border", enabled = true, speed = 6, bezier = "standard" })
