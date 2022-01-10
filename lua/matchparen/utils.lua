local conf = require('matchparen').config

local M = {}

-- Returns matched position of vim.fn.searchpairpos call
-- @param matchpair
-- @param skip_ref string vim function reference
-- @param line number 1-based line number
-- @param insert boolean is in insert mode
-- @return (number, number) or nil
function M.search_pair_pos(matchpair, skip_ref, line, insert)
    local flags = matchpair.backward and 'bnW' or 'nW'
    local timeout = insert and conf.timeout_insert or conf.timeout
    local win_height = vim.api.nvim_win_get_height(0)
    -- highlight characters offscreen, so such characters scrolled into view would be highlited
    local stopline = matchpair.backward and math.max(1, line - win_height) or (line + win_height)
    -- `searchpairpos()` can cause errors when evaluating `skip_ref` expression
    -- so it should be handled
    local ok, match_pos = pcall(vim.fn.searchpairpos,
                                matchpair.left,
                                '',
                                matchpair.right,
                                flags,
                                skip_ref,
                                stopline,
                                timeout)
    if ok and match_pos[1] > 0 then
        -- `searchpairpos()` returns 1-based results, but we work with 0-based
        return match_pos[1] - 1, match_pos[2] - 1
    end
end

-- Determines if cursor is in a specific region
-- @param fn function that return nil outside of region
-- @return boolean
function M.in_skip_region(fn)
    local line, col = unpack(vim.api.nvim_win_get_cursor(0))
    if vim.fn.foldclosed(line) ~= -1 then
        return false
    end

    return fn(line - 1, col) ~= nil
end

local function find_forward_char(text, chars, limit)
    local index, _, bracket = string.find(text, '([' .. chars .. '])', limit)
    return index, bracket
end

local function find_backward_char(text, chars, limit)
    local _, index, bracket = string.find(text:sub(1, limit), '.*([' .. chars .. '])')
    return index, bracket
end

local function find_char(text, chars, limit, backward)
        if backward then
            return find_backward_char(text, chars, limit and limit - 1)
        else
            return find_forward_char(text, chars, limit and limit + 1)
        end
end

local function next_line_pos(line, backward)
    line = backward and line - 1 or line + 1
    return line, nil
end

local function get_line(line)
    return vim.api.nvim_buf_get_lines(0, line, line + 1, false)[1]
end


function M.search(char, line, col, backward, skip, stop)
    local index
    local text = get_line(line)
    stop = stop or function() end
    skip = skip or function() end

    repeat
        index = find_char(text, char, col, backward)

        if index then
            if not skip(line, col) then
                return line, index - 1
            end
            col = index
        else
            line, col = next_line_pos(line, backward)
            text = get_line(line)
        end
    until not text or stop(line, col)
end

function M.search_pair(left, right, line, col, backward, skip, stop)
    local count = 0
    local text = get_line(line)
    local index, bracket
    local chars = right .. left
    local same_bracket = backward and right or left
    stop = stop or function() end
    skip = skip or function() end

    repeat
        index, bracket = find_char(text, chars, col, backward)
        if index then
            if not skip(line, col) then
                if bracket == same_bracket then
                    count = count + 1
                else
                    if count == 0 then
                        return line, index - 1
                    else
                        count = count - 1
                    end
                end
            end
            col = index
        else
            line, col = next_line_pos(line, backward)
            text = get_line(line)
        end
    until not text or stop(line, col)
end

return M
