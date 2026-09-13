# Power & Session (Vicinae Extension)

A comprehensive power and session manager for [Vicinae](https://vicinae.com) on Linux.

## Features

- **Standard Power Actions**:
  - **Lock Screen** (`Ctrl+L`)
  - **Suspend / Sleep** (`Ctrl+U`)
  - **Restart / Reboot** (`Ctrl+R`)
  - **Power Off / Shutdown** (`Ctrl+S`)
  - **Log Out** (`Ctrl+E`)
  - **Hibernate** (`Ctrl+H`)
- **Native Out-of-the-Box**: Uses Vicinae's native deeplinks (`vicinae://launch/power/*`) by default without requiring any configuration.
- **Customizable In-App UI**: Press `Ctrl+C` (or select from Action Panel) to open the interactive settings form and override any action with custom shell commands (e.g. `hyprctl dispatch exit`, `hyprlock`, `swaylock`, `systemctl hibernate`).
- **Rich Detail Metadata**: Displays action type, active handler state, and hotkeys.

## Installation

Clone or copy this folder into your Vicinae extensions directory:

```bash
mkdir -p ~/.local/share/vicinae/extensions/
cp -r power-session ~/.local/share/vicinae/extensions/
```

Or launch directly via deeplink:
```bash
vicinae deeplink vicinae://launch/@joshkempter/power-session/power-menu
```

## Configuration

Settings are stored in `~/.config/vicinae/power-session.json`. You can edit this file directly or use the built-in `Ctrl+C` configuration form.

## License

MIT
