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
local a, opts, utils = autoload("matchparen.aniseed.core"), autoload("matchparen.defaults"), autoload("matchparen.utils")
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
local function last_three_synids(pos)
  local synids = f.synstack(a.inc(pos.line), a.inc(pos.col))
  local len = #synids
  return {synids[len], synids[(len - 1)], synids[(len - 2)]}
end
_2amodule_locals_2a["last-three-synids"] = last_three_synids
local function synname(synid)
  return string.lower(f.synIDattr(synid, "name"))
end
_2amodule_locals_2a["synname"] = synname
local function belong_to_skip_3f(synid)
  return utils["string-contains-any?"](synname(synid), syntax_skip)
end
_2amodule_locals_2a["belong-to-skip?"] = belong_to_skip_3f
local function in_syntax_skip_3f(pos)
  return a.some(last_three_synids(pos), belong_to_skip_3f)
end
_2amodule_locals_2a["in-syntax-skip?"] = in_syntax_skip_3f
local function in_skip_region_3f(pos)
  if utils["inside-closed-fold?"]() then
    return false
  else
    return in_syntax_skip_3f(pos)
  end
end
_2amodule_locals_2a["in-skip-region?"] = in_skip_region_3f
local function skip_by_region(pos)
  if syntax_on_3f then
    if in_skip_region_3f(pos) then
      local function _2_(_241)
        if in_skip_region_3f(_241) then
          return 0
        else
          return 1
        end
      end
      return _2_
    else
      local function _4_(_241)
        if in_skip_region_3f(_241) then
          return 1
        else
          return 0
        end
      end
      return _4_
    end
  else
    return nil
  end
end
_2amodule_2a["skip-by-region"] = skip_by_region
return _2amodule_2a