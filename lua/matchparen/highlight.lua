local conf = require('matchparen').config
local utils = require('matchparen.utils')
local search = require('matchparen.search')

local M = {}

---Creates extmark
local function create_extmark(line, col)
    return vim.api.nvim_buf_set_extmark(
        0, conf.namespace, line, col,
        { end_col = col + 1, hl_group = conf.hl_group }
    )
end

---Deletes extmark
local function delete_extmark(id)
    vim.api.nvim_buf_del_extmark(0, conf.namespace, id)
end

---Removes highlighting from matching brackets
function M.remove()
    delete_extmark(conf.extmarks.current)
    delete_extmark(conf.extmarks.match)
end

---Highlights characters at positions x and y
local function apply_highlight(x_line, x_col, y_line, y_col)
    conf.extmarks.current = create_extmark(x_line, x_col)
    conf.extmarks.match = create_extmark(y_line, y_col)
end

---Returns matched bracket conf option and its column or nil
---@param col number 0-based column number
---@param in_insert boolean
---@return table|nil, number
local function get_bracket(col, in_insert)
    local text = vim.api.nvim_get_current_line()
    in_insert = utils.is_in_insert_mode() or in_insert

    if col > 0 and in_insert then
        local before_char = text:sub(col, col)
        if conf.matchpairs[before_char] then
            return conf.matchpairs[before_char], col - 1
        end
    end

    local inc_col = col + 1
    local cursor_char = text:sub(inc_col, inc_col)
    return conf.matchpairs[cursor_char], col
end

---Updates the highlight of brackets by first removing previous highlight
---and then if there is matching brackets pair at the new cursor position highlight them
local function update(in_insert)
    M.remove()
    vim.g.matchparen_tick = vim.api.nvim_buf_get_changedtick(0)
    local line, col = utils.get_current_pos()

    if utils.inside_closed_fold(line) then return end

    local match_bracket
    match_bracket, col = get_bracket(col, in_insert)
    if not match_bracket then return end

    local match_line, match_col = search.match_pos(match_bracket, line, col)
    if match_line then
        apply_highlight(line, col, match_line, match_col)
    end
end

function M.pcall_update(in_insert)
    local ok, err = xpcall(update, debug.traceback, in_insert)
    if not ok and not utils.error then
        utils.error = err
        vim.cmd("silent! command MatchParenError lua require'matchparen.utils'.show_error()")
        vim.api.nvim_echo(
            {
                { ' matchparen.nvim: ', 'String' },
                { 'ERROR detected ', 'ErrorMsg' },
                { 'highlighting could be broken, ', 'Normal' },
                { ':MatchParenError ', 'WarningMsg' },
                { 'for more info', 'Normal' },
            },
            true, {}
        )
    end
end

---Updates highlighting only if changedtick is changed
---currently used only for TextChanged and TextChangedI autocmds
---so they do not repeat `pcall_update()` function after CursorMoved autocmds
function M.update_on_tick()
    if vim.g.matchparen_tick ~= vim.api.nvim_buf_get_changedtick(0) then
        M.pcall_update()
    end
end

return M
