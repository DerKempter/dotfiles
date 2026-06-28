# Dotfiles workspace automation tasks

# Sync all configurations to the system using the 'store' dotfile manager
link:
    store apply

# Preview link changes (dry-run)
diff:
    store diff

# Check configuration health, broken links, and missing secrets
doctor:
    store doctor

# Unlink configurations from the system safely (Legacy recipe for GNU Stow cleanup)
unlink-stow:
    stow -D . --verbose


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
