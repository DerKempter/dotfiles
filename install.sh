#!/usr/bin/env bash
# ==============================================================================
# Dotfiles Essentials Installer (Bash Bootstrapper)
# ==============================================================================
# Installs core CLI utilities, shells, and dependencies across CachyOS / Arch
# and Debian / Ubuntu (Tuxedo OS), then links configurations using GNU Stow.
# ==============================================================================

set -euo pipefail

# Color palette & styling
BOLD="\033[1m"
GREEN="\033[32m"
CYAN="\033[36m"
YELLOW="\033[33m"
RED="\033[31m"
RESET="\033[0m"

log_info() { printf "%b[INFO]%b %s\n" "${CYAN}${BOLD}" "${RESET}" "$1"; }
log_success() { printf "%b[OK]%b %s\n" "${GREEN}${BOLD}" "${RESET}" "$1"; }
log_warn() { printf "%b[WARN]%b %s\n" "${YELLOW}${BOLD}" "${RESET}" "$1"; }
log_error() { printf "%b[ERROR]%b %s\n" "${RED}${BOLD}" "${RESET}" "$1"; }

has_cmd() {
    for cmd in "$@"; do
        if command -v "$cmd" >/dev/null 2>&1; then
            return 0
        fi
    done
    return 1
}

printf "%b==============================================================================%b\n" "${CYAN}${BOLD}" "${RESET}"
printf "%b          Dotfiles Essentials Bootstrapper & Package Installer           %b\n" "${CYAN}${BOLD}" "${RESET}"
printf "%b==============================================================================%b\n\n" "${CYAN}${BOLD}" "${RESET}"

# Ensure ~/.local/bin exists and is in PATH
mkdir -p "$HOME/.local/bin"
export PATH="$HOME/.local/bin:$PATH"

# -----------------------------------------------------------------------------
# OS Detection
# -----------------------------------------------------------------------------
OS_TYPE="unknown"
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_TYPE=$ID
    OS_LIKE=${ID_LIKE:-""}
else
    log_error "Cannot detect OS type via /etc/os-release."
    exit 1
fi

log_info "Detected Operating System: ${BOLD}${OS_TYPE}${RESET}"

# -----------------------------------------------------------------------------
# Arch Linux / CachyOS Installation
# -----------------------------------------------------------------------------
install_arch() {
    log_info "Installing essential packages via pacman..."
    
    local ARCH_PACKAGES=(
        nushell zsh bash
        stow just
        starship atuin
        yazi bat lazygit lazydocker micro
        zoxide keychain git-delta fzf ripgrep
        uv fnm
    )

    if command -v pacman >/dev/null 2>&1; then
        sudo pacman -S --needed --noconfirm "${ARCH_PACKAGES[@]}" || {
            log_warn "Some packages failed to install directly via pacman. Retrying core packages..."
            sudo pacman -S --needed --noconfirm nushell zsh bash stow just starship atuin yazi bat lazygit micro zoxide keychain git-delta fzf ripgrep uv
        }
    fi
}

