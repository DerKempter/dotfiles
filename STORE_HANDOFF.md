# Dotfiles Migration Handoff: `Stow` to `store`

This file documents the changes, configurations, and migration steps prepared to transition this dotfiles repository from **GNU Stow** to the **`store`** dotfile manager.
[GitHub Link](https://github.com/cushycush/store)

---

## 1. Mapped Configurations

All configuration definitions have been created in the new **[.store/config.yaml](file:///home/joshkempter/dotfiles/.store/config.yaml)** file. Mappings are designed to work directly with your existing repository layout without requiring any restructuring yet.

### Key Mapping Rules:
*   **Direct File Keys**: Files in the root of the repository are mapped explicitly (e.g. `".zshrc"`, `".gitconfig"`).
*   **Direct Directory Keys**: Configurations under `.config` are referenced by their exact subfolder paths (e.g. `".config/ghostty"`, `".config/zed"`).
*   **Decoupled Targets**: The repository paths are mapped to absolute locations on the host system.

---

## 2. Multi-Platform & Hostname Portability

To keep this repository fully shareable with friends/colleagues and sync-safe with your Tuxedo OS work laptop:

1.  **Windows Support**: Targets have been defined for Windows (`os: windows`) mapping to standard paths like `%APPDATA%` and `%USERPROFILE%` for:
    *   [Zed](file:///home/joshkempter/dotfiles/.config/zed)
    *   [Yazi](file:///home/joshkempter/dotfiles/.config/yazi)
    *   [Nushell](file:///home/joshkempter/dotfiles/.config/nushell)
    *   [Starship](file:///home/joshkempter/dotfiles/.config/starship.toml)
    *   [Antigravity](file:///home/joshkempter/dotfiles/.config/antigravity)
    *   Git Configurations
2.  **Linux-Only Restriction**: Platforms like `ghostty`, `bash`, `zsh`, and `ripgrep` are restricted to `os: linux`.
3.  **Dynamic Hostname Check (Personal Machine)**: 
    *   Desktop-specific configurations (Niri, Vesktop, OpenRGB) are locked behind the `PERSONAL_HOSTNAME` environment variable using Go templating:
        ```yaml
        when:
          - os: linux
            hostname: '{{ env "PERSONAL_HOSTNAME" }}'
        ```
    *   This ensures these configs are automatically **skipped** on your work laptop and colleagues' systems unless they explicitly set `export PERSONAL_HOSTNAME="..."` to match their host.

---

## 3. Automation Update

The **[justfile](file:///home/joshkempter/dotfiles/justfile)** was updated to replace GNU Stow commands with `store` CLI integrations:
*   `just link` -> Deploys configs using `store apply`.
*   `just diff` -> Previews system links using `store diff`.
*   `just doctor` -> Runs a config health check using `store doctor`.
*   `just unlink-stow` -> Runs `stow -D .` (retained as a legacy helper to clean up old Stow symlinks).

---

## 4. Final Migration Steps

Whenever you are ready to complete the migration on any machine:

1.  **Install `store`**:
    *   *Arch / CachyOS:* `yay -S store`
    *   *Windows:* Download the binary from the GitHub releases page, or via `go install github.com/cushycush/store/cmd/store@latest`.
2.  **Clean up Stow**:
    ```bash
    just unlink-stow
    ```
3.  **Export Hostname (Personal Machine Only)**:
    Add the environment variable to your shell initialization on your personal desktop (e.g. in `~/.zshenv` or `~/.bashrc`):
    ```bash
    export PERSONAL_HOSTNAME=<hostname>
    ```
4.  **Establish `store` Links**:
    ```bash
    just link
    ```
