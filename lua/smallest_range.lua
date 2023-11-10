local function calculateDelta(pos1, pos2)
    -- pos1 and pos2 are {line, col}
    -- returns the number of characters between the 2 positions
    local delta = 0
    if pos1[1] == pos2[1] then
        -- same line
        delta = pos2[2] - pos1[2]
    else
        -- different lines
        delta = pos2[2] + vim.fn.col({ pos1[1], '$' }) - pos1[2]
        for i = pos1[1] + 1, pos2[1] - 1 do
            delta = delta + vim.fn.col({ i, '$' })
        end
    end

    return delta
end

local function findSmallestPair(pairs)
    local current_lnum = vim.fn.line(".") or 1

    -- searching 3 lines before to 3 lines after the cursor
    local from = current_lnum - 3
    local to = current_lnum + 3

    -- making sure from > 0 and to < #lines
    local lines = vim.fn.line("$") or 1
    if from < 1 then
        from = 1
    end
    if to > lines then
        to = lines
    end

    local pair_pos = {}
    local smallest_delta = -1

    for _, p in ipairs(pairs) do
        local closest_before
        local closest_after

        if p[1] == p[2] then
            -- opening and closing chars are the same
            closest_before = vim.fn.searchpos(p[1], "cbnW")
            closest_after = vim.fn.searchpos(p[2], "cnW")
        else
            closest_before = vim.fn.searchpairpos(p[1], "", p[2], "cbnW")
            closest_after = vim.fn.searchpairpos(p[1], "", p[2], "cnW")
        end

        local can_be_multiline = p[3]

        local are_lines_ok = can_be_multiline or ( closest_before[1] == closest_after[1])
        local chars_have_been_found = closest_before[1] > 0 and closest_after[1] > 0

        if are_lines_ok and chars_have_been_found then
            local delta = calculateDelta(closest_before, closest_after)
            if smallest_delta < 0 or delta < smallest_delta then
                smallest_delta = delta
                pair_pos = { closest_before, closest_after }
            end
        end
    end

    return pair_pos
end

local function select_smallest_range(include_chars)
    local pair = findSmallestPair({
        -- { "opening", "closing" , multiline },
        { "{", "}", true },
        { "(", ")", true },
        { "[", "]", true },
        { "<", ">", true },
        { "'", "'", false },
        { '"', '"', false },
    })

    if #pair > 0 then
        if not include_chars then
            -- removing the chars from the pair

            local eol_start = vim.fn.col({ pair[1][1], '$' })

            if pair[1][2] == eol_start - 1 then
                -- opening char is at the end of the line
                -- adding a space after the char
                local line = vim.fn.getline(pair[1][1])
                vim.fn.setline(pair[1][1], line .. " ")
            end
            pair[1][2] = pair[1][2] + 1


            if pair[2][2] == 1 then
                -- closing char is at the beginning of the line
                pair[2][1] = pair[2][1] - 1
                pair[2][2] = vim.fn.col({ pair[2][1], '$' })
            else
                pair[2][2] = pair[2][2] - 1
            end
        end

        -- setting cursor pos to opening char
        vim.fn.cursor(pair[1])

        -- activating visual mode
        vim.cmd("normal! v")

        -- setting cursor pos to closing char
        vim.fn.cursor(pair[2])
    end
end

return {
    select_smallest_range = select_smallest_range
}
