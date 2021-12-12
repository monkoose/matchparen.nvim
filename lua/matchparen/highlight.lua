local conf = require('matchparen').config
local skip = require('matchparen.block').skip

local a = vim.api
local f = vim.fn
local max = math.max

local M = {}

local function is_insert_mode()
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

function M.remove()
    delete_extmark(conf.extmarks.current)
    delete_extmark(conf.extmarks.match)
end

function M.update()
    M.remove()

    local cur_lnum, cur_col = unpack(a.nvim_win_get_cursor(0))

    -- Should it also check for pumvisible() as original matchparen does?
    -- Because i do not notice any difference and popupmenu doesn't close
    -- Do not process current line if it is in closed fold
    if f.foldclosed(cur_lnum) ~= -1 then return end

    local text = a.nvim_get_current_line()
    local inc_col = cur_col + 1
    local char = text:sub(inc_col, inc_col)
    local in_insert = is_insert_mode()
    local before = 0

    if cur_col > 0 and in_insert then
        local before_char = text:sub(cur_col, cur_col)
        if conf.matchpairs[before_char] then
            char = before_char
            before = 1
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
    local win_height = a.nvim_win_get_height(0)
    local stopline = backward and max(1, cur_lnum - win_height) or (cur_lnum + win_height)

    local saved_cursor
    if before > 0 then
        saved_cursor = a.nvim_win_get_cursor(0)
        a.nvim_win_set_cursor(0, { cur_lnum, cur_col - before })
    end

    local timeout = in_insert and conf.timeout_insert or conf.timeout

    local ok, match_pos = pcall(f.searchpairpos, starts, '', ends, flags, 'matchparen#skip()', stopline, timeout)
    if not ok then return end

    local match_lnum, match_col = unpack(match_pos)

    if before > 0 then
        a.nvim_win_set_cursor(0, saved_cursor)
    end

    if match_lnum > 0 then
        conf.extmarks.current = create_extmark(cur_lnum - 1, cur_col - before)
        conf.extmarks.match = create_extmark(match_lnum - 1, match_col - 1)
    end
end

return M
