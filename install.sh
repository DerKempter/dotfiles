#!/usr/bin/env bash
# =============================================================================
# Dotfiles Essentials Installer (Bash Bootstrapper)
# Audits, installs dependencies, and links dotfiles across supported distributions
# =============================================================================
set -euo pipefail

BOLD="$(tput bold 2>/dev/null || echo '')"
GREEN="$(tput setaf 2 2>/dev/null || echo '')"
YELLOW="$(tput setaf 3 2>/dev/null || echo '')"
CYAN="$(tput setaf 6 2>/dev/null || echo '')"
RED="$(tput setaf 1 2>/dev/null || echo '')"
RESET="$(tput sgr0 2>/dev/null || echo '')"

log_info() {
    printf "%b==> %b%s\n" "${CYAN}${BOLD}" "${RESET}" "$1"
}

log_success() {
    printf "%b✓ %b%s\n" "${GREEN}${BOLD}" "${RESET}" "$1"
}

log_warn() {
    printf "%b⚠ %b%s\n" "${YELLOW}${BOLD}" "${RESET}" "$1"
}

log_error() {
    printf "%b✗ %b%s\n" "${RED}${BOLD}" "${RESET}" "$1" >&2
}

# -----------------------------------------------------------------------------
# Header
# -----------------------------------------------------------------------------
printf "%b          Dotfiles Essentials Bootstrapper & Package Installer           %b\n" "${CYAN}${BOLD}" "${RESET}"
printf "%b=========================================================================%b\n\n" "${CYAN}" "${RESET}"

# -----------------------------------------------------------------------------
# OS Detection
# -----------------------------------------------------------------------------
OS_ID=""
if [ -f /etc/os-release ]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    OS_ID="${ID:-}"
elif [ "$(uname)" == "Darwin" ]; then
    OS_ID="darwin"
fi

if [ -z "$OS_ID" ]; then
    log_error "Unable to identify operating system. Exiting."
    exit 1
fi

log_info "Detected operating system: ${BOLD}${OS_ID}${RESET}"

# -----------------------------------------------------------------------------
# Dependency Audit Configuration
# -----------------------------------------------------------------------------
ESSENTIAL_TOOLS=(
    "git:git:git:git:git:git:git"
    "curl:curl:curl:curl:curl:curl:curl"
    "stow:stow:stow:stow:stow:stow:stow"
    "just:just:just:just:just:just:just"
    "nu:nushell:nushell:nushell:nushell:nushell:nushell"
    "starship:starship:starship:starship:starship:starship:starship"
    "zoxide:zoxide:zoxide:zoxide:zoxide:zoxide:zoxide"
    "atuin:atuin:atuin:atuin:atuin:atuin:atuin"
    "bat:bat:bat:bat:bat:bat:bat"
    "rg:ripgrep:ripgrep:ripgrep:ripgrep:ripgrep:ripgrep"
    "fd:fd:fd-find:fd-find:fd:fd:fd"
    "fzf:fzf:fzf:fzf:fzf:fzf:fzf"
    "delta:git-delta:git-delta:git-delta:git-delta:git-delta:git-delta"
    "yazi:yazi:yazi:yazi:yazi:yazi:yazi"
    "fnm:fnm:fnm:fnm:fnm:fnm:fnm"
)

# -----------------------------------------------------------------------------
# Installation Helper Functions
# -----------------------------------------------------------------------------
MISSING_PKGS=()
SPECIAL_INSTALLS=()

for entry in "${ESSENTIAL_TOOLS[@]}"; do
    IFS=":" read -r bin_name arch_pkg debian_pkg fedora_pkg suse_pkg alpine_pkg brew_pkg <<< "$entry"
    if ! command -v "$bin_name" >/dev/null 2>&1; then
        log_warn "Missing required binary: ${BOLD}$bin_name${RESET}"
        case "$OS_ID" in
            arch|cachyos|endeavouros|manjaro)
                MISSING_PKGS+=("$arch_pkg")
                ;;
            ubuntu|debian|pop|linuxmint|tuxedo|elementary|neon|zorin)
                if [[ "$bin_name" =~ ^(starship|atuin|yazi|fnm|just|delta)$ ]]; then
                    SPECIAL_INSTALLS+=("$bin_name")
                else
                    MISSING_PKGS+=("$debian_pkg")
                fi
                ;;
            fedora|rhel|centos)
                if [[ "$bin_name" =~ ^(fnm|yazi)$ ]]; then
                    SPECIAL_INSTALLS+=("$bin_name")
                else
                    MISSING_PKGS+=("$fedora_pkg")
                fi
                ;;
            opensuse*|suse)
                if [[ "$bin_name" =~ ^(fnm|yazi)$ ]]; then
                    SPECIAL_INSTALLS+=("$bin_name")
                else
                    MISSING_PKGS+=("$suse_pkg")
                fi
                ;;
            alpine)
                MISSING_PKGS+=("$alpine_pkg")
                ;;
            darwin)
                MISSING_PKGS+=("$brew_pkg")
                ;;
        esac
    else
        log_success "Found binary: ${BOLD}$bin_name${RESET}"
    fi
