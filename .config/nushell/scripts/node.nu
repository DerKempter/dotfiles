def "nu-complete npm" [] {
  let db = stor open

  try {
    # query commanders from in-mem db
    $db | query db "SELECT * FROM npm_commanders_table"
  } catch {
    # if catched error, create table and insert all data
    stor create --table-name npm_commanders_table --columns { value: str, description: str }

    let npm_commanders = ^npm -l
      | lines
      | where $it =~ '\s{4}[a-z\-]+.*\s{4,}'
      | parse -r '\s*(?P<value>[^ ]+)\s*(?P<description>\w.*)'

    $npm_commanders | stor insert --table-name npm_commanders_table

    $npm_commanders
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
