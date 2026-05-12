# Dotfiles

My personal configuration suite for a productive development environment on Linux (CachyOS/Tuxedo OS). Optimized for Nushell, Ghostty, and Starship.

## What's Inside?
*   **Nushell**: Shell configuration (`config.nu`, `env.nu`) and custom scripts.
*   **Ghostty**: Terminal emulator configuration.
*   **Starship**: Cross-shell prompt configuration.

---

## Installation & Setup

After cloning this repository to `~/dotfiles`, run the following steps to link the configurations to your system.

### 1. Create Symlinks (using GNU Stow)
This repository is structured to be used with GNU Stow. Run `stow` from the root of the repository to link the `.config` directory to your home folder:

```bash
# From ~/dotfiles
stow .
```

This will create a symlink for `~/.config` (or its contents) pointing back to this repository.

### 2. Install Dependencies
Ensure the following tools are installed on the host machine:
*   **Nushell**: The primary shell.
*   **Starship**: The prompt engine.
*   **Ghostty**: The terminal emulator.
*   **uv**: Python package manager for local development.

### 3. Shell Initialization
The `config.nu` relies on Starship initialization. Ensure your `config.nu` includes:
```nu
mkdir ~/.cache/starship
starship init nu | save -f ~/.cache/starship/init.nu
```

---

## Python Workflow
This setup includes a custom `py` helper script for **uv** development.
*   `py run <file>`: Runs a script within the `uv` virtual environment.

---

## Privacy Notes
*   **History**: `nushell/history.txt` is ignored via `.gitignore` to prevent leaking command history.
*   **Secrets**: All `.env` files are ignored. Recreate your `.env` manually for services like the `ews-mailservice`.
