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

# Force link configurations by adopting conflicts and then restoring repository tracked files (safeguarded against uncommitted changes)
force-link:
    @git diff --quiet || (echo "Error: You have uncommitted changes in your dotfiles repository. Commit or stash them first!" && exit 1)
    just adopt
    git restore .

# Install external package dependencies (like Yazi plugins/flavors)
install:
    ya pkg install
