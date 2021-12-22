local conf = require('matchparen').config
local syntax = require('matchparen.syntax')
local ts = require('matchparen.treesitter')

local M = {}

-- @return (bool) if in insert or Replace modes
local function is_in_insert_mode()
    local mode = vim.api.nvim_get_mode().mode
    return mode == 'i' or mode == 'R'
end

local function delete_extmark(id)
    vim.api.nvim_buf_del_extmark(0, conf.namespace, id)
end

local function create_extmark(line, col)
    return vim.api.nvim_buf_set_extmark(
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

    local cursor_line, cursor_col = unpack(vim.api.nvim_win_get_cursor(0))

    -- Should it also check for pumvisible() as original matchparen does?
    -- Because i do not notice any difference and popupmenu doesn't close
    -- Do not process current line if it is in closed fold
    if vim.fn.foldclosed(cursor_line) ~= -1 then return end

    local text = vim.api.nvim_get_current_line()
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
        vim.api.nvim_win_set_cursor(0, { cursor_line, cursor_col })
    end

    local match_line
    local match_col
    local parser = ts.get_parser()

    if parser then  -- buffer has ts parser, so use treesitter to match pair
        parser:for_each_tree(function(tree)
            if not match_line then
                local node_at_cursor = ts.node_at(tree:root(), cursor_line - 1, cursor_col)
                match_line, match_col = ts.match(char, node_at_cursor, cursor_line, cursor_col, in_insert)
            end
        end)
    else  -- no ts parser, try built-in syntax to skip highlighting in strings and comments
        match_line, match_col = syntax.match(conf.matchpairs[char], cursor_line, in_insert)
    end

    -- restore cursor if needed
    if shift then
        cursor_col = cursor_col + 1
        vim.api.nvim_win_set_cursor(0, { cursor_line, cursor_col })
    end

    if not match_line then return end

    -- If shift was true `cursor_col` should be decremented to highlight correct char
    cursor_col = shift and cursor_col - 1 or cursor_col
    apply_highlight(cursor_line - 1, cursor_col, match_line, match_col)
end

return M
