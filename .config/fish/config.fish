# Disable the default welcoming greeting
set -g fish_greeting ""

# Source CachyOS fish config if present
if test -f /usr/share/cachyos-fish-config/cachyos-config.fish
  source /usr/share/cachyos-fish-config/cachyos-config.fish
end


# ==========================================
# Environment Variables & Path Extensions
# ==========================================
fish_add_path "$HOME/.local/bin"
fish_add_path "$HOME/.cargo/bin"
fish_add_path "$HOME/.local/share/fnm"
fish_add_path "/opt/mssql-tools18/bin"
fish_add_path "$HOME/.bun/bin"
fish_add_path "$HOME/.opencode/bin"

# Hardware rendering & WebKit workarounds
set -Ux WEBKIT_DISABLE_DMABUF_RENDERER 1
set -Ux LIBGL_ALWAYS_SOFTWARE 1
set -Ux QT_XCB_FORCE_SOFTWARE_OPENGL 1

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

# Thefuck alias generator
if command -v thefuck >/dev/null 2>&1
  thefuck --alias | source
end

# ==========================================
# Custom Functions & Logging
# ==========================================

function ssh-log --description "SSH with local session logging"
  # 1. Define log file location
  set -l log_dir "$HOME/Syncthing/ActivityLogs/ssh_sessions"
  mkdir -p $log_dir
  set -l timestamp (date "+%Y-%m-%d_%H-%M-%S")
  
  # Extract the hostname from arguments for a better filename
  # (This is a simplified extraction, takes the last arg usually)
  set -l remote_host $argv[-1] 
  set -l log_file "$log_dir/ssh_$remote_host_$timestamp.log"

  echo "🔴 [Logging SSH session to $log_file]"

  # 2. Use `script` to record the session
  script -q -c "/usr/bin/ssh $argv" $log_file

  perl -i -pe 's/\e\[?.*?[\@-~]//g; s/\e\].*?\a//g' $log_file
end

function log_command --on-event fish_postexec
  set -l cmd $argv[1]
  set -l log_file "$HOME/Syncthing/ActivityLogs/commands_cachyos.log"
  set -l timestamp (date "+%Y-%m-%d %H:%M:%S")
  set -l current_dir (pwd)

  # --- PRIVACY FILTER ---
  if string match -q -r "password|token|key" $cmd
    return
  end
  
  # Don't log simple commands (optional)
  if string match -q -r "(ls|cd|clear|exit|git status|mkdir|cat)" $cmd
    return
  end

  echo "$timestamp | $current_dir | $cmd" >> $log_file
end

# Source local/private configurations if present (not tracked by git)
if test -f ~/.config/fish/config.local.fish
  source ~/.config/fish/config.local.fish
end
