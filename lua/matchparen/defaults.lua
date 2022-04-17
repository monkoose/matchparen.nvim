local _2afile_2a = "fnl/matchparen/defaults.fnl"
local _2amodule_name_2a = "matchparen.defaults"
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
local options = {on_startup = true, hl_group = "MatchParen", augroup_name = "matchparen", syntax_skip_groups = {"string", "comment", "character", "singlequoute", "escape", "symbol"}, ts_skip_groups = {"string", "comment"}}
_2amodule_2a["options"] = options
local function update(new_options)
  for option, value in pairs(new_options) do
    if options[option] then
      options[option] = value
    else
    end
  end
  return nil
end
_2amodule_2a["update"] = update
return _2amodule_2a