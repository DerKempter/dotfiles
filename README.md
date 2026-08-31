# dotfiles

Personal configuration files for Linux (Tuxedo OS / KDE Plasma 6 / CachyOS / Hyprland), optimized for Nushell, Zsh, Ghostty, Zed, Yazi, Starship, and Vicinae.

## Dynamic Theming (Material You / Matugen)

This repository features a system-wide dynamic Material You theming pipeline powered by [Matugen](https://github.com/InioX/matugen) (`scheme-expressive` default).

Whenever a wallpaper is selected or a theme profile is changed, colors are instantly extracted and synchronized across all desktop environments and applications in real time:

*   **Desktop Environments**:
    *   **KDE Plasma 6**: Automatically generates and applies decimal RGB color schemes (`Matugen.colors`) via `plasma-apply-colorscheme`.
    *   **Hyprland / Niri / Waybar / SwayNC / SwayOSD / Wlogout**: Generates dynamic CSS and Lua palettes.
*   **Application Launchers & Terminals**:
    *   **Vicinae**: Custom dynamic TOML theme (`~/.local/share/vicinae/themes/matugen.toml`) with instant live reload.
    *   **Starship Prompt**: Decoupled dynamic prompt palette (`~/.cache/starship.toml`), keeping git repositories clean.
    *   **Ghostty**: Dynamic terminal palette with light/dark contrast tuning.

---

## Applications & Configs

*   **Shells**:
    *   **Nushell** (`nu`): Primary shell with automatic Python `.venv` activation, database-backed `npm` completions, custom SSH helpers, wallpaper management, and Docker integrations.
    *   **Bash / Zsh**: Muscle-memory and prompt parity with Nushell. Zsh is set as the default IDE shell in JetBrains, while Bash provides remote environment scripts (like `sshi` and `dockeri` for injecting configs).
*   **Ghostty**: GPU-accelerated terminal styled with dynamic Material You palettes and custom window splitting keybinds.
*   **Atuin**: SQLite-backed shell history with a pastel theme.
*   **Starship**: Prompt engine with dynamic Material You accent colors, Git status, and background jobs.
*   **Yazi**: GPU-accelerated terminal file manager with automatic exit directory syncing and fuzzy search (`yafg`).
*   **Bat**: Syntax-highlighted `cat` replacement with Git diff integration.
*   **Lazygit**: Git TUI styled with mauve and lavender accents.
*   **Lazydocker**: Docker TUI matching the Lazygit styling.
*   **Micro**: Terminal text editor customized with custom bindings and encoding auto-detection.
*   **Zed**: Code editor configured with Biome linters, JetBrains keymaps, and local AI agent integration.
*   **Vicinae**: C++ & Qt app launcher configured with dynamic Matugen theming, JetBrainsMono font, favorite applications, and dmenu workflow scripts.
*   **mpv & uosc**: Minimalist, high-performance media consumption stack with native Wayland, native PipeWire, and VA-API hardware decoding. Integrated with `uosc` overlay controls and custom chapter-based `sponsorblock` skipping.
*   **Justfile**: Automation runner for managing symlinks and test suites.

---

## Quick Start & Installation

### Automated Installer (Recommended)

Clone the repository and run the bootstrapper:

```bash
git clone https://github.com/DerKempter/dotfiles.git ~/dotfiles
cd ~/dotfiles

# On a fresh machine (Bash bootstrapper):
./install.sh

# Or inside Nushell (interactive dependency audit & installer):
nu install.nu  # or: just setup
```

The bootstrapper automatically detects your OS distribution (CachyOS / Arch or Debian / Ubuntu / Tuxedo OS), installs missing essential dependencies, applies GNU Stow symlinks, and deploys Yazi plugins.

---

### Manual Linking

If you already have all packages installed and only want to apply symlinks:

```bash
# Apply Stow symlinks:
just link
```

### Dependencies & Installation

Ensure you have the following packages installed:
*   **Shells**: `nu` (0.113.0+), `zsh`, `bash`
*   **Setup**: `stow`, `just`
*   **Theming**: `matugen`
*   **Prompt & Multiplexer**: `starship`, `ghostty`, `atuin`
*   **TUI Utilities**: `yazi`, `bat`, `lazygit`, `lazydocker`, `micro`
*   **Helpers**: `zoxide`, `keychain`
*   **Search & Diffing**: `fzf`, `ripgrep`, `git-delta`
*   **Package Managers**: `uv`

#### Arch Linux (CachyOS)
```bash
sudo pacman -S nushell zsh bash stow just starship ghostty atuin yazi bat lazygit lazydocker micro zoxide keychain git-delta fzf ripgrep uv matugen
```

#### Debian / Ubuntu (Tuxedo OS)
```bash
sudo apt update
sudo apt install zsh bash stow just bat micro zoxide keychain git-delta fzf ripgrep
```

*Note for Debian/Ubuntu*:
- Packages like `nushell`, `starship`, `lazygit`, `lazydocker`, `yazi`, `atuin`, `ghostty`, `matugen`, and `uv` can be installed via Cargo or official GitHub binary releases:
  - **Matugen**: `cargo install matugen`
  - **Starship**: `curl -sS https://starship.rs/install.sh | sh`
  - **uv**: `curl -LsSf https://astral.sh/uv/install.sh | sh`
  - **Lazygit**: Install via official GitHub pre-built binary release.
  - **Ghostty**: Download and install `.deb` from official repository releases.

---

## Nushell Helpers

Custom commands in `.config/nushell/scripts/`:

| Command | Script | Description |
|:---|:---|:---|
| `wallpaper <path\|category\|random>` | [desktop.nu](common/.config/nushell/scripts/desktop.nu) | Sets wallpaper across KDE Plasma and Wayland, extracts Material You colors, and reloads all app themes. Supports case-insensitive category resolution and tab autocompletions. |
| `wallpaper random [category]` | [desktop.nu](common/.config/nushell/scripts/desktop.nu) | Picks a random wallpaper from all subfolders or a specific category (e.g. `wallpaper random Space`, `wallpaper random Kitties`). |
| `wallpaper list` | [desktop.nu](common/.config/nushell/scripts/desktop.nu) | Displays a structured table of all indexed wallpapers and subcategories. |
| `theme <profile\|color\|mode>` | [desktop.nu](common/.config/nushell/scripts/desktop.nu) | Re-applies theme schemes (`expressive`, `fruit-salad`, `vibrant`, `rainbow`, etc.), toggles dark/light mode, or sets custom extracted hex swatches. |
| `git feature`, `git catchup`, `git publish`, `git history`, `git uncommit`, `git clean-merged`, `git gone`, `git nuke` | [git.nu](common/.config/nushell/scripts/git.nu) | Custom Git workflow subcommands (safe branching, rebasing, publishing, tabular history, uncommitting, and cleanup/nuking). |
| `nu-fail <msg>` | [misc.nu](common/.config/nushell/scripts/misc.nu) | Standardized error output helper supporting interactive stderr printing or non-zero exit codes (`--code` / `--fatal`) for automation. |
| `py <action>` | [python.nu](common/.config/nushell/scripts/python.nu) | Runs scripts using `uv` virtualenv when available, falling back to system Python. |
| `dn <action>` | [dotnet.nu](common/.config/nushell/scripts/dotnet.nu) | Wrapper for `.csproj` tasks (`run`, `watch`, `build`, `test`). |
| `npm run [script]` | [node.nu](common/.config/nushell/scripts/node.nu) | Auto-completes scripts directly from `package.json` utilizing Nushell's SQLite storage. |
| `dps`, `dx`, `dockeri` | [docker.nu](common/.config/nushell/scripts/docker.nu) | Docker autocompletion. `dockeri` base64-injects your local `.bashrc` into running containers. |
| `sshi`, `sshc`, `sync-starship`, `sync-nushell` | [ssh.nu](common/.config/nushell/scripts/ssh.nu) | SSH helper suite. `sshi` dynamically boots Nushell (if available) or falls back to Bash with local `.bashrc` injection. `sync-starship` and `sync-nushell` sync prompt and Nushell configs. |
| `git histogram` | [misc.nu](common/.config/nushell/scripts/misc.nu) | Visual contribution graph per author in the terminal. |
| `fix-anims` | [misc.nu](common/.config/nushell/scripts/misc.nu) | Resets frozen Aura Glow window animations. |
| `parse-scraper` | [misc.nu](common/.config/nushell/scripts/misc.nu) | Parses scrape logs into tabular formats. |
| `rgt <pattern>` | [misc.nu](common/.config/nushell/scripts/misc.nu) | Searches files recursively using `ripgrep` and outputs matches in a beautiful, highlighted Nushell table. |
| `test-speed` | [test-speed.nu](common/.config/nushell/scripts/test-speed.nu) | Runs a native network download speed test in Nushell. |
| `setup-mpv` | [setup_mpv.nu](common/.config/nushell/scripts/setup_mpv.nu) | Bootstraps the MPV stack: provisions isolated `yt-dlp`, deploys `uosc` overlays and `sponsorblock` scripts, and configures the `ff2mpv` Firefox native messaging host bridge. |
| `update-aerion` | [misc.nu](common/.config/nushell/scripts/misc.nu) | Installs/upgrades the Aerion email client from GitHub releases. |

### Auto .venv Detection
When navigating (`cd` / `z`) into any folder with a `.venv` directory, the shell automatically updates `$env.PATH` and loads `VIRTUAL_ENV`. Navigating out of the project ancestry tree deactivates it.

---

## Local AI Agent Integration
This setup integrates Zed with local GGUF models running locally.
See the [Local AI Developer Agents Guide](Agents.md) for architecture details and model settings.

---

## Privacy & Safety
*   **Command History**: Nushell command history (`history.txt`) is ignored by Git.
*   **Secrets**: All `.env` environment files are globally ignored by Git. Create them locally as needed.
