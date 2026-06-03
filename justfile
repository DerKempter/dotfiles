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

# Run static syntax validation and path parity tests across all shell configurations
check:
    @echo "=== Validating Bash ==="
    bash -n .bashrc && echo "✓ Bash syntax OK"
    @echo "=== Validating Zsh ==="
    zsh -n .zshrc && echo "✓ Zsh syntax OK"
    @echo "=== Validating Nushell ==="
    @find .config/nushell -name "*.nu" -type f -exec sh -c 'nu --ide-check 10 "{}" > /dev/null || (echo "✗ Syntax error in {}" && exit 1)' \;
    @echo "✓ Nushell syntax OK"
    @echo "=== Validating Fish ==="
    @if command -v fish >/dev/null 2>&1; then \
        fish -n .config/fish/config.fish && echo "✓ Fish syntax OK"; \
    else \
        echo "⚠ Fish is not installed on host. Static check skipped."; \
    fi
    @echo "=== Validating PATH Parity ==="
    nu --config .config/nushell/config.nu --env-config .config/nushell/env.nu tests/verify_paths.nu
