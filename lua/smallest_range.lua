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

local function escapeForRx(str)
    return vim.fn.escape(str, '^$.*~[]')
end

local function charUnderCursor()
    local line = vim.fn.line(".")
    local col = vim.fn.col(".")

    local current_line_content = vim.fn.getline(".")
    local char_under_cursor = current_line_content:sub(col, col)

    return char_under_cursor
end

local function findClosestBrace(target, other, direction)
    -- saving char position
    local initial_cursor_pos = { vim.fn.line('.'), vim.fn.col('.') }

    local stack = 1
    local target_pos = { 0, 0 }

    local flags = direction == 1 and "W" or "bW"

    local rx = escapeForRx(target) .. '\\|' .. escapeForRx(other)
    while vim.fn.search(rx, flags) > 0 do
        local char_under_cursor = charUnderCursor()

        if char_under_cursor == target then
            stack = stack - 1
        elseif char_under_cursor == other then
            stack = stack + 1
        end
        if stack == 0 then
            target_pos = { vim.fn.line("."), vim.fn.col(".") }
            break
        end
    end

    -- Restauring cursor position
    vim.fn.cursor(initial_cursor_pos)

    return target_pos
end

local function searchPairPosForIdenticalPair(pair_char, multiline)
    local current_line = vim.fn.line('.')

    if multiline == false then
        -- one line, We count the opening and closing chars from the start of the line
        local line_content = vim.fn.getline(".")
        local last_open_col = 0
        local cursor_col = vim.fn.col(".")

        -- Iterating on the character in the line
        for col = 1, vim.fn.strlen(line_content) do
            local cur_char = line_content:sub(col, col)
            if cur_char == pair_char then
                if last_open_col == 0 then
                    -- We found an opening char
                    if col > cursor_col then
                        -- The opening char is after the cursor, useless to continue
                        break
                    end
                    last_open_col = col
                else
                    -- We found a closing char
                    if col >= cursor_col then
                        -- The cursor is before the closing, we found our pair
                        return { { current_line, last_open_col }, { current_line, col } }
                    else
                        -- The closing char is before the cursor, we keep looking
                        last_open_col = 0
                    end
                end
            end
        end

        return {{0,0}, {0,0}}
    else
        -- multiline, things get more complicated
        -- Not yet supported
        return {{0,0}, {0,0}}
    end
end


local function searchPairPos(pair)
    -- redefining the searchPairPos function from vim, because the initial
    -- function gives unconsistent results

    if pair[1] == pair[2] then
        return searchPairPosForIdenticalPair(pair[1], pair[3])
    end

    local char_under_cursor = charUnderCursor()

    local pos_before = {0,0}
    local pos_after = {0,0}

    if char_under_cursor == pair[1] then
        -- Cursor is on the opening char
        pos_before = { vim.fn.line("."), vim.fn.col(".") }
        pos_after = findClosestBrace(pair[2], pair[1], 1)
    elseif char_under_cursor == pair[2] then
        -- Cursor is on the closing char
        pos_after = { vim.fn.line("."), vim.fn.col(".") }
        pos_before = findClosestBrace(pair[1], pair[2], -1)
    else
        -- Cursor is somewhere in between
        pos_before = findClosestBrace(pair[1], pair[2], -1)
        pos_after = findClosestBrace(pair[2], pair[1], 1)
    end

    return { pos_before, pos_after }
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

        local closests = searchPairPos(p)
        closest_before = closests[1]
        closest_after = closests[2]

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
        { "[", "]", true },
        { "{", "}", true },
        { "(", ")", true },
        { "<", ">", true },
        { "'", "'", false },
        { '"', '"', false },
        { '`', '`', false },
    })

    if #pair == 0 then
        return
    end

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

return {
    select_smallest_range = select_smallest_range
}
