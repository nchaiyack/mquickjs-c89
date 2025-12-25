#!/usr/bin/awk -f
# Remove trailing comma before the closing brace in enum declarations (C89 pedantic)
# Line- and context-agnostic: accumulates full enum blocks across lines.
# Usage: awk -f patch_enum_trailing_comma.awk file.h > file.h.new && mv file.h.new file.h

BEGIN {
    state = "normal"
    block = ""
    depth = 0
}

function rindex(s, t,    i, n, m) {
    n = length(s); m = length(t)
    for (i = n - m + 1; i >= 1; i--) if (substr(s, i, m) == t) return i
    return 0
}

function strip_trailing_comma(s,    close_pos, j, open_pos) {
    close_pos = rindex(s, "}")
    if (close_pos == 0) return s
    j = close_pos - 1
    # skip whitespace before '}'
    while (j >= 1 && substr(s, j, 1) ~ /[ \t\n\r]/) j--
    # skip any trailing block comments before '}' (/* ... */)
    while (j >= 2 && substr(s, j-1, 2) == "*/") {
        open_pos = rindex(substr(s, 1, j-2), "/*")
        if (open_pos <= 0) break
        j = open_pos - 1
        while (j >= 1 && substr(s, j, 1) ~ /[ \t\n\r]/) j--
    }
    if (j >= 1 && substr(s, j, 1) == ",") {
        # remove the comma; keep surrounding whitespace/comments
        s = substr(s, 1, j-1) substr(s, j+1)
    }
    return s
}

{
    line = $0
    if (state == "normal") {
        if (match(line, /(^|[^[:alnum:]_])enum([^[:alnum:]_]|$)/)) {
            # saw 'enum' keyword; start capturing when '{' appears
            pending = line "\n"
            if (index(line, "{")) {
                block = pending
                depth = gsub(/\{/, "{", line) - gsub(/\}/, "}", line)
                if (depth < 1) depth = 1  # ensure we close at first '}'
                state = "capture"
            } else {
                state = "enum_pending"
            }
            next
        }
        print line
        next
    }

    if (state == "enum_pending") {
        pending = pending line "\n"
        if (index(line, "{")) {
            block = pending
            depth = gsub(/\{/, "{", pending) - gsub(/\}/, "}", pending)
            if (depth < 1) depth = 1
            state = "capture"
        }
        next
    }

    if (state == "capture") {
        # If we just transitioned on same line, it is already included in block
        if (block != "" && substr(block, length(block), 1) != "\n") {
            block = block "\n"
        }
        if (pending == "") {
            block = block line "\n"
        }
        # Adjust depth based on this line
        depth += gsub(/\{/, "{", line)
        depth -= gsub(/\}/, "}", line)
        if (depth <= 0 || index(line, "}")) {
            # Close enum block captured; strip trailing comma before final '}'
            block = strip_trailing_comma(block)
            printf "%s", block
            # reset state
            state = "normal"
            block = ""; pending = ""; depth = 0
        }
        next
    }
}
