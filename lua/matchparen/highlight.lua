local conf = require('matchparen').config
local utils = require('matchparen.utils')
local search = require('matchparen.search')

local M = {}

-- Creates extmark
local function create_extmark(line, col)
    return vim.api.nvim_buf_set_extmark(
        0, conf.namespace, line, col,
        { end_col = col + 1, hl_group = conf.hl_group }
    )
end

-- Deletes extmark
local function delete_extmark(id)
    vim.api.nvim_buf_del_extmark(0, conf.namespace, id)
end

-- Removes highlighting from matching brackets
function M.remove()
    delete_extmark(conf.extmarks.current)
    delete_extmark(conf.extmarks.match)
end

-- Highlights characters at positions x and y
local function apply_highlight(x_line, x_col, y_line, y_col)
    conf.extmarks.current = create_extmark(x_line, x_col)
    conf.extmarks.match = create_extmark(y_line, y_col)
end

-- Updates the highlight of brackets by first removing previous highlight
-- and then if there is matching brackets pair at the new cursor position highlight them
function M.update(in_insert)
    M.remove()

    vim.g.matchparen_tick = vim.api.nvim_buf_get_changedtick(0)
    local line, col = utils.get_current_pos()
    local inc_line = line + 1

    -- Do not process current line if it is in closed fold
    if vim.fn.foldclosed(inc_line) ~= -1 then return end

    local text = vim.api.nvim_get_current_line()
    local inc_col = col + 1
    local bracket = text:sub(inc_col, inc_col)
    in_insert = utils.is_in_insert_mode() or in_insert
    local shift = false

    if col > 0 and in_insert then
        local before_char = text:sub(col, col)
        if conf.matchpairs[before_char] then
            bracket = before_char
            shift = true
        end
    end

    if not conf.matchpairs[bracket] then return end

    -- shift cursor to the left
    if shift then
        col = col - 1
        vim.api.nvim_win_set_cursor(0, { inc_line, col })
    end

    local match_line, match_col = search.match_pos(conf.matchpairs[bracket], line, col)
    if match_line then
        apply_highlight(line, col, match_line, match_col)
    end

    -- restore cursor if previously shifted
    if shift then
        vim.api.nvim_win_set_cursor(0, { inc_line, col + 1})
    end
end

-- Updates highlighting only if changedtick is changed
-- currently used only for TextChanged and TextChangedI autocmds
-- so they do not repeat `update()` function after CursorMoved autocmds
function M.update_on_tick()
    if vim.g.matchparen_tick ~= vim.api.nvim_buf_get_changedtick(0) then
        M.update()
    end
end

return M
