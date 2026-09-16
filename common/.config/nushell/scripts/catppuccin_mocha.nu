# Catppuccin Mocha / Matugen baseline theme for Nushell
# https://github.com/catppuccin/nushell

export def main [] {
    let catppuccin_mocha = {
        rosewater: "#005049"
        flamingo: "#ffb4ab"
        pink: "#74d7cb"
        mauve: "#ecb8ce"
        red: "#ffb4ab"
        maroon: "#ffb4ab"
        peach: "#e7b7e8"
        yellow: "#5e3962"
        green: "#74d7cb"
        teal: "#ecb8ce"
        sky: "#74d7cb"
        sapphire: "#ecb8ce"
        blue: "#613b4d"
        lavender: "#e7b7e8"
        cyan: "#4f4350"
        text: "#ebdfe9"
        subtext1: "#d2c1d2"
        subtext0: "#9b8c9b"
        overlay2: "#9b8c9b"
        overlay1: "#4f4350"
        overlay0: "#3a323a"
        surface2: "#2f282f"
        surface1: "#241d25"
        surface0: "#171118"
        base: "#241d25"
        mantle: "#171118"
        crust: "#171118"
    }

    let catppuccin_theme = {
        separator: $catppuccin_mocha.overlay0
        leading_trailing_space_bg: $catppuccin_mocha.overlay0
        header: { fg: $catppuccin_mocha.pink attr: "b" }
        empty: $catppuccin_mocha.lavender
        bool: $catppuccin_mocha.lavender
        int: $catppuccin_mocha.peach
        duration: $catppuccin_mocha.text
        filesize: {|size|
            if $size < 1mb {
                $catppuccin_mocha.green
            } else if $size < 100mb {
                $catppuccin_mocha.yellow
            } else if $size < 500mb {
                $catppuccin_mocha.peach
            } else if $size < 800mb {
                $catppuccin_mocha.maroon
            } else if $size > 800mb {
                $catppuccin_mocha.red
            }
        }
        date: {|| (date now) - $in |
            if $in < 1hr {
                $catppuccin_mocha.green
            } else if $in < 1day {
                $catppuccin_mocha.yellow
            } else if $in < 3day {
                $catppuccin_mocha.peach
            } else if $in < 1wk {
                $catppuccin_mocha.maroon
            } else if $in < 6wk {
                $catppuccin_mocha.mauve
            } else if $in < 52wk {
                $catppuccin_mocha.blue
            } else {
                $catppuccin_mocha.subtext0
            }
        }
        range: $catppuccin_mocha.text
        float: $catppuccin_mocha.text
        string: $catppuccin_mocha.text
        nothing: $catppuccin_mocha.text
        binary: $catppuccin_mocha.text
        cellpath: $catppuccin_mocha.text
        row_index: { fg: $catppuccin_mocha.green attr: "b" }
        record: $catppuccin_mocha.text
        list: $catppuccin_mocha.text
        block: $catppuccin_mocha.text
        hints: $catppuccin_mocha.overlay1
        search_result: { fg: $catppuccin_mocha.red bg: $catppuccin_mocha.text }
        shape_and: { fg: $catppuccin_mocha.mauve attr: "b" }
        shape_binary: { fg: $catppuccin_mocha.mauve attr: "b" }
        shape_block: { fg: $catppuccin_mocha.blue attr: "b" }
        shape_bool: $catppuccin_mocha.teal
        shape_custom: $catppuccin_mocha.green
        shape_datetime: { fg: $catppuccin_mocha.teal attr: "b" }
        shape_directory: $catppuccin_mocha.teal
        shape_external: $catppuccin_mocha.teal
        shape_externalarg: { fg: $catppuccin_mocha.green attr: "b" }
        shape_filepath: $catppuccin_mocha.teal
        shape_flag: { fg: $catppuccin_mocha.blue attr: "b" }
        shape_float: { fg: $catppuccin_mocha.mauve attr: "b" }
        shape_garbage: { fg: $catppuccin_mocha.text bg: $catppuccin_mocha.red attr: "b" }
        shape_globpattern: { fg: $catppuccin_mocha.teal attr: "b" }
        shape_int: { fg: $catppuccin_mocha.mauve attr: "b" }
        shape_internalcall: { fg: $catppuccin_mocha.teal attr: "b" }
        shape_list: { fg: $catppuccin_mocha.teal attr: "b" }
        shape_literal: $catppuccin_mocha.blue
        shape_match_pattern: $catppuccin_mocha.green
        shape_matching_brackets: { attr: "u" }
        shape_nothing: $catppuccin_mocha.teal
        shape_operator: $catppuccin_mocha.peach
        shape_or: { fg: $catppuccin_mocha.mauve attr: "b" }
        shape_pipe: { fg: $catppuccin_mocha.mauve attr: "b" }
        shape_range: { fg: $catppuccin_mocha.peach attr: "b" }
        shape_record: { fg: $catppuccin_mocha.teal attr: "b" }
        shape_redirection: { fg: $catppuccin_mocha.mauve attr: "b" }
        shape_signature: { fg: $catppuccin_mocha.green attr: "b" }
        shape_string: $catppuccin_mocha.green
        shape_string_interpolation: { fg: $catppuccin_mocha.teal attr: "b" }
        shape_table: { fg: $catppuccin_mocha.blue attr: "b" }
        shape_variable: $catppuccin_mocha.mauve
    }

    return $catppuccin_theme
}
