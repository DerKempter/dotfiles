# =============================================================================
# Tabular & Structured Data Conversion Toolkit (CSV, XLSX, JSON, TSV)
# =============================================================================

# Helper: Format path for clean display (relative if inside cwd, otherwise absolute)
def format-display-path [p: string] {
    try {
        $p | path relative-to (pwd)
    } catch {
        $p
    }
}

# Helper: Transliterate and sanitize a sheet name for clean filesystem / Excel usage
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

# Helper: Convert whole float values (e.g. 55218.0) to integers (55218) across a table or nested record
def clean-table-numbers [] {
    let input = $in
    if ($input | is-empty) { return $input }

    if ($input | describe) =~ "^table" or ($input | describe) =~ "^list" {
        $input | each { |row|
            if ($row | describe) =~ "^record" {
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
            } else {
                $row
            }
        }
    } else if ($input | describe) =~ "^record" {
        $input | items { |k, v|
            [ $k ($v | clean-table-numbers) ]
        } | into record
    } else {
        $input
    }
}

# Helper: Filter out ghost/blank rows where all cells are empty or null
def drop-empty-rows [] {
    let input = $in
    if ($input | is-empty) { return $input }

    $input | where { |row|
        if ($row | describe) =~ "^record" {
            $row | values | any { |val|
                ($val | is-not-empty) and (($val | describe) != "nothing") and (($val | into string | str trim) != "")
            }
        } else {
            true
        }
    }
}

# Helper: Resolve input argument/pipeline to a list of files matching supported extensions
def resolve-input-files [input_source: any, extensions: list<string> = ["xlsx", "csv", "json", "tsv"]] {
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
            let matches = ($extensions | each { |ext|
                glob ($expanded | path join $"*.($ext)")
            } | flatten | sort)

            if ($matches | is-empty) {
                error make {
                    msg: $"No matching files with extensions [($extensions | str join ', ')] found in directory: ($item)"
                }
            }
            $matches
        } else {
            [ $expanded ]
        }
    } | flatten
}

# Helper: Write structured data (record of tables or list of records) into an .xlsx workbook using openpyxl via uv
def write-xlsx-file [data: any, out_path: string] {
    let parent_dir = ($out_path | path dirname)
    if not ($parent_dir | path exists) {
        mkdir $parent_dir
    }

    let py_script = '
import json, sys
from openpyxl import Workbook

raw = json.loads(sys.stdin.read())
out_path = sys.argv[1]

wb = Workbook()
wb.remove(wb.active)

sheets = []
if isinstance(raw, list):
    sheets.append(("Sheet1", raw))
elif isinstance(raw, dict):
    for k, v in raw.items():
        if isinstance(v, list):
            sheets.append((k, v))
        else:
            sheets.append((k, [v]))

for sheet_title, rows in sheets:
    ws = wb.create_sheet(title=sheet_title[:31])
    if not rows:
        continue
    if isinstance(rows[0], dict):
        headers = list(rows[0].keys())
        ws.append(headers)
        for r in rows:
            ws.append([r.get(h) for h in headers])
    elif isinstance(rows[0], list):
        for r in rows:
            ws.append(r)
    else:
        for r in rows:
            ws.append([r])

wb.save(out_path)
'
    $data | to json --raw | ^uv run --with openpyxl python3 -c $py_script ($out_path | path expand)
}

# Helper: Read CSV with flexible delimiter fallback
def open-csv-flexible [file_path: string, delimiter?: string] {
    if ($delimiter | is-not-empty) {
        open $file_path --raw | from csv --separator $delimiter
    } else {
        # Check first line for auto-detection between ',', ';', '|', '\t'
        let sample = (open $file_path --raw | lines | first 2 | str join "\n")
        let sep = if ($sample | str contains "|") and not ($sample | str contains ",") {
            "|"
        } else if ($sample | str contains ";") and not ($sample | str contains ",") {
            ";"
        } else if ($sample | str contains "\t") and not ($sample | str contains ",") {
            "\t"
        } else {
            ","
        }
        open $file_path --raw | from csv --separator $sep
    }
}

# =============================================================================
# Inspection Commands
# =============================================================================

