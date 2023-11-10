local function findSmallestPair(pairs)
    -- Searching for all the characters matching the pairs.
    -- We want to remember the order of the pairs, so we can
    -- match them later.
    local regex = "⏺"
    for _, pair in ipairs(pairs) do
        regex = regex .. pair[1] .. pair[2]
    end
    regex = "[^" .. regex .. "]+"

    local current_lnum = vim.fn.line(".") or 1

    -- searching 3 lines before to 3 lines after the cursor
    local from = current_lnum - 3
    local to = current_lnum + 3

    local all_lines = ""
    for linenum = from, to do
        local line = vim.fn.getline(linenum)
        if linenum == current_lnum then
            line = line .. "⏺"
        end
        all_lines = all_lines .. line
    end

    -- Removing all the characters that are not part of the pairs from all_lines
    local braces = all_lines:gsub(regex, "")

    -- removing all matching braces (e.g. '{}' or '()' or '[]') recursively
    while true do
        local new_braces = braces
        for _, pair in ipairs(pairs) do
            local rx = pair[1] .. pair[2]
            new_braces = new_braces:gsub(rx, "")
        end
        if new_braces == braces then
            break
        end
        braces = new_braces
    end

    -- separating the braces before and after the cursor.
    local cursor_pos = braces:find("⏺")
    local braces_before = braces:sub(1, cursor_pos - 1)
    local braces_after = braces:sub(cursor_pos + 3):reverse()

    -- Removing all the matching braces from the braces_before and braces_after
    while true do
        local prev_brace = braces_before:sub(-1)
        local next_brace = braces_after:sub(-1)
        local found_pair = false
        for _, pair in ipairs(pairs) do
            if prev_brace:match(pair[1]) and next_brace:match(pair[2]) then
                braces_before = braces_before:sub(1, -2)
                braces_after = braces_after:sub(1, -2)
                found_pair = true
                break
            end
        end
        if not found_pair then
            break
        end
    end

    -- Doing the same thing, but from the end of the strings
    braces_before = braces_before:reverse()
    braces_after = braces_after:reverse()
    while true do
        local prev_brace = braces_before:sub(-1)
        local next_brace = braces_after:sub(-1)
        local found_pair = false
        for _, pair in ipairs(pairs) do
            if prev_brace:match(pair[1]) and next_brace:match(pair[2]) then
                braces_before = braces_before:sub(1, -2)
                braces_after = braces_after:sub(1, -2)
                found_pair = true
                break
            end
        end
        if not found_pair then
            break
        end
    end

    return { '{', '}' };
end

local function select_smallest_range()
    local pair = findSmallestPair({
        { "{", "}" },
        { "(", ")" },
        { "[", "]" },
        { "<", ">" },
        { "'", "'" },
        { '"', '"' },
    })
end

return {
    select_smallest_range = select_smallest_range
}
