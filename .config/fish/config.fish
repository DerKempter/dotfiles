# Disable the default welcoming greeting
set -g fish_greeting ""

# ==========================================
# Environment Variables & Path Extensions
# ==========================================
fish_add_path "$HOME/.local/bin"
fish_add_path "$HOME/.cargo/bin"
fish_add_path "$HOME/.local/share/fnm"
fish_add_path "/opt/mssql-tools18/bin"
fish_add_path "$HOME/.bun/bin"
fish_add_path "$HOME/.opencode/bin"

# Fast Node Manager (fnm)
if command -v fnm >/dev/null 2>&1
  fnm env --error-on-no-node | source
end

# Bun
set -gx BUN_INSTALL "$HOME/.bun"

# Deno
if test -f "$HOME/.deno/env.fish"
  source "$HOME/.deno/env.fish"
else if test -f "$HOME/.deno/env"
  set -gx DENO_INSTALL "$HOME/.deno"
  fish_add_path "$DENO_INSTALL/bin"
end

# ==========================================
# Muscle-Memory Parity Aliases
# ==========================================
if command -v bat >/dev/null 2>&1
  alias cat="bat --theme=ansi"
end
if command -v lazygit >/dev/null 2>&1
  alias lg="lazygit"
end
if command -v lazydocker >/dev/null 2>&1
  alias ld="lazydocker"
end

# Standard shortcuts
alias ll="ls -alF"
alias la="ls -A"
alias l="ls -CF"

# ==========================================
# Modern CLI Tool Initializers
# ==========================================

# Zoxide smart navigation
if command -v zoxide >/dev/null 2>&1
  zoxide init fish | source
  alias cd=z
end

# Atuin shell history
if command -v atuin >/dev/null 2>&1
  atuin init fish | source
end

# Starship Prompt initialization
if command -v starship >/dev/null 2>&1
  starship init fish | source
end