done

# -----------------------------------------------------------------------------
# Package Installation Execution
# -----------------------------------------------------------------------------
if [ "${#MISSING_PKGS[@]}" -gt 0 ]; then
    log_info "Installing missing system packages: ${MISSING_PKGS[*]}..."
    case "$OS_ID" in
        arch|cachyos|endeavouros|manjaro)
            if command -v paru >/dev/null 2>&1; then
                paru -S --needed --noconfirm "${MISSING_PKGS[@]}"
            elif command -v yay >/dev/null 2>&1; then
                yay -S --needed --noconfirm "${MISSING_PKGS[@]}"
            else
                sudo pacman -S --needed --noconfirm "${MISSING_PKGS[@]}"
            fi
            ;;
        ubuntu|debian|pop|linuxmint|tuxedo|elementary|neon|zorin)
            sudo apt update && sudo apt install -y "${MISSING_PKGS[@]}"
            ;;
        fedora|rhel|centos)
            sudo dnf install -y "${MISSING_PKGS[@]}"
            ;;
        opensuse*|suse)
            sudo zypper install -y "${MISSING_PKGS[@]}"
            ;;
        alpine)
            sudo apk add "${MISSING_PKGS[@]}"
            ;;
        darwin)
            brew install "${MISSING_PKGS[@]}"
            ;;
    esac
fi

# -----------------------------------------------------------------------------
# Standalone Fallback Installers (for distros with older/missing repos)
# -----------------------------------------------------------------------------
mkdir -p "$HOME/.local/bin"
export PATH="$HOME/.local/bin:$PATH"

for tool in "${SPECIAL_INSTALLS[@]}"; do
    case "$tool" in
        starship)
            log_info "Installing starship via official install script..."
            curl -sS https://starship.rs/install.sh | sh -s -- -y -b "$HOME/.local/bin"
            ;;
        atuin)
            log_info "Installing atuin via official install script..."
            curl --proto '=https' --tlsv1.2 -sSf https://setup.atuin.sh | bash
            ;;
        just)
            log_info "Installing just via official script..."
            curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to "$HOME/.local/bin"
            ;;
        delta)
            log_info "Installing git-delta..."
            if command -v cargo >/dev/null 2>&1; then
                cargo install git-delta
            fi
            ;;
        yazi)
            log_info "Installing yazi..."
            if command -v cargo >/dev/null 2>&1; then
                cargo install --locked yazi-fm yazi-cli
            fi
            ;;
        fnm)
            log_info "Installing Fast Node Manager (fnm)..."
            curl -fsSL https://fnm.vercel.app/install | bash -s -- --install-dir "$HOME/.local/bin" --skip-shell
            ;;
    esac
done

log_success "All essential CLI tools and dependencies are installed."

# -----------------------------------------------------------------------------
# Bootstrap Default Themes
# -----------------------------------------------------------------------------
bootstrap_default_themes() {
    local defaults_dir="$SCRIPT_DIR/common/.config/matugen/defaults"
    local pairs=(
        "$defaults_dir/ghostty-theme:$HOME/.config/ghostty/themes/matugen"
        "$defaults_dir/yazi-flavor.toml:$HOME/.config/yazi/flavors/matugen.yazi/flavor.toml"
        "$defaults_dir/atuin-theme.toml:$HOME/.config/atuin/themes/matugen.toml"
        "$defaults_dir/micro-colorscheme.micro:$HOME/.config/micro/colorschemes/matugen.micro"
        "$defaults_dir/vicinae-theme.toml:$HOME/.local/share/vicinae/themes/matugen.toml"
    )
    for pair in "${pairs[@]}"; do
        IFS=":" read -r src dst <<< "$pair"
        if [ -f "$src" ] && [ ! -f "$dst" ]; then
            mkdir -p "$(dirname "$dst")"
            cp "$src" "$dst"
            log_success "Bootstrapped default theme: $dst"
        fi
    done
}

# -----------------------------------------------------------------------------
# Symlink Dotfiles & Yazi Plugins
# -----------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

if command -v just >/dev/null 2>&1; then
    log_info "Applying GNU Stow symlinks via just..."
    just link
    
    if command -v ya >/dev/null 2>&1; then
        log_info "Installing Yazi plugins..."
        just install || true
    fi
elif command -v stow >/dev/null 2>&1; then
    log_info "Applying GNU Stow symlinks..."
    stow -R common --target "$HOME" --verbose
    bootstrap_default_themes
else
    log_error "Neither 'just' nor 'stow' found. Cannot link dotfiles."
    exit 1
fi

log_success "🎉 Dotfiles environment setup complete!"
