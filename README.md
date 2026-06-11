# dotfiles

Personal configuration files for Linux (Tuxedo OS / CachyOS), optimized for Nushell, Zsh, Ghostty, Zed, Yazi, and Starship.

## Applications & Configs

*   **Shells**:
    *   **Nushell** (`nu`): Primary shell with automatic Python `.venv` activation, database-backed `npm` completions, custom SSH helpers, and Docker integrations.
    *   **Bash / Zsh**: Muscle-memory and prompt parity with Nushell. Zsh is set as the default IDE shell in JetBrains, while Bash provides remote environment scripts (like `sshi` and `dockeri` for injecting configs).
*   **Ghostty**: GPU-accelerated terminal styled with Catppuccin Mocha, featuring custom window splitting keybinds.
*   **Atuin**: SQLite-backed shell history with a pastel Catppuccin theme.
*   **Starship**: Prompt engine showing Git status and background jobs.
*   **Yazi**: GPU-accelerated terminal file manager with automatic exit directory syncing and fuzzy search (`yafg`).
*   **Bat**: Catppuccin-styled `cat` replacement with Git diff integration.
*   **Lazygit**: Git TUI styled with Mocha mauve and lavender.
*   **Lazydocker**: Docker TUI matching the Lazygit styling using the Catppuccin Mocha theme.
*   **Micro**: Terminal text editor customized with Catppuccin Mocha theme, custom bindings, and encoding auto-detection.
*   **Zed**: Code editor configured with Biome linters, JetBrains keymaps, and local AI agent integration.
*   **Justfile**: Automation runner for managing symlinks.

---

## Installation

Configurations are managed using GNU Stow via `just`.

### 1. Clone & Link
Clone the repository:
```bash
git clone https://github.com/DerKempter/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

Apply symlinks to your home directory:
```bash
# Standard link:
just link

# Overwrite pre-existing conflicting configs:
just force-link
```
This symlinks the configs (e.g. `~/.config/nushell`) pointing back to the repository files.

### 2. Dependencies & Installation

Ensure you have the following packages installed:
*   **Shells**: `nu` (0.113.0+), `zsh`, `bash`
*   **Setup**: `stow`, `just`
*   **Prompt & Multiplexer**: `starship`, `ghostty`, `atuin`
*   **TUI Utilities**: `yazi`, `bat`, `lazygit`, `lazydocker`, `micro`
*   **Helpers**: `zoxide`, `keychain`
*   **Search & Diffing**: `fzf`, `ripgrep`, `git-delta`
*   **Package Managers**: `uv`

#### Arch Linux (CachyOS)
All packages are available in the official repositories and can be installed in one command:
```bash
sudo pacman -S nushell zsh bash stow just starship ghostty atuin yazi bat lazygit lazydocker micro zoxide keychain git-delta fzf ripgrep uv
```

#### Debian / Ubuntu (Tuxedo OS)
Install the core packages from the standard repositories:
```bash
sudo apt update
sudo apt install zsh bash stow just bat micro zoxide keychain git-delta fzf ripgrep
```

*Note for Debian/Ubuntu*:
- The remaining packages (`nushell`, `starship`, `lazygit`, `lazydocker`, `yazi`, `atuin`, `ghostty`, `uv`) are either missing from default repositories or are outdated. It is recommended to install them via their official sources:
  - **Starship**: `curl -sS https://starship.rs/install.sh | sh`
  - **Lazygit**: Install via official GitHub pre-built release binary.
  - **Nushell / Yazi / Atuin**: Best installed via `cargo` or official pre-built releases.
  - **Ghostty**: Download and install the `.deb` package from the official repository releases.
  - **uv**: `curl -LsSf https://astral.sh/uv/install.sh | sh`
  - **lazydocker**: `curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash`

---

## Nushell Helpers

Custom commands in `.config/nushell/scripts/`:

| Command | Script | Description |
|:---|:---|:---|
| `py <action>` | [python.nu](.config/nushell/scripts/python.nu) | Runs scripts using `uv` virtualenv when available, falling back to system Python. |
| `dn <action>` | [dotnet.nu](.config/nushell/scripts/dotnet.nu) | Wrapper for `.csproj` tasks (`run`, `watch`, `build`, `test`). |
| `npm run [script]` | [node.nu](.config/nushell/scripts/node.nu) | Auto-completes scripts directly from `package.json` utilizing Nushell's SQLite storage. |
| `dps`, `dx`, `dockeri` | [docker.nu](.config/nushell/scripts/docker.nu) | Docker autocompletion. `dockeri` base64-injects your local `.bashrc` into running containers. |
| `sshi`, `sshc`, `sync-starship`, `sync-nushell` | [ssh.nu](.config/nushell/scripts/ssh.nu) | SSH helper suite. `sshi` dynamically boots Nushell (if available) or falls back to Bash with local `.bashrc` injection. `sync-starship` and `sync-nushell` sync your prompt and Nushell configurations respectively. |
| `git histogram` | [misc.nu](.config/nushell/scripts/misc.nu) | Visual contribution graph per author in the terminal. |
| `fix-anims` | [misc.nu](.config/nushell/scripts/misc.nu) | Resets frozen Aura Glow window animations. |
| `parse-scraper` | [misc.nu](.config/nushell/scripts/misc.nu) | Parses scrape logs into tabular formats. |
| `rgt <pattern>` | [misc.nu](.config/nushell/scripts/misc.nu) | Searches files recursively using `ripgrep` and outputs matches in a beautiful, pastel-highlighted Nushell table. |
| `test-speed` | [test-speed.nu](.config/nushell/scripts/test-speed.nu) | Runs a native network download speed test in Nushell. |
| `update-aerion` | [misc.nu](.config/nushell/scripts/misc.nu) | Installs/upgrades the Aerion email client from GitHub releases. |

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
