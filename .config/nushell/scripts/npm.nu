export def "nu-complete npm scripts" [] {
    open package.json | get scripts | transpose name command | get name
}

export extern "npm run" [
    script: string@"nu-complete npm scripts" # Suggests scripts from YOUR package.json
]
