set shell := ["nu", "-c"]

# Sync all configurations to the system using GNU Stow packages
link:
    stow -R common --verbose
    if (sys host | get hostname) == "joshs-cachy-box" { \
        stow -R desktop --verbose \
    }

# Unlink configurations from the system safely
unlink:
    stow -D common --verbose
    if (sys host | get hostname) == "joshs-cachy-box" { \
        stow -D desktop --verbose \
    }

# Preview link changes (dry-run)
diff:
    stow -n -v -R common
    if (sys host | get hostname) == "joshs-cachy-box" { \
        stow -n -v -R desktop \
    }

# Install external package dependencies (like Yazi plugins/flavors)
install:
    ya pkg install

# Run static syntax validation and path parity tests across all shell configurations
check:
    print "=== Validating Bash ==="
    bash -n common/.bashrc
    print "✓ Bash syntax OK"
    
    print "=== Validating Zsh ==="
    zsh -n common/.zshrc
    print "✓ Zsh syntax OK"
    
    print "=== Validating Nushell ==="
    glob common/.config/nushell/**/*.nu | each { |file| \
        nu --ide-check 10 $file \
    }
    print "✓ Nushell syntax OK"
    
    print "=== Validating Fish ==="
    if (which fish | is-empty) == false { \
        fish -n common/.config/fish/config.fish; \
        print "✓ Fish syntax OK" \
    } else { \
        print "⚠ Fish is not installed on host. Static check skipped." \
    }
    
    print "=== Validating PATH Parity ==="
    nu --config common/.config/nushell/config.nu --env-config common/.config/nushell/env.nu tests/verify_paths.nu
