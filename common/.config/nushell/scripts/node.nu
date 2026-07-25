def "nu-complete npm" [] {
  let cache_file = ($nu.data-dir | path join "npm_completions.json")
  if ($cache_file | path exists) {
    open $cache_file
  } else {
    try {
      let npm_commanders = ^npm -l
        | lines
        | where $it =~ '\s{4}[a-z\-]+.*\s{4,}'
        | parse -r '\s*(?P<value>[^ ]+)\s*(?P<description>\w.*)'
      $npm_commanders | save -f $cache_file
      $npm_commanders
    } catch {
      []
    }
  }
}

export extern "npm" [
  command?: string@"nu-complete npm"
]

export def "nu-complete npm scripts" [] {
    open package.json | get scripts | transpose | rename value description
}

export extern "npm run" [
    script: string@"nu-complete npm scripts" # Suggests scripts from YOUR package.json
]

# Update active Node.js version using fnm
export def node-update [
    --latest (-l) # Use the general latest Node version instead of the LTS version
] {
    let target = if $latest { "latest" } else { "lts-latest" }
    print $"(ansi green)Updating Node.js to ($target)...(ansi reset)"
    fnm install $target
    fnm use $target
}
