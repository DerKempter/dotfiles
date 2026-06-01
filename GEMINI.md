# Dotfiles Gemini Instructions

This repository contains personal configuration files for Linux development environments (primarily CachyOS/Tuxedo OS), optimized for Nushell, Ghostty, Atuin, Zed, and Starship.

## Project Structure

- `.config/`: Contains application-specific configurations.
  - `nushell/`: Nushell configuration and custom modular scripts.
    - `config.nu` / `env.nu`: Core shell environment and initialization.
    - `scripts/`: Modular Nushell scripts (loaded via `mod.nu`).
      - `docker.nu`: Extensive completions for Docker/Compose and helpers (`dps`, `dx`).
      - `python.nu`: `py` command helper for `uv` virtual environments.
      - `dotnet.nu`: `dn` command helper for .NET development.
      - `node.nu`: Completions for `npm` and `npm run` scripts using Nushell's SQLite storage (`stor`).
      - `misc.nu`: System helpers like `fix-anims` (KWin Aura Glow), `git histogram`, and `parse-scraper`.
      - `test-speed.nu`: Streaming native download performance test.
      - `catppuccin_mocha.nu`: Catppuccin color configuration.
    - `hooks/`: Shell hooks.
      - `py_env-hook.nu`: Automatic activation/deactivation of python `.venv` on directory change.
      - `atuin.nu`: Atuin hook registration.
    - `completions/`: Custom completer definitions (e.g., `git-completions.nu`).
  - `ghostty/`: Ghostty terminal configuration, including custom split window bindings and Catppuccin Mocha styling.
  - `atuin/`: Custom compact shell history config utilizing a refined custom pastel Catppuccin theme.
  - `zed/`: Advanced high-performance editor config with Biome code formatters and local AI agent workspace profiles.
  - `starship.toml`: Starship cross-shell prompt configuration.

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
- To understand the AI configuration and GGUF model support details, see the dedicated [Agents.md](file:///home/joshkempter/dotfiles/Agents.md).

## Conventions

- **Modularity**: Keep Nushell configurations modular. Prefer creating a script in `scripts/` over adding large blocks directly to `config.nu`.
- **Naming**: Use kebab-case for script filenames and snake_case or kebab-case for Nushell commands, following local patterns (see `docker.nu` or `python.nu`).
- **Paths**: Use `$nu.home-dir` or `$nu.config-path` to build paths dynamically where possible to ensure portability.

## Safety & Privacy

- **Secrets**: NEVER commit API keys, tokens, or personal information. Use `.env` files (which are git-ignored) or system-level secret management.
- **History**: Command history (`history.txt`) is ignored and should remain so.
- **Symlinks**: This project uses **GNU Stow** for symlink management. The repository structure mirrors the user's home directory (e.g., `.config/` in the repo should be linked to `~/.config/`). To apply changes, run `stow .` from the root of the repository. Update the `README.md` if the installation process changes.
