# ~/.zshrc: executed by zsh(1) for non-login and interactive shells.

# Load CachyOS Zsh configuration if available
if [ -f /usr/share/cachyos-zsh-config/cachyos-config.zsh ]; then
  source /usr/share/cachyos-zsh-config/cachyos-config.zsh
fi


# ==========================================
# Portable Toolchain & Environment Variables
# ==========================================

export MICRO_TRUECOLOR=1
export RIPGREP_CONFIG_PATH="$HOME/.ripgreprc"

# fnm (Fast Node Manager)
FNM_PATH="$HOME/.local/share/fnm"
if [ -d "$FNM_PATH" ]; then
  export PATH="$FNM_PATH:$PATH"
  eval "`fnm env`"
fi

# Bun
export BUN_INSTALL="$HOME/.bun"
[ -d "$BUN_INSTALL" ] && export PATH="$BUN_INSTALL/bin:$PATH"

# Deno
[ -f "$HOME/.deno/env" ] && . "$HOME/.deno/env"

# SQL Server Command Line Tools
[ -d "/opt/mssql-tools18/bin" ] && export PATH="$PATH:/opt/mssql-tools18/bin"

# OpenCode & Local Bin
[ -d "$HOME/.opencode/bin" ] && export PATH="$HOME/.opencode/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"

# Sourcing Cargo
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

# Keychain SSH Agent setup
if command -v keychain >/dev/null 2>&1; then
  eval $(SHELL=/bin/zsh keychain --eval --quiet --noask)
fi

# ==========================================
# Muscle-Memory Parity Aliases
# ==========================================
if command -v bat >/dev/null 2>&1; then
  alias cat="bat --theme=ansi"
fi
if command -v lazygit >/dev/null 2>&1; then
  alias lg="lazygit"
fi
if command -v lazydocker >/dev/null 2>&1; then
  alias ld="lazydocker"
fi

# Standard shortcuts
alias ll="ls -alF"
alias la="ls -A"
alias l="ls -CF"

# ==========================================
# Modern CLI Tool Initializers
# ==========================================

# Zoxide smart navigation (alias cd=z)
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
  alias cd=z
fi

# Atuin shell history
[ -f "$HOME/.atuin/bin/env" ] && . "$HOME/.atuin/bin/env"
if command -v atuin >/dev/null 2>&1; then
  eval "$(atuin init zsh)"
fi

# Starship Prompt (Must be loaded last)
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi
