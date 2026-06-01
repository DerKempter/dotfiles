# Dotfiles workspace automation tasks

# Sync all configurations to the system using GNU Stow
link:
    stow . --verbose

# Unlink configurations from the system safely
unlink:
    stow -D . --verbose
