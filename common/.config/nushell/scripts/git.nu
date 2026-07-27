# git.nu
# Custom Nushell subcommands for Git operations.

use misc.nu nu-fail

# -----------------------------------------------------------------------------
# Autocomplete Definitions
# -----------------------------------------------------------------------------

# Pulls all local and remote branches for autocomplete
def "nu-complete git branches" [] {
    let local = (^git branch --format='%(refname:short)' | lines)
    let remote = (
        ^git branch -r --format='%(refname:short)'
        | lines
        | str replace -r '^[a-zA-Z0-9_-]+/' ''
    )

    $local | append $remote | uniq
}

# -----------------------------------------------------------------------------
# Branch Creation & Synchronization
# -----------------------------------------------------------------------------

# Creates a new feature branch safely from a specified base branch.
export def "git feature" [
    name: string,                                            # The name of the new branch (will be prefixed with feature/)
    --base (-b): string@"nu-complete git branches" = "main"  # The base branch to branch off of
] {
    let is_clean = (^git status --porcelain | is-empty)
    if not $is_clean {
        nu-fail "Working tree is dirty. Stash or commit your changes before branching."
        return
    }

    print $"Fetching origin to ensure base '($base)' is strictly up-to-date..."
    ^git fetch origin

    let target_branch = $"feature/($name)"
    let base_exists_locally = (^git branch --format='%(refname:short)' | lines | any {|it| $it == $base})

    if $base_exists_locally {
        ^git checkout $base
        ^git pull --ff-only origin $base
    } else {
        ^git checkout -t $"origin/($base)"
    }

    print $"Creating and checking out ($target_branch)..."
    ^git checkout -b $target_branch
}

# Rebases the current branch onto the latest remote base branch
export def "git catchup" [
    --base (-b): string@"nu-complete git branches" = "main"
] {
    let is_clean = (^git status --porcelain | is-empty)
    if not $is_clean {
        nu-fail "Working tree is dirty. Cannot safely rebase. Stash your changes."
        return
    }

    let current_branch = (^git branch --show-current | str trim)
    if ($current_branch | is-empty) {
        nu-fail "Not currently on any branch."
        return
    }

    print $"Fetching latest '($base)' from origin..."
    ^git fetch origin $base

    print $"Rebasing '($current_branch)' onto origin/($base)..."
    ^git rebase $"origin/($base)"
}

# Pushes the current branch and automatically sets the upstream tracking branch
export def "git publish" [] {
    let current_branch = (^git branch --show-current | str trim)
    if ($current_branch | is-empty) {
        nu-fail "Not currently on any branch."
        return
    }

    print $"Pushing to origin and setting upstream for '($current_branch)'..."
    ^git push -u origin $current_branch
}

# -----------------------------------------------------------------------------
# History & Modification
# -----------------------------------------------------------------------------

# Returns the git commit history as a queryable Nushell table.
export def "git history" [
    --limit (-l): int = 20  # Number of commits to fetch
] {
    let sep = "␟"
    let format = $"%h($sep)%an($sep)%ad($sep)%s"

    ^git log -n $limit --format=$format --date=short
    | lines
    | parse $"{{hash}}($sep){{author}}($sep){{date}}($sep){{message}}"
}

# Soft-resets the last commit, leaving changes staged.
export def "git uncommit" [] {
    let has_commits = (^git log -1 --oneline | is-empty) == false
    if not $has_commits {
        nu-fail "No commits to undo."
        return
    }

    print "Undoing last commit (changes remain in staging)..."
    ^git reset --soft HEAD~1
    ^git status -s
}

# -----------------------------------------------------------------------------
# Cleanup & Destructive Operations
# -----------------------------------------------------------------------------

