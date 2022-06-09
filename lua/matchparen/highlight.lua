local opts = require('matchparen.options').opts
local utils = require('matchparen.utils')
local search = require('matchparen.search')

local hl = {}
local namespace = vim.api.nvim_create_namespace(opts.augroup_name)

---Wrapper for nvim_buf_set_extmark()
---@param line integer 0-based line number
---@param col integer 0-based column number
---@param config table
local function set_extmark(line, col, config)
  return vim.api.nvim_buf_set_extmark(0, namespace, line, col, config)
end

---Creates new extmark and return it's id
---@return integer
local function create_extmark()
  return set_extmark(0, 0, {})
end

-- Create required extmarks for each buffer
local extmarks = setmetatable({ hidden = true }, {
  __index = function (t, k)
    local bufnr = {
      cursor = create_extmark(),
      match = create_extmark(),
    }
    rawset(t, k, bufnr)
    return bufnr
  end
})

---Clears extmarks's table `bufnr` key
---@param bufnr integer
function hl.clear_extmarks(bufnr)
  extmarks[bufnr] = nil
end

---Sets new position for extmark with `id`
---@param line integer 0-based line number
---@param col integer 0-based column number
---@param id integer extmark id
local function move_extmark(line, col, id)
  set_extmark(line, col, {
    end_col = col + 1,
    hl_group = opts.hl_group,
    id = id
  })
end

---Sets extmark with `id` to 0 length and nil hl_group
---@param id integer extmark id
local function hide_extmark(id)
  set_extmark(0, 0, { id = id })
end

---Highlights matching brackets
---@param cur table position of the cursor bracket
---@param match table position of the matching bracket
local function highlight_brackets(cur, match)
  if extmarks.hidden then
    extmarks.hidden = false
  end
  local bufnr = vim.api.nvim_get_current_buf()
  move_extmark(cur.line, cur.col, extmarks[bufnr].cursor)
  move_extmark(match.line, match.col, extmarks[bufnr].match)
end

---Removes brackets highlighting
function hl.hide()
  if not extmarks.hidden then
    extmarks.hidden = true
    local bufnr = vim.api.nvim_get_current_buf()
    hide_extmark(extmarks[bufnr].cursor)
    hide_extmark(extmarks[bufnr].match)
  end
end

---Returns matched bracket option and its column or nil
---@param col integer 0-based column number
---@param in_insert boolean
---@return table|nil, integer
local function get_bracket(col, in_insert)
  local text = vim.api.nvim_get_current_line()
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
  vim.g.matchparen_tick = vim.api.nvim_buf_get_changedtick(0)
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
  if vim.g.matchparen_tick ~= vim.api.nvim_buf_get_changedtick(0) then
    hl.update(false)
  end
end

return hl

-- vim:sw=2:et
