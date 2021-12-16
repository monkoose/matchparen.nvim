local conf = require('matchparen').config
local syntax = require('matchparen.syntax')
local tree = require('matchparen.treesitter')

local a = vim.api
local f = vim.fn
local max = math.max

local M = {}

-- @return (bool) if in insert or Replace modes
local function is_in_insert_mode()
    local mode = a.nvim_get_mode().mode
    return mode == 'i' or mode == 'R'
end

local function delete_extmark(id)
    a.nvim_buf_del_extmark(0, conf.namespace, id)
end

local function create_extmark(line, col)
    return a.nvim_buf_set_extmark(
        0, conf.namespace, line, col,
        { end_col = col + 1, hl_group = conf.hl_group }
    )
end

-- Removes highlighting from matched characters
function M.remove()
    delete_extmark(conf.extmarks.current)
    delete_extmark(conf.extmarks.match)
end

-- Highlight characters at positions x and y, if y line position is correct
local function apply_highlight(x_line, x_col, y_line, y_col)
    if y_line >= 0 then
        conf.extmarks.current = create_extmark(x_line, x_col)
        conf.extmarks.match = create_extmark(y_line, y_col)
    end
end

function M.update()
    M.remove()

    local cursor_line, cursor_col = unpack(a.nvim_win_get_cursor(0))

    -- Should it also check for pumvisible() as original matchparen does?
    -- Because i do not notice any difference and popupmenu doesn't close
    -- Do not process current line if it is in closed fold
    if f.foldclosed(cursor_line) ~= -1 then return end

    local text = a.nvim_get_current_line()
    -- nvim_win_get_cursor returns column started from 0, so we need to
    -- increment it for string.sub to get correct result
    local inc_col = cursor_col + 1
    local char = text:sub(inc_col, inc_col)
    local in_insert = is_in_insert_mode()
    -- `shift` variable used for insert mode to check if we should shift
    -- the cursor position to the left by one column, neovim matchparen calculates char
    -- size, but i'm not sure why, does someone use multicolumn characters for
    -- `matchpairs` option?
    -- TODO: make more investigation about this and if so fix this
    local shift = false

    if cursor_col > 0 and in_insert then
        local before_char = text:sub(cursor_col, cursor_col)
        if conf.matchpairs[before_char] then
            char = before_char
            shift = true
        end
    end

    if not conf.matchpairs[char] then return end

    -- shift cursor to the left
    if shift then
        cursor_col = cursor_col - 1
        a.nvim_win_set_cursor(0, { cursor_line, cursor_col })
    end

    local ok
    local root
    local match_line
    local match_col
    ok, root = tree.root()

    if ok then  -- buffer has ts parser, so use treesitter to match pair
        local node = tree.node_at(root, cursor_line - 1, cursor_col)
        if tree.is_type_of(node, char) then
            match_line, match_col = tree.get_match_pos(node, conf.matchpairs_ts[char])
        else
            local mp = conf.matchpairs[char]
            local starts = mp.opening
            local ends = mp.closing
            local backward = mp.backward
            local flags = backward and 'bnW' or 'nW'
            local timeout = in_insert and conf.timeout_insert or conf.timeout
            local win_height = a.nvim_win_get_height(0)
            local stopline = backward and max(1, cursor_line - win_height) or (cursor_line + win_height)
            local match_pos
            local start_line, start_col, end_line, end_col = 0, 0, 0, 0

            if tree.is_type_of(node, 'string') then
                start_line, start_col, end_line, end_col = node:range()
            elseif tree.is_type_of(node, 'comment') then
                start_line, start_col, end_line, end_col = tree.comments_range(node, mp.backward)
            end

            ok, match_pos = pcall(f.searchpairpos, starts, '', ends, flags, '', stopline, timeout)
            if ok then
                match_line = match_pos[1] - 1
                match_col = match_pos[2] - 1
                if not (match_line <= end_line and match_col <= end_col
                        or match_line >= start_line and match_col >= start_col) then
                    ok = false
                end
            end
        end
    else  -- no ts parser, try built-in syntax to skip highlighting in strings and comments
        ok, match_line, match_col = syntax.match(conf.matchpairs[char], cursor_line, in_insert)
    end

    -- restore cursor if needed
    if shift then
        cursor_col = cursor_col + 1
        a.nvim_win_set_cursor(0, { cursor_line, cursor_col })
    end

    if not ok or not match_line or match_line < 0 then return end

    -- If shift was true `cursor_col` should be decremented to highlight correct char
    cursor_col = shift and cursor_col - 1 or cursor_col
    apply_highlight(cursor_line - 1, cursor_col, match_line, match_col)
end

return M
