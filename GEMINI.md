# Dotfiles Gemini Instructions

This repository contains personal configuration files for Linux development environments (primarily CachyOS/Tuxedo OS), optimized for Nushell, Zsh, Bash, Ghostty, Atuin, Zed, Yazi, Bat, Lazygit, and Starship.

## Project Structure

- `.config/`: Contains application-specific configurations.
  - `nushell/`: Nushell configuration and custom modular scripts.
    - `config.nu` / `env.nu`: Core shell environment and initialization.
    - `scripts/`: Modular Nushell scripts (loaded via `mod.nu`).
      - `docker.nu`: Extensive completions for Docker/Compose and helpers (`dps`, `dx`, `dockeri`).
      - `ssh.nu`: Modular SSH command suite and autocomplete helpers (`sshi`, `sshc`, `sync-starship`).
      - `python.nu`: `py` command helper for `uv` virtual environments.
      - `dotnet.nu`: `dn` command helper for .NET development.
      - `node.nu`: Completions for `npm` and `npm run` scripts using Nushell's SQLite storage (`stor`).
      - `misc.nu`: System helpers like `fix-anims` (KWin Aura Glow), `git histogram`, `parse-scraper`, and `update-aerion` (automated installer).
      - `test-speed.nu`: Streaming native download performance test.
      - `catppuccin_mocha.nu`: Catppuccin color configuration.
      - `yazi.nu`: Yazi file manager integration with automatic exit cd syncing.
    - `hooks/`: Shell hooks.
      - `py_env-hook.nu`: Automatic activation/deactivation of python `.venv` on directory change.
      - `atuin.nu`: Atuin hook registration.
    - `completions/`: Custom completer definitions (e.g., `git-completions.nu`, `just-completions.nu`).
  - `ghostty/`: Ghostty terminal configuration, including custom split window bindings and Catppuccin Mocha styling.
  - `atuin/`: Custom compact shell history config utilizing a refined custom pastel Catppuccin theme.
  - `zed/`: Advanced high-performance editor config with Biome code formatters and local AI agent workspace profiles.
  - `bat/`: Terminal viewer previewer config, styled with terminal ANSI Catppuccin.
  - `lazygit/`: Git TUI theme config applying Catppuccin Mocha layouts.
  - `yazi/`: Yazi GPU-accelerated terminal file manager config with Catppuccin flavor and fuzzy find plugin.
  - `fish/`: Fully structured, stowed Fish environment with complete muscle-memory and alias parity (inactive on host, but fully tracked).
  - `starship.toml`: Starship cross-shell prompt configuration.
- `.bashrc` / `.zshrc`: Shell initialization configurations.
- `justfile`: Project-level workflow runner (defines link, unlink, adopt, force-link recipes).

## Development Workflow

### Adding Nushell Scripts
1. Create a new `.nu` script in `.config/nushell/scripts/`.
2. Use descriptive command names and provide documentation (comments).
3. Export the script in `.config/nushell/scripts/mod.nu` using `export use <filename>.nu *`.

### Environment Management
- This project uses `uv` for Python environment management.
- Custom hooks (`hooks/py_env-hook.nu`) handle automatic environment detection and activation of `.venv` when changing directories.
- Shell integrates with `keychain` (SSH keys loader), `zoxide` (smart directory switcher via `z`), and `atuin` (shell history).

### Local AI Agent Integration
- Zed editor integrates with local LLM environments (via the `lemonade` provider on `localhost:8000`).
- To understand the AI configuration and GGUF model support details, see the dedicated [Agents.md](Agents.md).

## Conventions

- **Modularity**: Keep Nushell configurations modular. Prefer creating a script in `scripts/` over adding large blocks directly to `config.nu`.
- **Naming**: Use kebab-case for script filenames and snake_case or kebab-case for Nushell commands, following local patterns (see `docker.nu` or `python.nu`).
- **Paths**: Use `$nu.home-dir` or `$nu.config-path` to build paths dynamically where possible to ensure portability.

## Safety & Privacy

- **Secrets**: NEVER commit API keys, tokens, or personal information. Use `.env` files (which are git-ignored) or system-level secret management.
- **History**: Command history (`history.txt`) is ignored and should remain so.
- **Symlinks**: This project uses **GNU Stow** managed via a top-level **`justfile`**. The repository structure mirrors the user's home directory (e.g., `.config/` in the repo links to `~/.config/`). To apply configurations:
  - Run **`just link`** for standard linking.
  - Run **`just force-link`** if pre-existing system folders cause conflicts. This automatically adopts system files and reverts them using Git to force the overwrite cleanly.
  - To undo links, run **`just unlink`**. Always update the `README.md` if the installation process changes.
