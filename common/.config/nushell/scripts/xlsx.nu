# Helper: Transliterate and sanitize a sheet name for clean filesystem usage
def sanitize-sheet-name [name: string] {
    $name
    | str replace --all " & " "_and_"
    | str replace --all " / " "_"
    | str replace --all " " "_"
    | str replace --all "/" "_"
    | str replace --all "ä" "ae"
    | str replace --all "ö" "oe"
    | str replace --all "ü" "ue"
    | str replace --all "Ä" "Ae"
    | str replace --all "Ö" "Oe"
    | str replace --all "Ü" "Ue"
    | str replace --all "ß" "ss"
    | str replace --regex '[^a-zA-Z0-9_\-]' ""
    | str replace --regex '_+' "_"
    | str trim --char "_"
}

# Helper: Convert whole float values (e.g. 55218.0) to integers (55218) across a table
def clean-table-numbers [] {
    let input = $in
    if ($input | is-empty) { return $input }

    $input | each { |row|
        $row | items { |k, v|
            let cleaned_v = if ($v | describe) =~ "^float" {
                if ($v mod 1 == 0) {
                    $v | into int
                } else {
                    $v
                }
            } else {
                $v
            }
            [ $k $cleaned_v ]
        } | into record
    }
}

# Helper: Filter out ghost/blank rows where all cells are empty or null
def drop-empty-rows [] {
    let input = $in
    if ($input | is-empty) { return $input }

    $input | where { |row|
        $row | values | any { |val|
            ($val | is-not-empty) and (($val | describe) != "nothing") and (($val | into string | str trim) != "")
        }
    }
}

# Helper: Resolve input argument/pipeline to a list of .xlsx file paths (supporting directories & globs)
def resolve-xlsx-files [input_source: any] {
    if ($input_source | is-empty) {
        error make {
            msg: "No input file or directory provided. Specify an argument or pipe paths into the command."
        }
    }

    let raw_list = if ($input_source | describe) =~ "^list" {
        $input_source
    } else {
        [ $input_source ]
    }

    $raw_list | each { |item|
        if not ($item | path exists) {
            error make {
                msg: $"File or directory not found: ($item)"
            }
        }

        let expanded = ($item | path expand)
        if ($expanded | path type) == "dir" {
            let found = (glob ($expanded | path join "*.xlsx") | sort)
            if ($found | is-empty) {
                error make {
                    msg: $"No .xlsx files found in directory: ($item)"
                }
            }
            $found
        } else {
            [ $expanded ]
        }
    } | flatten
}

# Inspect sheet names, columns, and row counts of an Excel workbook without exporting.
# Accepts a file, directory, or list of paths.
# If multiple files are inspected, a 'workbook' column is included to differentiate sources.
export def "xlsx sheets" [
    file?: path # Path to .xlsx workbook or directory (optional if piped)
] {
    let input_source = if ($file | is-not-empty) { $file } else { $in }
    let files = (resolve-xlsx-files $input_source)
    let is_multi = ($files | length) > 1

    $files | each { |resolved|
        let raw_sheets = (open $resolved | transpose sheet rows)

        $raw_sheets | each { |item|
            let cols = if ($item.rows | is-empty) { [] } else { $item.rows | first | columns }
            if $is_multi {
                {
                    workbook: ($resolved | path relative-to (pwd)),
                    sheet: $item.sheet,
                    sanitized_name: (sanitize-sheet-name $item.sheet),
                    columns: $cols,
                    rows: ($item.rows | length)
                }
            } else {
                {
                    sheet: $item.sheet,
                    sanitized_name: (sanitize-sheet-name $item.sheet),
                    columns: $cols,
                    rows: ($item.rows | length)
                }
            }
        }
    } | flatten
}

# Converts worksheets from Excel (.xlsx) file(s) or directory into separate delimiter-separated CSV files.
#
# Defaults:
# - Delimiter: '|' (pipe)
# - Float sanitization: on (55218.0 -> 55218)
# - Empty row dropping: on
#
# Returns a table containing execution results for each processed sheet.
export def "xlsx to-csv" [
    file?: path                 # Path to source .xlsx file or directory (optional if piped)
    --out-dir (-o): path        # Target directory for exported CSVs (default: input file directory)
    --sheets (-s): list<string> # Optional list of specific sheet names to export
    --prefix (-p): string = ""  # Optional prefix for output filenames
    --delimiter (-d): string = "|" # Field separator (default: '|')
    --force (-f)                # Overwrite existing CSV files if they already exist
    --no-clean-numbers          # Disable automatic float-to-integer conversion for whole numbers
    --keep-empty-rows           # Keep ghost/blank rows instead of dropping them
    --dry-run                   # Simulate export without creating files
] {
    let input_source = if ($file | is-not-empty) { $file } else { $in }
    let files = (resolve-xlsx-files $input_source)
    let is_multi = ($files | length) > 1

    $files | each { |resolved_file|
        let parent_dir = ($resolved_file | path dirname)
        let target_dir = if ($out_dir | is-empty) {
            $parent_dir
        } else {
            $out_dir | path expand
        }

        if (not $dry_run) and (not ($target_dir | path exists)) {
            mkdir $target_dir
        }

        # Open Excel file into a record of tables and transpose to {sheet, rows}
        let raw_sheets = (open $resolved_file | transpose sheet rows)

        # Filter sheets if requested
        let selected_sheets = if ($sheets | is-empty) {
            $raw_sheets
        } else {
            $raw_sheets | where ($it.sheet in $sheets)
        }

        let wb_stem = ($resolved_file | path parse | get stem)

        $selected_sheets | each { |item|
            let sheet_name = $item.sheet
            mut rows = $item.rows

            # Drop empty ghost rows unless requested otherwise
            if not $keep_empty_rows {
                $rows = ($rows | drop-empty-rows)
            }

            # Convert 55218.0 -> 55218 unless --no-clean-numbers is passed
            if not $no_clean_numbers {
                $rows = ($rows | clean-table-numbers)
            }

            let clean_name = (sanitize-sheet-name $sheet_name)

            let out_filename = if $is_multi {
                if ($prefix | is-empty) {
                    $"($wb_stem)_($clean_name).csv"
                } else {
                    $"($prefix)_($wb_stem)_($clean_name).csv"
                }
            } else {
                if ($prefix | is-empty) {
                    $"($clean_name).csv"
                } else {
                    $"($prefix)_($clean_name).csv"
                }
            }

            let out_path = ($target_dir | path join $out_filename)

            let status_msg = if $dry_run {
                "dry-run (simulation)"
            } else if ($out_path | path exists) and (not $force) {
                "skipped (file exists, use --force)"
            } else {
                $rows | to csv --separator $delimiter | save -f $out_path
                "exported"
            }

            if $is_multi {
                {
                    workbook: ($resolved_file | path relative-to (pwd)),
                    sheet: $sheet_name,
                    file: ($out_path | path relative-to (pwd)),
                    rows: ($rows | length),
                    status: $status_msg
                }
            } else {
                {
                    sheet: $sheet_name,
                    file: ($out_path | path relative-to (pwd)),
                    rows: ($rows | length),
                    status: $status_msg
                }
            }
        }
    } | flatten
}
