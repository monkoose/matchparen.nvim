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
local autoload = (require("matchparen.aniseed.autoload")).autoload
local nvim, search, utils = autoload("matchparen.aniseed.nvim"), autoload("matchparen.search"), autoload("matchparen.utils")
do end (_2amodule_locals_2a)["nvim"] = nvim
_2amodule_locals_2a["search"] = search
_2amodule_locals_2a["utils"] = utils
local opts = (require("matchparen.defaults")).options
_2amodule_locals_2a["opts"] = opts
local function delete_extmark(id)
  return nvim.buf_del_extmark(0, opts.namespace, id)
end
_2amodule_locals_2a["delete-extmark"] = delete_extmark
local function hide_extmark(id)
end
_2amodule_locals_2a["hide-extmark"] = hide_extmark
local function pcall_update()
end
_2amodule_2a["pcall-update"] = pcall_update
local function remove()
end
_2amodule_2a["remove"] = remove
local function update_on_tick()
end
_2amodule_2a["update-on-tick"] = update_on_tick
return _2amodule_2a