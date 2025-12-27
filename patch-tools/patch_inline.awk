#!/usr/bin/awk -f
# Remove standalone 'inline' outside strings/chars/comments (POSIX AWK)
# Usage: awk -f patch_inline.awk file.in > file.out

BEGIN { in_block = 0 }

function is_word_char(ch) { return ch ~ /[[:alnum:]_]/ }

{
    line = $0
    out = ""
    n = length(line)

    in_str = in_char = esc = 0
    i = 1

    while (i <= n) {
        c = substr(line, i, 1)

        if (in_block) {
            out = out c
            if (c == "*" && i < n && substr(line, i+1, 1) == "/") {
                out = out "/"
                in_block = 0
                i += 2
                continue
            }
            i++; continue
        }

        if (in_str) {
            out = out c
            if (!esc && c == "\"") in_str = 0
            if (c == "\\" && !esc) esc = 1; else if (esc) esc = 0
            i++; continue
        }

        if (in_char) {
            out = out c
            if (!esc && c == "'") in_char = 0
            if (c == "\\" && !esc) esc = 1; else if (esc) esc = 0
            i++; continue
        }

        # Comment starts
        if (c == "/" && i < n) {
            c2 = substr(line, i+1, 1)
            if (c2 == "/") { out = out substr(line, i); break }
            if (c2 == "*") { out = out "/*"; in_block = 1; i += 2; continue }
        }

        # Quote starts
        if (c == "\"") { in_str = 1; esc = 0; out = out c; i++; continue }
        if (c == "'")  { in_char = 1; esc = 0; out = out c; i++; continue }

        # Drop standalone 'inline'
        if (c == "i" && i + 5 <= n && substr(line, i, 6) == "inline") {
            prev = (length(out) ? substr(out, length(out), 1) : "")
            nextc = (i + 6 <= n ? substr(line, i+6, 1) : "")
            if (!is_word_char(prev) && !is_word_char(nextc)) {
                # Avoid double spaces: if space before and after, drop the next one
                if (prev ~ /[ \t]/ && nextc ~ /[ \t]/) i += 7; else i += 6
                continue
            }
        }

        out = out c
        i++
    }

    print out
}