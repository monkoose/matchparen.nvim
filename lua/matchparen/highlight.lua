local opts = require('matchparen.options').opts
local utils = require('matchparen.utils')
local search = require('matchparen.search')
local nvim = require('matchparen.missinvim')

local buf = nvim.buf
local M = {}

---Creates extmark
local function create_extmark(line, col)
  return buf.set_extmark(0, opts.namespace, line, col,
    { end_col = col + 1, hl_group = opts.hl_group })
end

---Deletes extmark
local function delete_extmark(id)
  buf.del_extmark(0, opts.namespace, id)
end

---Removes highlighting from matching brackets
function M.remove()
  delete_extmark(opts.extmarks.current)
  delete_extmark(opts.extmarks.match)
end

---Highlights characters at positions x and y
local function apply_highlight(x_line, x_col, y_line, y_col)
  opts.extmarks.current = create_extmark(x_line, x_col)
  opts.extmarks.match = create_extmark(y_line, y_col)
end

---Returns matched bracket option and its column or nil
---@param col number 0-based column number
---@param in_insert boolean
---@return table|nil, number
local function get_bracket(col, in_insert)
  local text = nvim.get_current_line()
  in_insert = in_insert or utils.is_in_insert_mode()

  if col > 0 and in_insert then
    local before_char = text:sub(col, col)
    if opts.matchpairs[before_char] then
      return opts.matchpairs[before_char], col - 1
    end
  end

  local inc_col = col + 1
  local cursor_char = text:sub(inc_col, inc_col)
  return opts.matchpairs[cursor_char], col
end

---Updates the highlight of brackets by first removing previous highlight
---and then if there is matching brackets pair at the new cursor position highlight them
---@param in_insert boolean
function M.update(in_insert)
  M.remove()
  vim.g.matchparen_tick = buf.get_changedtick(0)
  local line, col = utils.get_cursor_pos()

  if utils.inside_closed_fold(line) then return end

  local match_bracket
  match_bracket, col = get_bracket(col, in_insert)
  if not match_bracket then return end

  local match_line, match_col = search.match_pos(match_bracket, line, col)
  if match_line then
    apply_highlight(line, col, match_line, match_col)
  end
end

---Updates highlighting only if changedtick is changed
---currently used only for TextChanged and TextChangedI autocmds
---so they do not repeat `update()` function after CursorMoved autocmds
function M.update_on_tick()
  if vim.g.matchparen_tick ~= buf.get_changedtick(0) then
    M.update()
  end
end

return M

-- vim:sw=2:et
