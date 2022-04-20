local _2afile_2a = "fnl/matchparen/syntax.fnl"
local _2amodule_name_2a = "matchparen.syntax"
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
local a, utils = autoload("matchparen.aniseed.core"), autoload("matchparen.utils")
do end (_2amodule_locals_2a)["a"] = a
_2amodule_locals_2a["utils"] = utils
local f = vim.fn
_2amodule_locals_2a["f"] = f
local g = vim.g
_2amodule_locals_2a["g"] = g
local o = vim.o
_2amodule_locals_2a["o"] = o
local opts = (require("matchparen.defaults")).options
_2amodule_locals_2a["opts"] = opts
local function syntax_on_3f()
  return ((g.syntax_on == 1) and (o.syntax ~= ""))
end
_2amodule_locals_2a["syntax-on?"] = syntax_on_3f
local function get_synname(syn_id)
  return string.lower(f.synIDattr(syn_id, "name"))
end
_2amodule_locals_2a["get-synname"] = get_synname
local function last_three_synnames(line, col)
  local syn_ids = f.synstack(a.inc(line), a.inc(col))
  local len = #syn_ids
  local last_three = {syn_ids[len], syn_ids[(len - 1)], syn_ids[(len - 2)]}
  local len0 = #last_three
  local index = 0
  local function _1_()
    index = a.inc(index)
    if (index <= len0) then
      return get_synname(last_three[index])
    else
      return nil
    end
  end
  return _1_
end
_2amodule_locals_2a["last-three-synnames"] = last_three_synnames
local function in_syntax_skip_region_3f(line, col)
  local result = false
  for synname in last_three_synnames(line, col) do
    if result then break end
    result = utils["string-contains-any?"](synname, opts.syntax_skip_groups)
  end
  return result
end
_2amodule_locals_2a["in-syntax-skip-region?"] = in_syntax_skip_region_3f
local function skip_region_3f(line, col)
  if utils["inside-closed-fold"](line) then
    return false
  else
    return in_syntax_skip_region_3f(line, col)
  end
end
_2amodule_locals_2a["skip-region?"] = skip_region_3f
local function skip_by_region(line, col)
  if syntax_on_3f then
    if skip_region_3f(line, col) then
      local function _4_(_241, _242)
        return not skip_region_3f(_241, _242)
      end
      return _4_
    else
      local function _5_(_241, _242)
        return skip_region_3f(_241, _242)
      end
      return _5_
    end
  else
    return nil
  end
end
_2amodule_2a["skip-by-region"] = skip_by_region
return _2amodule_2a