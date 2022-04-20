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
local defaults, hl, nvim = autoload("matchparen.defaults"), autoload("matchparen.highlight"), autoload("matchparen.aniseed.nvim")
do end (_2amodule_locals_2a)["defaults"] = defaults
_2amodule_locals_2a["hl"] = hl
_2amodule_locals_2a["nvim"] = nvim
local f = vim.fn
_2amodule_locals_2a["f"] = f
local opts = defaults.options
_2amodule_locals_2a["opts"] = opts
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
  opts["namespace"] = nvim.create_namespace(opts.augroup_name)
  return nil
end
_2amodule_locals_2a["create-namespace"] = create_namespace
local function augroup_exists(name)
  return (0 ~= f.exists(("#" .. name)))
end
_2amodule_locals_2a["augroup-exists"] = augroup_exists
local function split_matchpairs()
  local tbl_12_auto = {}
  for _, pair in ipairs((vim.opt.matchpairs):get()) do
    local _2_, _3_ = nil, nil
    do
      local left, right = pair:match("(.+):(.+)")
      _2_, _3_ = left, right
    end
    if ((nil ~= _2_) and (nil ~= _3_)) then
      local k_13_auto = _2_
      local v_14_auto = _3_
      tbl_12_auto[k_13_auto] = v_14_auto
    else
    end
  end
  return tbl_12_auto
end
_2amodule_locals_2a["split-matchpairs"] = split_matchpairs
local function update_matchpairs()
  if (opts["cached-matchpairs"] ~= vim.o.matchpairs) then
    opts["cached-matchpairs"] = vim.o.matchpairs
    opts["matchpairs"] = {}
    for l, r in pairs(split_matchpairs()) do
      opts.matchpairs[l] = {left = l, right = r, backward = false}
      opts.matchpairs[r] = {left = l, right = r, backward = true}
    end
    return nil
  else
    return nil
  end
end
_2amodule_locals_2a["update-matchpairs"] = update_matchpairs
local function create_autocmds()
  if not augroup_exists(opts.augroup_name) then
    local group = nvim.create_augroup(opts.augroup_name, {})
    local function autocmd(events, callback, adds)
      local options = {group = group, callback = callback}
      if adds then
        options = vim.tbl_extend("error", options, adds)
        return nil
      else
        return nil
      end
    end
    local function _7_()
      return hl["pcall-update"]()
    end
    autocmd({"CursorMoved", "CursorMovedI", "WinEnter"}, _7_)
    local function _8_()
      return hl["pcall-update"](true)
    end
    autocmd("InsertEnter", _8_)
    local function _9_()
      return hl["update-on-tick"]()
    end
    autocmd({"TextChanged", "TextChangedI"}, _9_)
    local function _10_()
      return hl.remove()
    end
    autocmd({"WinLeave", "BufLeave"}, _10_)
    autocmd({"WinEnter", "BufWinEnter", "FileType"}, update_matchpairs)
    return autocmd("OptionSet", update_matchpairs, {pattern = "matchpairs"})
  else
    return nil
  end
end
_2amodule_locals_2a["create-autocmds"] = create_autocmds
local function delete_autocmds()
  if augroup_exists(opts.augroup_name) then
    return nvim.del_augroup_by_name(opts.augroup_name)
  else
    return nil
  end
end
_2amodule_locals_2a["delete-autocmds"] = delete_autocmds
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
local function create_commands()
  nvim.add_user_command("MatchParenEnable", enable, {})
  return nvim.add_user_command("MatchParenDisable", disable, {})
end
_2amodule_locals_2a["create-commands"] = create_commands
local function setup(config)
  disable_builtin()
  defaults.update(config)
  create_commands()
  create_namespace()
  update_matchpairs()
  do end (config)["extmarks"] = {current = 0, match = 0}
  if opts.on_startup then
    return create_autocmds()
  else
    return nil
  end
end
_2amodule_2a["setup"] = setup
return _2amodule_2a