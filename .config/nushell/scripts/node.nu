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
