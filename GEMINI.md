# Dotfiles Gemini Instructions

This repository contains personal configuration files for Linux development environments (primarily CachyOS/Tuxedo OS), optimized for Nushell, Ghostty, and Starship.

## Project Structure

- `.config/`: Contains application-specific configurations.
  - `nushell/`: Nushell configuration and custom scripts.
    - `scripts/`: Modular Nushell scripts.
    - `hooks/`: Shell hooks (e.g., environment auto-activation).
  - `ghostty/`: Ghostty terminal emulator configuration.
  - `starship.toml`: Starship prompt configuration.

## Development Workflow

### Adding Nushell Scripts
1. Create a new `.nu` script in `.config/nushell/scripts/`.
2. Use descriptive command names and provide documentation (comments).
3. Export the script in `.config/nushell/scripts/mod.nu` using `export use <filename>.nu *`.

### Environment Management
- This project uses `uv` for Python environment management.
- Custom hooks (like `hooks/py_env-hook.nu`) handle automatic environment detection or specific shell behaviors.

## Conventions

- **Modularity**: Keep Nushell configurations modular. Prefer creating a script in `scripts/` over adding large blocks directly to `config.nu`.
- **Naming**: Use kebab-case for script filenames and snake_case or kebab-case for Nushell commands, following local patterns (see `docker.nu` or `python.nu`).
- **Paths**: Use `$nu.home-dir` or `$nu.config-path` to build paths dynamically where possible to ensure portability.

## Safety & Privacy

- **Secrets**: NEVER commit API keys, tokens, or personal information. Use `.env` files (which are git-ignored) or system-level secret management.
- **History**: Command history (`history.txt`) is ignored and should remain so.
- **Symlinks**: This project uses **GNU Stow** for symlink management. The repository structure mirrors the user's home directory (e.g., `.config/` in the repo should be linked to `~/.config/`). To apply changes, run `stow .` from the root of the repository. Update the `README.md` if the installation process changes.
