local _2afile_2a = "fnl/matchparen/utils.fnl"
local _2amodule_name_2a = "matchparen.utils"
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
local a, nvim = autoload("matchparen.aniseed.core"), autoload("matchparen.nvim")
do end (_2amodule_locals_2a)["a"] = a
_2amodule_locals_2a["nvim"] = nvim
local f = vim.fn
_2amodule_locals_2a["f"] = f
local buf = nvim.buf
_2amodule_locals_2a["buf"] = buf
local win = nvim.win
_2amodule_locals_2a["win"] = win
local function inside_closed_fold_3f(line)
  return (-1 ~= f.foldclosed(a.inc(line)))
end
_2amodule_2a["inside-closed-fold?"] = inside_closed_fold_3f
local function insert_mode_3f()
  local mode = nvim.get_mode().mode
  return ((mode == "i") or (mode == "R"))
end
_2amodule_2a["insert-mode?"] = insert_mode_3f
local function string_contains_3f(str, pattern)
  return (str:find(pattern, 1, true) ~= nil)
end
_2amodule_2a["string-contains?"] = string_contains_3f
local function string_contains_any_3f(str, table_of_strings)
  local function _1_(_241)
    return string_contains_3f(str, _241)
  end
  return a.some(_1_, table_of_strings)
end
_2amodule_2a["string-contains-any?"] = string_contains_any_3f
local function get_cursor_pos()
  local _let_2_ = win.get_cursor(0)
  local line = _let_2_[1]
  local col = _let_2_[2]
  return {a.dec(line), col}
end
_2amodule_2a["get-cursor-pos"] = get_cursor_pos
local function find_forward(text, pattern, init)
  local i
  if init then
    i = a.inc(init)
  else
    i = nil
  end
  local index, _, capture = string.find(text, pattern, i)
  return index, capture
end
_2amodule_2a["find-forward"] = find_forward
local function find_backward(reversed_text, pattern, init)
  local len = a.inc(#reversed_text)
  local i
  if init then
    i = (len - init)
  else
    i = nil
  end
  local index, capture = find_forward(reversed_text, pattern, i)
  if index then
    return (len - index), capture
  else
    return nil
  end
end
_2amodule_2a["find-backward"] = find_backward
local function get_lines(line, count)
  return buf.get_lines(0, line, (line + count), false)
end
_2amodule_2a["get-lines"] = get_lines
return _2amodule_2a