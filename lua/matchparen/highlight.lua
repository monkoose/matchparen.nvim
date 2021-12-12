local conf = require('matchparen').config
local skip = require('matchparen.block').skip

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
    -- increment it for string.sub for correct result
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

    -- TODO: currently just skip comments and strings
    -- should make it works inside this blocks
    if skip() then return end

    local starts = conf.matchpairs[char].opening
    local ends = conf.matchpairs[char].closing
    local backward = conf.matchpairs[char].backward
    local flags = backward and 'bnW' or 'nW'
    local timeout = in_insert and conf.timeout_insert or conf.timeout

    -- calculate how many lines `searchpairpos` should search before stop
    -- so we highlight characters even offscreen, so such characters scrolled into view
    -- would be highlited
    local win_height = a.nvim_win_get_height(0)
    local stopline = backward and max(1, cursor_line - win_height) or (cursor_line + win_height)

    -- shift cursor to the left
    if shift then
        a.nvim_win_set_cursor(0, { cursor_line, cursor_col - 1 })
    end

    -- `searchpairpos` can cause errors when evaluatin `skip` expression so it should be handled
    -- `searchpairpos` returns [0, 0] if there is no match
    local ok, match_pos = pcall(f.searchpairpos, starts, '', ends, flags, 'matchparen#skip()', stopline, timeout)
    if not ok then return end

    -- restore cursor if needed
    if shift then
        a.nvim_win_set_cursor(0, { cursor_line, cursor_col })
    end

    -- `searchpairpos` returns correct values started from 1 (1-based), so we should
    -- correct this. nvim_win_get_cursor return 1-based line, but 0-based for column,
    -- so we don't need to correct it, but we need to decrement it if `shift` is true
    local match_line, match_col = unpack(match_pos)
    cursor_col = shift and cursor_col - 1 or cursor_col
    apply_highlight(cursor_line - 1, cursor_col, match_line -1, match_col - 1)
end

return M
