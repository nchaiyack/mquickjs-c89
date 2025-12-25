#!/usr/bin/awk -f
# Convert // comments to /* ... */ comments (ANSI C/C89 compatible)
# Usage: awk -f patch_comments.awk file.in > file.out

BEGIN {
    in_block = 0  # persist across records for multi-line /* ... */
}

# Replace occurrences of */ inside the comment payload to avoid premature close
function safe_comment_text(s,   t) {
    t = s
    gsub(/\*\//, "* /", t)
    return t
}

{
    line = $0
    out = ""
    n = length(line)

    # Strings/chars do not persist across lines in standard C unless escaped; we reset per line
    in_str = 0
    in_char = 0
    esc = 0

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
            i++
            continue
        }

        if (in_str) {
            out = out c
            if (!esc && c == "\"") {
                in_str = 0
            }
            if (c == "\\" && !esc) esc = 1; else if (esc) esc = 0
            i++
            continue
        }

        if (in_char) {
            out = out c
            if (!esc && c == "'") {
                in_char = 0
            }
            if (c == "\\" && !esc) esc = 1; else if (esc) esc = 0
            i++
            continue
        }

        # normal code region
        if (c == "/" && i < n) {
            c2 = substr(line, i+1, 1)
            if (c2 == "/") {
                # Found // outside of strings/chars/block comments
                comment = substr(line, i+2)
                comment = safe_comment_text(comment)
                out = out "/*" comment "*/"
                # rest of line consumed
                break
            } else if (c2 == "*") {
                # Enter block comment
                in_block = 1
                out = out "/*"
                i += 2
                continue
            }
        }

        if (c == "\"") {
            in_str = 1
            esc = 0
        } else if (c == "'") {
            in_char = 1
            esc = 0
        }

        out = out c
        i++
    }

    print out
}