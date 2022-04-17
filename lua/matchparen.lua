local _2afile_2a = "fnl/matchparen.fnl"
local _2amodule_name_2a = "matchparen"
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
local hl, nvim, opts = autoload("matchparen.highlight"), autoload("matchparen.aniseed.nvim"), autoload("matchparen.defaults")
do end (_2amodule_locals_2a)["hl"] = hl
_2amodule_locals_2a["nvim"] = nvim
_2amodule_locals_2a["opts"] = opts
local f = vim.fn
_2amodule_locals_2a["f"] = f
local options = opts.options
_2amodule_locals_2a["options"] = options
local function create_commands()
  nvim.add_user_command("MatchParenEnable", "lua require('matchparen.matchpairs').enable()", {})
  return nvim.add_user_command("MatchParenDisable", "lua require('matchparen.matchpairs').disable()", {})
end
_2amodule_locals_2a["create-commands"] = create_commands
local function disable_builtin()
  vim.g.loaded_matchparen = 1
  if (f.exists(":NoMatchParen") ~= 0) then
    return nvim.command("NoMatchParen")
  else
    return nil
  end
end
_2amodule_locals_2a["disable-builtin"] = disable_builtin
local function create_namespace()
  options["namespace"] = nvim.create_namespace(options.augroup_name)
  return nil
end
_2amodule_locals_2a["create-namespace"] = create_namespace
local function augroup_exists(name)
  return (0 ~= f.exists(("#" .. name)))
end
_2amodule_locals_2a["augroup-exists"] = augroup_exists
local function create_autocmds()
  if not augroup_exists(options.augroup_name) then
    local group = nvim.create_augroup(options.augroup_name, {})
    local function _2_()
      return hl["pcall-update"]()
    end
    nvim.create_autocmd({"CursorMoved", "CursorMovedI", "WinEnter"}, {group = group, callback = _2_})
    local function _3_()
      return hl["pcall-update"](true)
    end
    nvim.create_autocmd("InsertEnter", {group = group, callback = _3_})
    local function _4_()
      return hl["update-on-tick"]()
    end
    nvim.create_autocmd({"TextChanged", "TextChangedI"}, {group = group, callback = _4_})
    local function _5_()
      return hl.remove()
    end
    nvim.create_autocmd({"WinLeave", "BufLeave"}, {group = group, callback = _5_})
    nvim.create_autocmd({"WinEnter", "BufWinEnter", "FileType", "VimEnter"}, {group = group, callback = __fnl_global__update_2dmatchpairs})
    return nvim.create_autocmd("OptionSet", {group = group, pattern = "matchpairs", callback = __fnl_global__update_2dmatchpairs})
  else
    return nil
  end
end
_2amodule_locals_2a["create-autocmds"] = create_autocmds
local function delete_autocmds()
  if augroup_exists(options.augroup_name) then
    return nvim.del_augroup_by_name(options.augroup_name)
  else
    return nil
  end
end
_2amodule_locals_2a["delete-autocmds"] = delete_autocmds
local function split_matchpairs()
  local tbl_12_auto = {}
  for _, pair in ipairs((vim.opt.matchpairs):get()) do
    local _8_, _9_ = nil, nil
    do
      local left, right = pair:match("(.+):(.+)")
      _8_, _9_ = left, right
    end
    if ((nil ~= _8_) and (nil ~= _9_)) then
      local k_13_auto = _8_
      local v_14_auto = _9_
      tbl_12_auto[k_13_auto] = v_14_auto
    else
    end
  end
  return tbl_12_auto
end
_2amodule_locals_2a["split-matchpairs"] = split_matchpairs
local function update_matchpairs()
  if (options["cached-matchpairs"] ~= vim.o.matchpairs) then
    options["cached-matchpairs"] = vim.o.matchpairs
    options["matchpairs"] = {}
    for l, r in pairs(split_matchpairs()) do
      options.matchpairs[l] = {left = l, right = r, backward = false}
      options.matchpairs[r] = {left = l, right = r, backward = true}
    end
    return nil
  else
    return nil
  end
end
_2amodule_locals_2a["update-matchpairs"] = update_matchpairs
local function enable()
  create_autocmds()
  update_matchpairs()
  return hl["pcall-update"]()
end
_2amodule_locals_2a["enable"] = enable
local function disable()
  delete_autocmds()
  return hl.remove()
end
_2amodule_locals_2a["disable"] = disable
local function setup(config)
  disable_builtin()
  opts.update(config)
  create_commands()
  create_namespace()
  do end (config)["extmarks"] = {current = 0, match = 0}
  if opts.on_startup then
    return create_autocmds()
  else
    return nil
  end
end
_2amodule_2a["setup"] = setup
return _2amodule_2a