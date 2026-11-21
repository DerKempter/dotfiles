local home   = os.getenv("HOME")
local scheme = require("scheme.current")
local json   = require("utils.json")

local vars = {
    ------------------
    ---- HYPRLAND ----
    ------------------

    -- Apps
    terminal                   = "ghostty",
    browser                    = "zen-browser",
    editor                     = "zed",
    fileExplorer               = "nautilus",
    audioSettings              = "pwvucontrol",

    -- Mouse & Touchpad
    mouseScrollFactor          = 0.5,
    touchpadDisableTyping      = true,
    touchpadScrollFactor       = 0.3,
    gestureFingers             = 3,
    workspaceSwipeFingers      = 4,
    gestureFingersMore         = 4,

    -- Blur
    blurEnabled                = true,
    blurSpecialWs              = false,
    blurPopups                 = true,
    blurInputMethods           = true,
    blurSize                   = 8,
    blurPasses                 = 2,
    blurXray                   = false,

    -- Shadow (Uniform all-around elevated box-shadow)
    shadowEnabled              = true,
    shadowRange                = 26,
    shadowRenderPower          = 4,
    shadowOffset               = "0 0",
    shadowScale                = 1.0,
    shadowColour               = "rgba(000000aa)",
    shadowColourInactive       = "rgba(000000aa)",

    -- Gaps
    workspaceGaps              = 20,
    windowGapsIn               = 6,
    windowGapsOut              = 10,
    singleWindowGapsOut        = 20,

    -- Window styling (Subtle accent border without heavy glow)
    windowOpacity              = 0.95,
    windowRounding             = 12,
    windowBorderSize           = 1,
    activeWindowBorderColour   = "rgba(" .. scheme.primary .. "77)",
    inactiveWindowBorderColour = "rgba(" .. (scheme.outlineVariant or scheme.onSurfaceVariant or "ffffff") .. "33)",

    -- Misc
    volumeStep                 = 2,
    volumeMax                  = 100,
    cursorTheme                = "Bibata-Modern-Ice",
    cursorSize                 = 22,
    sleepGestureCmd            = "systemctl suspend-then-hibernate",

    ------------------
    ---- KEYBINDS ----
    ------------------

    -- Modifier only, the actual binds will be mod + 0-9. These should be strings and not arrays.
    kbGoToWs                   = "SUPER",
    kbGoToWsGroup              = "CTRL + SUPER",
    kbMoveWinToWs              = "SUPER + ALT",
    kbMoveWinToWsGroup         = "CTRL + SUPER + ALT",

    -- All the following binds can be either an array of binds to bind multiple keys, or a single string.

    -- Workspaces
    kbMoveWinToWsSpecial       = "CTRL + SUPER + SHIFT + Up",
    kbMoveWinFromWsSpecial     = "CTRL + SUPER + SHIFT + Down",
    kbMoveWinToWsNext          = { "SUPER + ALT + mouse_down", "SUPER + ALT + Page_Down", "CTRL + SUPER + SHIFT + Right" },
    kbMoveWinToWsPrev          = { "SUPER + ALT + mouse_up", "SUPER + ALT + Page_Up", "CTRL + SUPER + SHIFT + Left" },
    kbNextWs                   = { "SUPER + mouse_down", "CTRL + SUPER + Right", "SUPER + Page_Down" },
    kbPrevWs                   = { "SUPER + mouse_up", "CTRL + SUPER + Left", "SUPER + Page_Up" },
    kbNextWsGroup              = "CTRL + SUPER + mouse_down",
    kbPrevWsGroup              = "CTRL + SUPER + mouse_up",

    -- Window Group
    kbWindowCycleNext          = "ALT + TAB",
    kbWindowCyclePrev          = "SHIFT + ALT + TAB",
    kbWindowGroupCycleNext     = "CTRL + ALT + TAB",
    kbWindowGroupCyclePrev     = "CTRL + SHIFT + ALT + TAB",
    kbUngroup                  = "SUPER + U",
    kbToggleGroup              = "SUPER + Comma",
    kbGroupLockActive          = "SUPER + SHIFT + Comma",

    -- Window Actions
    kbWindowDecreaseWidth      = { "SUPER + Minus", "SUPER + ALT + Left" },
    kbWindowIncreaseWidth      = { "SUPER + Equal", "SUPER + ALT + Right" },
    kbWindowDecreaseHeight     = { "SUPER + SHIFT + Minus", "SUPER + ALT + Up" },
    kbWindowIncreaseHeight     = { "SUPER + SHIFT + Equal", "SUPER + ALT + Down" },

    -- Window Movement / Layout
    kbMoveWindow               = "SUPER + Z",
    kbResizeWindow             = "SUPER + X",
    kbCenterWindow             = "CTRL + SUPER + B",
    kbNormalizeWindow          = "CTRL + SUPER + Backslash",
    kbWindowPip                = "SUPER + ALT + Backslash",
    kbPinWindow                = "SUPER + P",
    kbWindowFullscreen         = "SUPER + ALT + F",
    kbWindowBorderedFullscreen = "SUPER + F",
    kbToggleWindowFloating     = "SUPER + ALT + Space",
    kbCloseWindow              = "SUPER + Q",

    -- Special Workspaces
    kbSpecialWs                = "SUPER + S",
    kbSystemMonitorWs          = "CTRL + SHIFT + Escape",
    kbMusicWs                  = "SUPER + M",
    kbCommunicationWs          = "SUPER + D",
    kbTodoWs                   = "SUPER + R",

    -- Apps
    kbTerminal                 = "SUPER + Return",
    kbBrowser                  = "SUPER + W",
    kbEditor                   = "SUPER + C",
    kbFileExplorer             = "SUPER + E",
    kbAudioSettings            = "CTRL + SUPER + V",

    -- Utilities & Screenshots
    kbScreenshot               = "Print",
    kbScreenshotFreeze         = "SUPER + SHIFT + S",
    kbScreenshotRegion         = "CTRL + SHIFT + S",
    kbScreenshotOCR            = "SUPER + SHIFT + T",
    kbWallpaperRandom          = "CTRL + SUPER + R",
    kbWallpaperPicker          = "CTRL + SUPER + W",
    kbWallpaperSelect          = "CTRL + SUPER + SHIFT + W",
    kbColorPicker              = "SUPER + SHIFT + C",

    -- Media & Volume
    kbMediaToggle              = "CTRL + SUPER + Space",
    kbMediaNext                = "CTRL + SUPER + Equal",
    kbMediaPrev                = "CTRL + SUPER + Minus",
    kbMediaStop                = "CTRL + SUPER + Delete",
    kbVolumeMute               = "CTRL + SUPER + M",

    -- Clipboard & Emoji
    kbClipboard                = "SUPER + V",
    kbClipboardDel             = "SUPER + ALT + V",
    kbClipboardPasteLatest     = "SUPER + SHIFT + V",
    kbEmoji                    = "SUPER + Period",

    -- Shell & Session
    kbLauncher                 = "SUPER + SUPER_L",
    kbLock                     = "SUPER + L",
    kbRestoreLock              = "SUPER + ALT + L",
    kbSession                  = "CTRL + ALT + Delete",
    kbShowSidebar              = "SUPER + N",
    kbClearNotifs              = "SUPER + SHIFT + N",
    kbSleep                    = "SUPER + SHIFT + L",
    kbKeybindsCheatsheet       = "SUPER + Slash",
}

local config_dir = os.getenv("XDG_CONFIG_HOME") or (home .. "/.config")
local override_file = io.open(config_dir .. "/mercury/hyprland.json", "r")
if override_file then
    local raw = override_file:read("*a")
    override_file:close()
    local ok, overrides = pcall(json.decode, raw)
    if ok and type(overrides) == "table" then
        for k, v in pairs(overrides) do
            vars[k] = v
        end
    end
end

return vars