# Deletes local branches that have been merged into the current HEAD.
export def "git clean-merged" [] {
    let protected_branches = ["main", "master", "dev", "develop"]

    let merged_branches = (
        ^git branch --merged
        | lines
        | str trim
        | where { |b| not ($b | str starts-with "*") }
        | where { |b| $b not-in $protected_branches }
    )

    if ($merged_branches | is-empty) {
        print "No merged branches to clean up."
        return
    }

    print $"\n(ansi yellow)The following merged branches are queued for deletion:(ansi reset)"
    $merged_branches | each { |b| print $"  - ($b)" }
    print ""

    let confirmation = (input "Do you want to delete these branches? [y/N]: " | into string | str trim)

    if ($confirmation | str lowercase) != "y" {
        print "Aborted. No branches were deleted."
        return
    }

    print "\nCleaning up..."
    $merged_branches | each { |b| ^git branch -d $b | ignore }
    print $"(ansi green)Cleanup complete.(ansi reset)"
}

# Deletes local branches whose remote tracking branch no longer exists.
export def "git gone" [] {
    print "Fetching latest from origin and pruning stale references..."
    ^git fetch -p

    let gone_branches = (
        ^git for-each-ref --format '%(refname:short) %(upstream:track)' refs/heads
        | lines
        | where ($it | str contains "[gone]")
        | parse "{branch} [gone]"
        | get branch
    )

    if ($gone_branches | is-empty) {
        print "No local branches with missing remotes found."
        return
    }

    print $"\n(ansi yellow)The following branches have been deleted on the remote:(ansi reset)"
    $gone_branches | each { |b| print $"  - ($b)" }
    print ""
    print "(ansi red)Note: This uses a force-delete (-D) because the upstream is missing.(ansi reset)"

    let confirmation = (input "Do you want to FORCE DELETE these local branches? [y/N]: " | into string | str trim)

    if ($confirmation | str lowercase) != "y" {
        print "Aborted. No branches were deleted."
        return
    }

    print "\nCleaning up 'gone' branches..."
    $gone_branches | each { |b| ^git branch -D $b | ignore }
    print $"(ansi green)Cleanup complete.(ansi reset)"
}

# Destructively resets the current branch to match origin, wiping all untracked files and local commits.
export def "git nuke" [] {
    let current_branch = (^git branch --show-current | str trim)
    if ($current_branch | is-empty) {
        nu-fail "Not currently on any branch."
        return
    }

    print $"Fetching latest state for origin/($current_branch)..."
    try {
        ^git fetch origin $current_branch | ignore
    } catch {
        nu-fail $"No upstream branch found for ($current_branch) on origin."
        return
    }

    let untracked_or_modified = (^git status --porcelain | lines)
    let commits_to_drop = (^git log $"origin/($current_branch)..HEAD" --oneline | lines)

    if ($untracked_or_modified | is-empty) and ($commits_to_drop | is-empty) {
        print "Branch is perfectly aligned with origin. Nothing to destroy."
        return
    }

    print $"\n(ansi red_bold)⚠️  WARNING: DESTRUCTIVE ACTION ⚠️(ansi reset)"
    print "The following will be PERMANENTLY LOST:\n"

    if not ($commits_to_drop | is-empty) {
        print $"(ansi yellow)Local commits to be dropped:(ansi reset)"
        $commits_to_drop | each {|c| print $"  ($c)" }
        print ""
    }

    if not ($untracked_or_modified | is-empty) {
        print $"(ansi yellow)Uncommitted changes/untracked files to be wiped:(ansi reset)"
        $untracked_or_modified | each {|f| print $"  ($f)" }
        print ""
    }

    let confirmation = (input "Are you absolutely sure you want to nuke these changes? [y/N]: " | into string | str trim)

    if ($confirmation | str lowercase) != "y" {
        print "Aborted. Your working tree is safe."
        return
    }

    print "\nNuking..."
    ^git reset --hard $"origin/($current_branch)" | ignore
    ^git clean -fd | ignore
    print $"(ansi green)Branch reset complete.(ansi reset)"
}
