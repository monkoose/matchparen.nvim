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
local a, nvim = autoload("matchparen.aniseed.core"), autoload("matchparen.aniseed.nvim")
do end (_2amodule_locals_2a)["a"] = a
_2amodule_locals_2a["nvim"] = nvim
local f = vim.fn
_2amodule_locals_2a["f"] = f
local function inside_closed_fold_3f(line_nr)
  return (-1 ~= f.foldclosed(a.inc(line_nr)))
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
local function get_cursor_pos()
  local _let_1_ = nvim.win_get_cursor(0)
  local line = _let_1_[1]
  local col = _let_1_[2]
  return a.dec(line), col
end
_2amodule_2a["get-cursor-pos"] = get_cursor_pos
local function find_forward(text, pattern, init)
  local index, _, capture = nil, nil, nil
  local function _2_()
    if init then
      return a.inc(init)
    else
      return nil
    end
  end
  index, _, capture = string.find(text, pattern, _2_())
  return index, capture
end
_2amodule_2a["find-forward"] = find_forward
local function find_backward(reversed_text, pattern, init)
  local len = a.inc(#reversed_text)
  local index, capture = nil, nil
  local function _3_()
    if init then
      return (len - init)
    else
      return nil
    end
  end
  index, capture = find_forward(reversed_text, pattern, _3_())
  if index then
    return (len - index), capture
  else
    return nil
  end
end
_2amodule_2a["find-backward"] = find_backward
local function get_line(line)
  local _let_5_ = nvim.buf_get_lines(0, line, a.inc(line), false)
  local text = _let_5_[1]
  return text
end
_2amodule_2a["get-line"] = get_line
local function get_reversed_line(line)
  local text = get_line(line)
  if text then
    return string.reverse(text)
  else
    return nil
  end
end
_2amodule_2a["get-reversed-line"] = get_reversed_line
return _2amodule_2a