local _2afile_2a = "fnl/matchparen/search.fnl"
local _2amodule_name_2a = "matchparen.search"
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
local a, nvim, opts, utils = autoload("matchparen.aniseed.core"), autoload("matchparen.nvim"), autoload("matchparen.defaults"), autoload("matchparen.utils")
do end (_2amodule_locals_2a)["a"] = a
_2amodule_locals_2a["nvim"] = nvim
_2amodule_locals_2a["opts"] = opts
_2amodule_locals_2a["utils"] = utils
local function forward_matches(pattern, line, col, count)
  local lines = utils["get-lines"](line, count)
  local i = 1
  local text = lines[i]
  local index = a.inc(col)
  local capture = nil
  local function _1_()
    while text do
      index, capture = utils["find-forward"](text, pattern, index)
      if index then
        local match_line = a.dec((line + i))
        a.dec(index)
      else
        i = a.inc(i)
        text = lines[i]
      end
    end
    return nil
  end
  return _1_
end
_2amodule_locals_2a["forward-matches"] = forward_matches
local function find_match(pattern, line, col, skip_3f)
  local col_2b1 = a.inc(col)
  local skip_3f0
  local function _3_()
    return false
  end
  skip_3f0 = (skip_3f or _3_)
  local max_lines = nvim.win_get_height(0)
  local lines = utils["get-lines"](line, max_lines)
  for l, c, cap in __fnl_global___2amatch_2dforward(lines, pattern, line, col_2b1) do
    if not skip_3f0(l, c, cap) then
      return {l, c, cap}
    else
    end
  end
  return nil
end
_2amodule_locals_2a["find-match"] = find_match
do
  local start_24_auto = vim.loop.hrtime()
  local result_25_auto
  do
    result_25_auto = find_match("([(])", a.dec(vim.fn.line(".")), a.dec(vim.fn.col(".")))
  end
  local end_26_auto = vim.loop.hrtime()
  print(("Elapsed time: " .. ((end_26_auto - start_24_auto) / 1000000) .. " msecs"))
end
return _2amodule_2a