# Inspect sheet names, columns, and row counts of an Excel workbook without exporting.
# Accepts a file, directory, or list of paths.
export def "data sheets" [
    file?: path # Path to .xlsx workbook or directory (optional if piped)
] {
    let input_source = if ($file | is-not-empty) { $file } else { $in }
    let files = (resolve-input-files $input_source ["xlsx"])
    let is_multi = ($files | length) > 1

    $files | each { |resolved|
        let raw_sheets = (open $resolved | transpose sheet rows)

        $raw_sheets | each { |item|
            let cols = if ($item.rows | is-empty) { [] } else { $item.rows | first | columns }
            if $is_multi {
                {
                    workbook: (format-display-path $resolved),
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

# Alias for backwards compatibility
export def "xlsx sheets" [file?: path] {
    data sheets $file
}

# =============================================================================
# Export to CSV / TSV
# =============================================================================

# Converts worksheets from Excel (.xlsx) or JSON file(s) into delimiter-separated CSV files.
export def "data to-csv" [
    file?: path                 # Path to source .xlsx / .json file or directory (optional if piped)
    --out-dir (-o): path        # Target directory or output file path (default: input file directory)
    --sheets (-s): list<string> # Optional list of specific sheet names to export (for xlsx)
    --prefix (-p): string = ""  # Optional prefix for output filenames
    --delimiter (-d): string = "|" # Field separator (default: '|')
    --force (-f)                # Overwrite existing CSV files if they already exist
    --no-clean-numbers          # Disable automatic float-to-integer conversion for whole numbers
    --keep-empty-rows           # Keep ghost/blank rows instead of dropping them
    --dry-run                   # Simulate export without creating files
] {
    let input_source = if ($file | is-not-empty) { $file } else { $in }
    let files = (resolve-input-files $input_source ["xlsx", "json"])
    let is_multi = ($files | length) > 1

    $files | each { |resolved_file|
        let parent_dir = ($resolved_file | path dirname)
        let target_dir = if ($out_dir | is-empty) {
            $parent_dir
        } else {
            $out_dir | path expand
        }

        let is_target_file = ($target_dir | str ends-with ".csv")
        let effective_dir = if $is_target_file { ($target_dir | path dirname) } else { $target_dir }

        if (not $dry_run) and (not ($effective_dir | path exists)) {
            mkdir $effective_dir
        }

        let ext = ($resolved_file | path parse | get extension)
        let wb_stem = ($resolved_file | path parse | get stem)

        let sheets_data = if $ext == "xlsx" {
            let raw = (open $resolved_file | transpose sheet rows)
            if ($sheets | is-empty) {
                $raw
            } else {
                $raw | where ($it.sheet in $sheets)
            }
        } else {
            # JSON file
            let raw_json = (open $resolved_file)
            if ($raw_json | describe) =~ "^table" or ($raw_json | describe) =~ "^list" {
                [ { sheet: $wb_stem, rows: $raw_json } ]
            } else if ($raw_json | describe) =~ "^record" {
                $raw_json | transpose sheet rows
            } else {
                error make { msg: $"Unsupported JSON structure in ($resolved_file). Expected array or object of arrays." }
            }
        }

        $sheets_data | each { |item|
            let sheet_name = $item.sheet
            mut rows = $item.rows

            if not $keep_empty_rows {
                $rows = ($rows | drop-empty-rows)
            }

            if not $no_clean_numbers {
                $rows = ($rows | clean-table-numbers)
            }

            let clean_name = (sanitize-sheet-name $sheet_name)

            let out_path = if $is_target_file and not $is_multi and (($sheets_data | length) == 1) {
                $target_dir
            } else {
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
                ($effective_dir | path join $out_filename)
            }

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
                    source: (format-display-path $resolved_file),
                    sheet: $sheet_name,
                    file: (format-display-path $out_path),
                    rows: ($rows | length),
                    status: $status_msg
                }
            } else {
                {
                    sheet: $sheet_name,
                    file: (format-display-path $out_path),
                    rows: ($rows | length),
                    status: $status_msg
                }
            }
        }
    } | flatten
}

# Aliases for backwards compatibility & quick access
export def "xlsx to-csv" [
    file?: path
    --out-dir (-o): path
    --sheets (-s): list<string>
    --prefix (-p): string = ""
    --delimiter (-d): string = "|"
    --force (-f)
    --no-clean-numbers
    --keep-empty-rows
    --dry-run
] {
    data to-csv $file -o $out_dir -s $sheets -p $prefix -d $delimiter --force=$force --no-clean-numbers=$no_clean_numbers --keep-empty-rows=$keep_empty_rows --dry-run=$dry_run
}

export def "json to-csv" [
    file?: path
    --out-dir (-o): path
    --delimiter (-d): string = ","
    --force (-f)
    --dry-run
] {
    data to-csv $file -o $out_dir -d $delimiter --force=$force --dry-run=$dry_run
}

# =============================================================================
# Export to JSON
# =============================================================================

# Converts Excel (.xlsx) or CSV/TSV file(s) into clean structured JSON.
export def "data to-json" [
    file?: path                 # Path to source .xlsx / .csv file or directory (optional if piped)
    --out-dir (-o): path        # Target directory or output .json file path (default: input file directory)
    --combined (-c)             # Combine all sheets into a single JSON object { "SheetName": [...] }
    --sheets (-s): list<string> # Optional list of specific sheet names to export (for xlsx)
    --delimiter (-d): string    # Delimiter for CSV source (auto-detected if omitted)
    --indent (-i): int = 2      # JSON indentation (default: 2, use 0 for minified)
    --force (-f)                # Overwrite existing JSON files if they already exist
    --no-clean-numbers          # Disable automatic float-to-integer conversion for whole numbers
    --keep-empty-rows           # Keep ghost/blank rows instead of dropping them
    --dry-run                   # Simulate export without creating files
] {
    let input_source = if ($file | is-not-empty) { $file } else { $in }
    let files = (resolve-input-files $input_source ["xlsx", "csv", "tsv"])
    let is_multi = ($files | length) > 1

    $files | each { |resolved_file|
        let parent_dir = ($resolved_file | path dirname)
        let target_dir = if ($out_dir | is-empty) {
            $parent_dir
        } else {
            $out_dir | path expand
        }

        let is_target_file = ($target_dir | str ends-with ".json")
        let effective_dir = if $is_target_file { ($target_dir | path dirname) } else { $target_dir }

        if (not $dry_run) and (not ($effective_dir | path exists)) {
            mkdir $effective_dir
        }

        let ext = ($resolved_file | path parse | get extension)
        let wb_stem = ($resolved_file | path parse | get stem)

        if $ext == "xlsx" {
            let raw_sheets = (open $resolved_file | transpose sheet rows)
            let selected_sheets = if ($sheets | is-empty) {
                $raw_sheets
            } else {
                $raw_sheets | where ($it.sheet in $sheets)
            }

            # If combined mode is requested or target is a single JSON file
            if $combined or ($is_target_file and not $is_multi) {
                mut combined_record = {}
                for item in $selected_sheets {
                    mut rows = $item.rows
                    if not $keep_empty_rows { $rows = ($rows | drop-empty-rows) }
                    if not $no_clean_numbers { $rows = ($rows | clean-table-numbers) }
                    $combined_record = ($combined_record | insert $item.sheet $rows)
                }

                let out_path = if $is_target_file { $target_dir } else { ($effective_dir | path join $"($wb_stem).json") }
                let status_msg = if $dry_run {
                    "dry-run (simulation)"
                } else if ($out_path | path exists) and (not $force) {
                    "skipped (file exists, use --force)"
                } else {
                    let json_str = if $indent > 0 { $combined_record | to json --indent $indent } else { $combined_record | to json --raw }
                    $json_str | save -f $out_path
                    "exported"
                }

                {
                    source: (format-display-path $resolved_file),
                    type: "combined_workbook",
                    file: (format-display-path $out_path),
                    sheets: ($selected_sheets | length),
                    status: $status_msg
                }
            } else {
                # Export each sheet to a separate .json file
                $selected_sheets | each { |item|
                    let sheet_name = $item.sheet
                    mut rows = $item.rows

                    if not $keep_empty_rows { $rows = ($rows | drop-empty-rows) }
                    if not $no_clean_numbers { $rows = ($rows | clean-table-numbers) }

                    let clean_name = (sanitize-sheet-name $sheet_name)
                    let out_filename = if $is_multi {
                        $"($wb_stem)_($clean_name).json"
                    } else {
                        $"($clean_name).json"
                    }
                    let out_path = ($effective_dir | path join $out_filename)

                    let status_msg = if $dry_run {
                        "dry-run (simulation)"
                    } else if ($out_path | path exists) and (not $force) {
                        "skipped (file exists, use --force)"
                    } else {
                        let json_str = if $indent > 0 { $rows | to json --indent $indent } else { $rows | to json --raw }
                        $json_str | save -f $out_path
                        "exported"
                    }

                    {
                        source: (format-display-path $resolved_file),
                        sheet: $sheet_name,
                        file: (format-display-path $out_path),
                        rows: ($rows | length),
                        status: $status_msg
                    }
                }
            }
        } else {
            # CSV or TSV file
            mut rows = (open-csv-flexible $resolved_file $delimiter)
            if not $keep_empty_rows { $rows = ($rows | drop-empty-rows) }
            if not $no_clean_numbers { $rows = ($rows | clean-table-numbers) }

            let out_path = if $is_target_file and not $is_multi {
                $target_dir
            } else {
                ($effective_dir | path join $"($wb_stem).json")
            }

            let status_msg = if $dry_run {
                "dry-run (simulation)"
            } else if ($out_path | path exists) and (not $force) {
                "skipped (file exists, use --force)"
            } else {
                let json_str = if $indent > 0 { $rows | to json --indent $indent } else { $rows | to json --raw }
                $json_str | save -f $out_path
                "exported"
            }

            {
                source: (format-display-path $resolved_file),
                file: (format-display-path $out_path),
                rows: ($rows | length),
                status: $status_msg
            }
        }
    } | flatten
}

# Aliases for convenience
export def "xlsx to-json" [
    file?: path
    --out-dir (-o): path
    --combined (-c)
    --sheets (-s): list<string>
    --indent (-i): int = 2
    --force (-f)
    --no-clean-numbers
    --keep-empty-rows
    --dry-run
] {
    data to-json $file -o $out_dir --combined=$combined -s $sheets -i $indent --force=$force --no-clean-numbers=$no_clean_numbers --keep-empty-rows=$keep_empty_rows --dry-run=$dry_run
}

export def "csv to-json" [
    file?: path
    --out-dir (-o): path
    --delimiter (-d): string
    --indent (-i): int = 2
    --force (-f)
    --no-clean-numbers
    --keep-empty-rows
    --dry-run
] {
    data to-json $file -o $out_dir -d $delimiter -i $indent --force=$force --no-clean-numbers=$no_clean_numbers --keep-empty-rows=$keep_empty_rows --dry-run=$dry_run
}

# =============================================================================
# Export to XLSX
# =============================================================================

# Converts CSV, TSV, or JSON file(s) into Excel (.xlsx) workbook(s).
# If multiple CSV files are provided or a directory is targeted with -c / --combine,
# they are merged as separate tabs inside a single Excel workbook!
export def "data to-xlsx" [
    file?: path                 # Path to source .csv, .json file or directory (optional if piped)
    --out-file (-o): path       # Target .xlsx output file or directory (default: same name with .xlsx)
    --sheet-name (-s): string   # Custom sheet name for single file export (default: file stem)
    --delimiter (-d): string    # Delimiter for CSV inputs (auto-detected if omitted)
    --combine (-c)              # Combine multiple input CSVs into a single multi-tab workbook
    --force (-f)                # Overwrite existing .xlsx file if it already exists
    --dry-run                   # Simulate creation without writing file
] {
    let input_source = if ($file | is-not-empty) { $file } else { $in }
    let files = (resolve-input-files $input_source ["csv", "tsv", "json"])
    let is_multi = ($files | length) > 1

    if $combine or ($is_multi and ($out_file | is-not-empty) and ($out_file | str ends-with ".xlsx")) {
        # Combine multiple input files into tabs of one workbook
        let out_path = if ($out_file | is-not-empty) {
            $out_file | path expand
        } else {
            let parent_dir = ($files | first | path dirname)
            ($parent_dir | path join "combined_data.xlsx")
        }

        if ($out_path | path exists) and (not $force) {
            error make { msg: $"Output file exists: ($out_path). Use --force (-f) to overwrite." }
        }

        mut workbook_record = {}
        for f in $files {
            let f_stem = ($f | path parse | get stem)
            let f_ext = ($f | path parse | get extension)
            let clean_tab = (sanitize-sheet-name $f_stem)

            if $f_ext == "json" {
                let json_data = (open $f)
                if ($json_data | describe) =~ "^table" or ($json_data | describe) =~ "^list" {
                    $workbook_record = ($workbook_record | insert $clean_tab $json_data)
                } else if ($json_data | describe) =~ "^record" {
                    for tab in ($json_data | transpose key val) {
                        $workbook_record = ($workbook_record | insert (sanitize-sheet-name $tab.key) $tab.val)
                    }
                }
            } else {
                let csv_rows = (open-csv-flexible $f $delimiter)
                $workbook_record = ($workbook_record | insert $clean_tab $csv_rows)
            }
        }

        if not $dry_run {
            write-xlsx-file $workbook_record $out_path
        }

        {
            file: (format-display-path $out_path),
            sheets: ($workbook_record | columns),
            status: (if $dry_run { "dry-run (simulation)" } else { "exported" })
        }
    } else {
        # Export each file individually
        $files | each { |resolved_file|
            let parent_dir = ($resolved_file | path dirname)
            let wb_stem = ($resolved_file | path parse | get stem)
            let ext = ($resolved_file | path parse | get extension)

            let out_path = if ($out_file | is-not-empty) {
                if ($out_file | str ends-with ".xlsx") {
                    $out_file | path expand
                } else {
                    ($out_file | path expand | path join $"($wb_stem).xlsx")
                }
            } else {
                ($parent_dir | path join $"($wb_stem).xlsx")
            }

            let status_msg = if $dry_run {
                "dry-run (simulation)"
            } else if ($out_path | path exists) and (not $force) {
                "skipped (file exists, use --force)"
            } else {
                let data = if $ext == "json" {
                    let json_data = (open $resolved_file)
                    if ($json_data | describe) =~ "^record" {
                        $json_data
                    } else {
                        let effective_sheet = if ($sheet_name | is-empty) { $wb_stem } else { $sheet_name }
                        { ($effective_sheet): $json_data }
                    }
                } else {
                    let effective_sheet = if ($sheet_name | is-empty) { $wb_stem } else { $sheet_name }
                    let rows = (open-csv-flexible $resolved_file $delimiter)
                    { ($effective_sheet): $rows }
                }

                write-xlsx-file $data $out_path
                "exported"
            }

            {
                source: (format-display-path $resolved_file),
                file: (format-display-path $out_path),
                status: $status_msg
            }
        }
    }
}

# Aliases for convenience
export def "csv to-xlsx" [
    file?: path
    --out-file (-o): path
    --sheet-name (-s): string
    --delimiter (-d): string
    --combine (-c)
    --force (-f)
    --dry-run
] {
    data to-xlsx $file -o $out_file -s $sheet_name -d $delimiter --combine=$combine --force=$force --dry-run=$dry_run
}

export def "json to-xlsx" [
    file?: path
    --out-file (-o): path
    --sheet-name (-s): string
    --combine (-c)
    --force (-f)
    --dry-run
] {
    data to-xlsx $file -o $out_file -s $sheet_name --combine=$combine --force=$force --dry-run=$dry_run
}

# =============================================================================
# Universal Converter (Smart Auto-Detection)
# =============================================================================

# Universal tabular converter that automatically detects source and target format from file extensions.
# Example:
#   data convert data.xlsx data.json
#   data convert data.csv data.xlsx
#   data convert data.json data.csv
export def "data convert" [
    source: path                # Source file (.xlsx, .csv, .json, .tsv)
    target: path                # Target file (.xlsx, .csv, .json, .tsv)
    --delimiter (-d): string    # Optional delimiter override for CSV/TSV
    --force (-f)                # Overwrite existing destination file
    --dry-run                   # Simulate conversion without writing
] {
    let src_path = ($source | path expand)
    let dst_path = ($target | path expand)

    if not ($src_path | path exists) {
        error make { msg: $"Source file not found: ($source)" }
    }

    let src_ext = ($src_path | path parse | get extension | str lowercase)
    let dst_ext = ($dst_path | path parse | get extension | str lowercase)

    match [$src_ext, $dst_ext] {
        ["xlsx", "json"] => {
            data to-json $src_path -o $dst_path --combined --force=$force --dry-run=$dry_run
        }
        ["xlsx", "csv"] => {
            data to-csv $src_path -o $dst_path -d ($delimiter | default "|") --force=$force --dry-run=$dry_run
        }
        ["xlsx", "tsv"] => {
            data to-csv $src_path -o $dst_path -d "\t" --force=$force --dry-run=$dry_run
        }
        ["csv", "json"] | ["tsv", "json"] => {
            data to-json $src_path -o $dst_path -d $delimiter --force=$force --dry-run=$dry_run
        }
        ["csv", "xlsx"] | ["tsv", "xlsx"] => {
            data to-xlsx $src_path -o $dst_path -d $delimiter --force=$force --dry-run=$dry_run
        }
        ["json", "csv"] => {
            data to-csv $src_path -o $dst_path -d ($delimiter | default ",") --force=$force --dry-run=$dry_run
        }
        ["json", "tsv"] => {
            data to-csv $src_path -o $dst_path -d "\t" --force=$force --dry-run=$dry_run
        }
        ["json", "xlsx"] => {
            data to-xlsx $src_path -o $dst_path --force=$force --dry-run=$dry_run
        }
        _ => {
            error make { msg: $"Unsupported conversion from '.($src_ext)' to '.($dst_ext)'" }
        }
    }
}
