# =============================================================================
# AI Assistant & Rules Management Utilities
# =============================================================================

# Helper: Inspect path metadata natively in Nushell (supports broken symlinks)
def get-path-type [p: string] {
    let parent = match ($p | path dirname) {
        "" => ".",
        $dir => $dir
    }

    if not ($parent | path exists) { return "missing" }

    let target_name = ($p | path basename)
    let matches = (try {
        ls -a $parent | where { ($in.name | path basename) == $target_name }
    } catch { [] })

    if ($matches | is-empty) {
        "missing"
    } else {
        $matches | first | get type
    }
}

# Symlinks global AI instructions (~/.gemini/GEMINI.md) into JetBrains AI Assistant rules
# (.aiassistant/rules/global-instructions.md) at the Git repository root.
# Automatically adds the global rule to local git exclude so it is never committed.
export def "ai link-rules" [
    target_repo: path = "." # Target repository path (defaults to current directory)
    --track                 # Do not add .aiassistant/rules/global-instructions.md to git exclude
    --force (-f)            # Force overwrite existing rules without preserving them
] {
    let target_dir = ($target_repo | path expand)
    let repo_root = (try { ^git -C $target_dir rev-parse --show-toplevel | str trim } catch { "" })
    if ($repo_root | is-empty) {
        error make { msg: $"Directory is not inside a git repository: ($target_dir)" }
    }

    let source_file = ($env.HOME | path join ".gemini" "GEMINI.md")
    if (get-path-type $source_file) == "missing" {
        error make { msg: $"Global instructions file not found at: ($source_file)" }
    }

    let rules_dir = ($repo_root | path join ".aiassistant" "rules")
    let target_file = ($rules_dir | path join "global-instructions.md")

    if not ($rules_dir | path exists) {
        mkdir $rules_dir
    }

    let target_type = (get-path-type $target_file)

    # Handle existing target file or symlink
    if $target_type != "missing" {
        if $target_type == "symlink" {
            let current_target = (try { ^readlink -f $target_file | str trim } catch { "" })
            let desired_target = ($source_file | path expand)

            if ($current_target == $desired_target) and ($desired_target | is-not-empty) {
                print $"(ansi green)✓ AI Assistant rules are already linked:(ansi reset)"
                print $"  ($target_file) -> ($source_file)"
                return
            }
            # Broken or pointing elsewhere symlink: remove cleanly
            rm -f $target_file
        } else {
            # Regular local file exists
            if not $force {
                let backup_file = ($rules_dir | path join "project-instructions.md")
                if (get-path-type $backup_file) == "missing" {
                    mv $target_file $backup_file
                    print $"(ansi yellow)ℹ Existing global-instructions.md moved to ($backup_file) to preserve local rules.(ansi reset)"
                } else {
                    let timestamp = (date now | format date "%Y%m%d_%H%M%S")
                    let timestamped_backup = ($rules_dir | path join $"project-instructions_($timestamp).md")
                    mv $target_file $timestamped_backup
                    print $"(ansi yellow)ℹ Existing global-instructions.md moved to ($timestamped_backup) to preserve local rules.(ansi reset)"
                }
            } else {
                rm -f $target_file
            }
        }
    }

    # Create the symlink
    ^ln -sf $source_file $target_file

    # Prevent git tracking of only the global rule symlink via git exclude (worktree/submodule safe)
    if not $track {
        let rel_exclude_path = (try { ^git -C $repo_root rev-parse --git-path info/exclude | str trim } catch { "" })
        let is_abs = ($rel_exclude_path | str starts-with "/") or ($rel_exclude_path | str contains ":")
        let exclude_file = if $is_abs {
            $rel_exclude_path
        } else {
            ($repo_root | path join $rel_exclude_path)
        }

        let exclude_dir = ($exclude_file | path dirname)
        if not ($exclude_dir | path exists) {
            mkdir $exclude_dir
        }
        if not ($exclude_file | path exists) {
            "" | save -f $exclude_file
        }

        let content = (open $exclude_file --raw)
        let exclude_pattern = ".aiassistant/rules/global-instructions.md"
        if not ($content | str contains $exclude_pattern) {
            $"\n# JetBrains AI Assistant global rules link\n($exclude_pattern)\n" | save --append $exclude_file
        }
    }

    print $"(ansi green_bold)✓ Successfully linked AI Assistant instructions:(ansi reset)"
    print $"  ($target_file) -> ($source_file)"
    if not $track {
        print $"  (ansi dark_gray)Added .aiassistant/rules/global-instructions.md to local git exclude [untracked](ansi reset)"
    }
}