# -----------------------------------------------------------------------------
# Debian / Ubuntu / Tuxedo OS Installation
# -----------------------------------------------------------------------------
install_debian() {
    log_info "Installing APT essentials..."
    sudo apt-get update -qq
    sudo apt-get install -y -qq \
        zsh bash stow bat micro zoxide keychain git-delta fzf ripgrep \
        curl git build-essential ca-certificates

    log_info "Checking & installing standalone CLI tools into ~/.local/bin..."

    # 1. Just runner
    if ! has_cmd just; then
        log_info "Installing just..."
        curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to "$HOME/.local/bin"
    fi

    # 2. Starship prompt
    if ! has_cmd starship; then
        log_info "Installing starship..."
        curl -sS https://starship.rs/install.sh | sh -s -- -y -b "$HOME/.local/bin"
    fi

    # 3. uv Python manager
    if ! has_cmd uv; then
        log_info "Installing uv..."
        curl -LsSf https://astral.sh/uv/install.sh | sh
    fi

    # 4. Nushell
    if ! has_cmd nu; then
        log_info "Installing Nushell..."
        local NU_VERSION
        NU_VERSION=$(curl -s https://api.github.com/repos/nushell/nushell/releases/latest | grep -oP '"tag_name": "\K[^"]+')
        local ARCH
        ARCH=$(uname -m)
        local NU_TAR="nu-${NU_VERSION}-${ARCH}-unknown-linux-gnu.tar.gz"
        local TEMP_DIR
        TEMP_DIR=$(mktemp -d)
        curl -sSL "https://github.com/nushell/nushell/releases/download/${NU_VERSION}/${NU_TAR}" -o "${TEMP_DIR}/${NU_TAR}"
        tar -xzf "${TEMP_DIR}/${NU_TAR}" -C "${TEMP_DIR}"
        cp "${TEMP_DIR}"/nu-*/nu* "$HOME/.local/bin/"
        rm -rf "${TEMP_DIR}"
    fi

    # 5. Lazygit
    if ! has_cmd lazygit; then
        log_info "Installing lazygit..."
        local LG_VERSION
        LG_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -oP '"tag_name": "v\K[^"]+')
        curl -sLo "$HOME/.local/bin/lazygit.tar.gz" "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LG_VERSION}_Linux_x86_64.tar.gz"
        tar -xzf "$HOME/.local/bin/lazygit.tar.gz" -C "$HOME/.local/bin" lazygit
        rm -f "$HOME/.local/bin/lazygit.tar.gz"
    fi

    # 6. Lazydocker
    if ! has_cmd lazydocker; then
        log_info "Installing lazydocker..."
        DIR="$HOME/.local/bin" curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash
    fi

    # 7. Atuin
    if ! has_cmd atuin; then
        log_info "Installing atuin..."
        curl --proto '=https' --tlsv1.2 -sSf https://setup.atuin.sh | bash
    fi

    # 8. Yazi
    if ! has_cmd yazi; then
        log_info "Installing yazi..."
        local YAZI_TAR="yazi-x86_64-unknown-linux-gnu.zip"
        local TEMP_DIR
        TEMP_DIR=$(mktemp -d)
        curl -sSL "https://github.com/sxyazi/yazi/releases/latest/download/${YAZI_TAR}" -o "${TEMP_DIR}/${YAZI_TAR}"
        unzip -q "${TEMP_DIR}/${YAZI_TAR}" -d "${TEMP_DIR}"
        cp "${TEMP_DIR}"/yazi-*/yazi "${TEMP_DIR}"/yazi-*/ya "$HOME/.local/bin/"
        rm -rf "${TEMP_DIR}"
    fi
}

# -----------------------------------------------------------------------------
# Dispatch Installer
# -----------------------------------------------------------------------------
case "$OS_TYPE" in
    cachyos|arch)
        install_arch
        ;;
    ubuntu|debian|tuxedo|pop|mint)
        install_debian
        ;;
    *)
        if [[ "${OS_LIKE}" == *"arch"* ]]; then
            install_arch
        elif [[ "${OS_LIKE}" == *"debian"* || "${OS_LIKE}" == *"ubuntu"* ]]; then
            install_debian
        else
            log_warn "Unrecognized OS distribution '${OS_TYPE}'. Attempting pacman or apt fallback..."
            if command -v pacman >/dev/null 2>&1; then
                install_arch
            elif command -v apt-get >/dev/null 2>&1; then
                install_debian
            else
                log_error "No supported package manager (pacman/apt) found."
                exit 1
            fi
        fi
        ;;
esac

log_success "All essential CLI tools and dependencies are installed."

# -----------------------------------------------------------------------------
# Symlink Dotfiles & Yazi Plugins
# -----------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

if command -v just >/dev/null 2>&1; then
    log_info "Applying GNU Stow symlinks via just..."
    just link
    
    if command -v ya >/dev/null 2>&1; then
        log_info "Installing Yazi package plugins..."
        just install || true
    fi
elif command -v stow >/dev/null 2>&1; then
    log_info "Applying GNU Stow symlinks directly..."
    stow -R common --verbose
else
    log_warn "Neither 'just' nor 'stow' found. Skipping automatic symlinking."
fi

printf "\n%b==============================================================================%b\n" "${GREEN}${BOLD}" "${RESET}"
printf "%b             🎉 Dotfiles Installation & Setup Complete!              %b\n" "${GREEN}${BOLD}" "${RESET}"
printf "%b==============================================================================%b\n" "${GREEN}${BOLD}" "${RESET}"
