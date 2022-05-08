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
local autoload = (require("matchparen.aniseed.autoload")).autoload
local a, opts, utils = autoload("matchparen.aniseed.core"), autoload("matchparen.options.opts"), autoload("matchparen.utils")
do end (_2amodule_locals_2a)["a"] = a
_2amodule_locals_2a["opts"] = opts
_2amodule_locals_2a["utils"] = utils
local f = vim.fn
_2amodule_locals_2a["f"] = f
local syntax_skip = {"string", "comment", "character", "singlequoute", "escape", "symbol"}
_2amodule_locals_2a["syntax-skip"] = syntax_skip
local function syntax_on_3f()
  return ((vim.g.syntax_on == 1) and (vim.bo.syntax ~= ""))
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
  local index = 0
  local function _1_()
    index = a.inc(index)
    if (index <= #last_three) then
      return get_synname(last_three[index])
    else
      return nil
    end
  end
  return _1_
end
_2amodule_locals_2a["last-three-synnames"] = last_three_synnames
local function in_syntax_skip_3f(line, col)
  local result = false
  for synname in last_three_synnames(line, col) do
    if result then break end
    result = utils["string-contains-any?"](synname, syntax_skip)
  end
  return result
end
_2amodule_locals_2a["in-syntax-skip?"] = in_syntax_skip_3f
local function in_skip_region_3f(line, col)
  if utils["inside-closed-fold?"]() then
    return false
  else
    return in_syntax_skip_3f(line, col)
  end
end
_2amodule_locals_2a["in-skip-region?"] = in_skip_region_3f
local function skip_by_region(line, col)
  if syntax_on_3f then
    if in_skip_region_3f(line, col) then
      local function _4_(_241, _242)
        if in_skip_region_3f(_241, _242) then
          return 0
        else
          return 1
        end
      end
      return _4_
    else
      local function _6_(_241, _242)
        if __fnl_global__skip_2dregion_3f(_241, _242) then
          return 1
        else
          return 0
        end
      end
      return _6_
    end
  else
    return nil
  end
end
_2amodule_2a["skip-by-region"] = skip_by_region
return _2amodule_2a