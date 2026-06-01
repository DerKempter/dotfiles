# 💫 Personal Linux Dotfiles

Welcome to my personal, high-performance configuration suite optimized for productivity and developer comfort on Linux (**CachyOS / Tuxedo OS**). Featuring a beautifully integrated dark theme system, custom shell completions, custom development helpers, and an integrated local AI assistant setup.

![Theme Accent](https://img.shields.io/badge/Aesthetic-Catppuccin%20Mocha-mauve?style=for-the-badge)
![Shell](https://img.shields.io/badge/Shell-Nushell-yellow?style=for-the-badge&logo=nushell)
![Editor](https://img.shields.io/badge/Editor-Zed-orange?style=for-the-badge)
![Terminal](https://img.shields.io/badge/Terminal-Ghostty-teal?style=for-the-badge)

---

## 🛠️ What's Inside?

This suite contains highly tailored configurations for the following core applications:

*   **🐚 Nushell**: Custom shell configurations (`config.nu`, `env.nu`) featuring automatic virtual environment switching, Zoxide smart jumping, keychain SSH setup, and a database-backed `npm` completion helper.
*   **💻 Ghostty**: GPU-accelerated terminal emulator configured with Catppuccin Mocha colors, blur opacity, ligatures, and custom intuitive layout/split controls.
*   **🕰️ Atuin**: SQLite-powered shell history with a custom pastel Catppuccin theme, custom key bindings, and directory-specific search filters.
*   **🛸 Starship**: Cross-shell prompt engine with quick-loading components and responsive design.
*   **⚡ Zed Editor**: High-speed rust-native editor optimized with Biome linters, JetBrains keymaps, custom profiles, and a robust local AI agent developer ecosystem.

---

## 🚀 Installation & Setup

These configurations are designed to be managed and symlinked using **GNU Stow**.

### 1. Clone & Link Configs
First, clone the repository to your home directory:
```bash
git clone https://github.com/DerKempter/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

Using the task automator **`just`**, link the configurations to your system home directory:
```bash
# If there are no pre-existing config directory conflicts:
just link

# If you have pre-existing system config folders (e.g., auto-generated lazygit/bat directories)
# and want to cleanly force-link and overwrite them with your tracked repository files:
just force-link
```
This automatically symlinks the config directories (like `~/.config/nushell`, `~/.config/zed`, etc.) pointing directly back to your repository files.

### 2. Install Host Dependencies
Ensure the following packages are installed on your host system:
*   `nu`: The primary Nushell shell.
*   `starship`: Cross-shell prompt generator.
*   `ghostty`: Modern terminal emulator.
*   `atuin`: Distributed, syncable shell history.
*   `zoxide`: Smarter directory navigation (`z` / `cd`).
*   `keychain`: SSH agent manager for key handling.
*   `uv`: Ultra-fast Python package installer & resolver.

### 3. Shell Initialization
Nushell leverages Zoxide and Starship. The configurations automatic initializers will run on startup. Ensure you have Zoxide and Starship working properly. `config.nu` automatically manages caching the Starship autoload setup.

---

## 💡 Nushell Custom Command Suite

I have modularized and written several custom command scripts (located in `.config/nushell/scripts/`) to simplify common tasks:

| Command | File | Description |
|:---|:---|:---|
| `py <action> [target]` | [python.nu](file:///.config/nushell/scripts/python.nu) | Runs local scripts using `uv` (if `uv.lock` is present) or fallback to system python/pip. Automatically syncs/adds packages. |
| `dn <action> [proj]` | [dotnet.nu](file:///.config/nushell/scripts/dotnet.nu) | Fast wrapper for `.csproj` management supporting `run`, `watch`, `build`, `test`. |
| `npm run [script]` | [node.nu](file:///.config/nushell/scripts/node.nu) | Enhanced `npm` completion helper using Nushell SQLite storage (`stor`) to parse scripts directly from `package.json`. |
| `dps`, `dx` | [docker.nu](file:///.config/nushell/scripts/docker.nu) | Advanced Docker completion and context management commands. `dx` offers interactive context switching with active container display. |
| `git histogram` | [misc.nu](file:///.config/nushell/scripts/misc.nu) | Beautiful CLI visualizer showing a commit contribution graph per author. |
| `fix-anims` | [misc.nu](file:///.config/nushell/scripts/misc.nu) | System level dbus handler that resets/unloads stuck Aura Glow KWin window animations. |
| `parse-scraper <file>` | [misc.nu](file:///.config/nushell/scripts/misc.nu) | Parses structured date/time logs, extracts dealer IDs and maps them to clean tabular datasets. |
| `test-speed [url]` | [test-speed.nu](file:///.config/nushell/scripts/test-speed.nu) | Measures real-time network download speed natively using Nushell stream payloads. |
| `update-aerion` | [misc.nu](file:///.config/nushell/scripts/misc.nu) | Fully automated, interactive GitHub release installer and upgrader for the Aerion email client. |

### 🤖 Automatic `.venv` Activation
Whenever you change directories (`cd` / `z`) to a folder containing a `.venv` folder, the shell automatically triggers `py_env-hook.nu` to prepend the virtual environment's bin folder to your `PATH` and exports `VIRTUAL_ENV`. Leaving the directory automatically deactivates it.

---

## 🤖 Local AI Agent Ecosystem

This configuration features a premium local-first AI development workflow using the Zed editor linked with local GGUF models.

For detailed architecture diagrams, model definitions, and custom configurations, please refer to:
👉 **[Local AI Developer Agents Guide](file:///home/joshkempter/dotfiles/Agents.md)**

---

## 🔒 Privacy & Safety

*   **Ignored Files**: Shell history (`history.txt`) is excluded to avoid committing user commands.
*   **Secrets**: All `.env` environment files are globally ignored by Git. Re-create them locally for system-level services (like the `ews-mailservice`).
