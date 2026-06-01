# Dotfiles workspace automation tasks

# Sync all configurations to the system using GNU Stow
link:
    stow . --verbose

# Unlink configurations from the system safely
unlink:
    stow -D . --verbose

# Adopt existing system configurations into the dotfiles repository (careful: commits must be clean)
adopt:
    stow --adopt . --verbose

# Force link configurations by adopting conflicts and then restoring repository tracked files
force-link: adopt
    git restore .

# Install external package dependencies (like Yazi plugins/flavors)
install:
    ya pkg install
