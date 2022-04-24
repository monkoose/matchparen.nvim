local opts = require('matchparen.options').opts
local utils = require('matchparen.utils')
local search = require('matchparen.search')
local nvim = require('matchparen.missinvim')

local buf = nvim.buf
local hl = {}

---Creates new extmark and return it's id
---@return integer
local function create_extmark()
  return buf.set_extmark(0, opts.namespace, 0, 0, {})
end

---Creates required extmarks for `bufnr`
function hl.create_extmarks(bufnr)
  if not opts.extmarks[bufnr] then
    opts.extmarks[bufnr] = {}
    opts.extmarks[bufnr].cursor = create_extmark()
    opts.extmarks[bufnr].match = create_extmark()
  end
end

---Sets new position for extmark with `id`
---@param line integer 0-based line number
---@param col integer 0-based column number
---@param id integer extmark id
local function set_extmark(line, col, id)
  buf.set_extmark(0, opts.namespace, line, col,
    { end_col = col + 1, hl_group = opts.hl_group, id = id })
end

---Sets extmark with `id` to 0 length and nil hl_group
---@param id integer extmark id
local function hide_extmark(id)
  buf.set_extmark(0, opts.namespace, 0, 0, { id = id })
end

---Highlights matching brackets
---@param cur table position of the cursor bracket
---@param match table position of the matching bracket
local function highlight_brackets(cur, match)
  if opts.extmarks.hidden then
    opts.extmarks.hidden = false
  end
  local bufnr = nvim.get_current_buf()
  set_extmark(cur.line, cur.col, opts.extmarks[bufnr].cursor)
  set_extmark(match.line, match.col, opts.extmarks[bufnr].match)
end

---Removes brackets highlighting
function hl.hide()
  if not opts.extmarks.hidden then
    opts.extmarks.hidden = true
    local bufnr = nvim.get_current_buf()
    hide_extmark(opts.extmarks[bufnr].cursor)
    hide_extmark(opts.extmarks[bufnr].match)
  end
end

---Returns matched bracket option and its column or nil
---@param col integer 0-based column number
---@param in_insert boolean
---@return table|nil, integer
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
function hl.update(in_insert)
  vim.g.matchparen_tick = buf.get_changedtick(0)
  local line, col = utils.get_cursor_pos()
  if utils.is_inside_fold(line) then
    hl.hide()
    return
  end

  local match_bracket
  match_bracket, col = get_bracket(col, in_insert)
  if not match_bracket then
    hl.hide()
    return
  end

  local match_line, match_col = search.match_pos(match_bracket, line, col)
  if match_line then
    highlight_brackets({ line = line, col = col, },
                       { line = match_line, col = match_col, })
  else
    hl.hide()
  end
end

---Updates highlighting only if changedtick is changed
---currently used only for TextChanged and TextChangedI autocmds
---so they do not repeat `update()` function after CursorMoved autocmds
function hl.update_on_tick()
  if vim.g.matchparen_tick ~= buf.get_changedtick(0) then
    hl.update()
  end
end

return hl

-- vim:sw=2:et
