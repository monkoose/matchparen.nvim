local _2afile_2a = "fnl/matchparen/highlight.fnl"
local _2amodule_name_2a = "matchparen.highlight"
local _2amodule_2a
do
  package.loaded[_2amodule_name_2a] = {}
  _2amodule_2a = package.loaded[_2amodule_name_2a]
end
local _2amodule_locals_2a
do
  _2amodule_2a["aniseed/locals"] = {}
  _2amodule_locals_2a = (_2amodule_2a)["aniseed/locals"]
end
local autoload = (require("aniseed.autoload")).autoload
local a, nvim, opts, search, utils = autoload("matchparen.aniseed.core"), autoload("matchparen.nvim"), autoload("matchparen.defaults"), autoload("matchparen.search"), autoload("matchparen.utils")
do end (_2amodule_locals_2a)["a"] = a
_2amodule_locals_2a["nvim"] = nvim
_2amodule_locals_2a["opts"] = opts
_2amodule_locals_2a["search"] = search
_2amodule_locals_2a["utils"] = utils
local buf = nvim.buf
_2amodule_locals_2a["buf"] = buf
local function set_extmark(line, col, opts0)
  return buf.set_extmark(0, opts0.namespace, line, col, opts0)
end
_2amodule_locals_2a["set-extmark"] = set_extmark
local function create_extmark()
  return set_extmark(0, 0, {})
end
_2amodule_locals_2a["create-extmark"] = create_extmark
local extmarks
local function _1_(t, k)
  local bufnr = {cursor = create_extmark(), match = create_extmark()}
  rawset(t, k, bufnr)
  return bufnr
end
extmarks = setmetatable({hidden = true}, {__index = _1_})
do end (_2amodule_locals_2a)["extmarks"] = extmarks
local function move_extmark(line, col, id)
  return buf.set_extmark(line, col, {end_col = a.inc(col), hl_group = opts.hl_group, id = id})
end
_2amodule_locals_2a["move-extmark"] = move_extmark
local function hide_extmark(id)
  return set_extmark(0, 0, {id = id})
end
_2amodule_locals_2a["hide-extmark"] = hide_extmark
local function highlight_brackets(cur, mat)
  if extmarks.hidden then
    extmarks["hidden"] = false
  else
  end
  local bufnr = nvim.get_current_buf()
  move_extmark(cur.line, cur.col, extmarks[bufnr].cursor)
  return move_extmark(mat.line, mat.col, extmarks[bufnr].match)
end
_2amodule_locals_2a["highlight-brackets"] = highlight_brackets
local function get_bracket(col, insert_3f)
  local text = nvim.get_current_line()
  local insert_3f0 = (insert_3f or utils["insert-mode?"])
  if ((0 < col) and insert_3f0) then
    return nil
  else
    return nil
  end
end
_2amodule_locals_2a["get-bracket"] = get_bracket
local function clear_extmarks(bufnr)
  extmarks[bufnr] = nil
  return nil
end
_2amodule_2a["clear-extmarks"] = clear_extmarks
local function hide()
  if not extmarks.hidden then
    extmarks["hidden"] = true
    local bufnr = nvim.get_current_buf()
    hide_extmark(extmarks[bufnr].cursor)
    return hide_extmark(extmarks[bufnr].match)
  else
    return nil
  end
end
_2amodule_2a["hide"] = hide
local function update(insert_3f)
  vim.g.matchparen_tick = buf.get_changedtick(0)
  local hide_3f = true
  local _local_5_ = utils["get-cursor-pos"]()
  local line = _local_5_[1]
  local col = _local_5_[2]
  if not utils["inside-closed-fold?"](line) then
    local _local_6_ = get_bracket(col, insert_3f)
    local match_bracket = _local_6_[1]
    local col0 = _local_6_[2]
    if match_bracket then
      local m_line, m_col = search["match-pos"](match_bracket, line, col0)
      if m_line then
        hide_3f = false
        highlight_brackets({line = line, col = col0}, {line = m_line, col = m_col})
      else
      end
    else
    end
  else
  end
  if hide_3f then
    return hide()
  else
    return nil
  end
end
_2amodule_2a["update"] = update
local function update_on_tick()
  if (vim.g.matchparen_tick ~= buf.get_changedtick(0)) then
    return update()
  else
    return nil
  end
end
_2amodule_2a["update-on-tick"] = update_on_tick
return _2amodule_2a