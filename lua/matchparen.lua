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
local a, hl, nvim, options = autoload("matchparen.aniseed.core"), autoload("matchparen.highlight"), autoload("matchparen.aniseed.nvim"), autoload("matchparen.options")
do end (_2amodule_locals_2a)["a"] = a
_2amodule_locals_2a["hl"] = hl
_2amodule_locals_2a["nvim"] = nvim
_2amodule_locals_2a["options"] = options
local f = vim.fn
_2amodule_locals_2a["f"] = f
local opts = options.opts
_2amodule_locals_2a["opts"] = opts
local function augroup_exists(name)
  return (0 ~= f.exists(("#" .. name)))
end
_2amodule_locals_2a["augroup-exists"] = augroup_exists
local function command_exists(name)
  return (0 ~= f.exists((":" .. name)))
end
_2amodule_locals_2a["command-exists"] = command_exists
local function split_matchpairs()
  local tbl_12_auto = {}
  for _, pair in ipairs((vim.opt.matchpairs):get()) do
    local _1_, _2_ = nil, nil
    do
      local left, right = pair:match("(.+):(.+)")
      _1_, _2_ = left, right
    end
    if ((nil ~= _1_) and (nil ~= _2_)) then
      local k_13_auto = _1_
      local v_14_auto = _2_
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
    for left, right in pairs(split_matchpairs()) do
      opts.matchpairs[left] = {left = left, right = right, backward = false}
      opts.matchpairs[right] = {left = left, right = right, backward = true}
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
    local function autocmd(events, callback, conf)
      local options0 = {group = group, callback = callback}
      if conf then
        return a["merge!"](options0, conf)
      else
        return nil
      end
    end
    local function _6_()
      return hl.update(true)
    end
    autocmd("InsertEnter", _6_)
    local function _7_()
      return hl.update()
    end
    autocmd({"VimEnter", "WinEnter"}, _7_)
    local function _8_()
      return hl.update()
    end
    autocmd({"CursorMoved", "CursorMovedI"}, _8_)
    local function _9_()
      return hl["update-on-tick"]()
    end
    autocmd({"TextChanged", "TextChangedI"}, _9_)
    local function _10_()
      return hl.hide()
    end
    autocmd({"WinLeave", "BufLeave"}, _10_)
    local function _11_()
      return update_matchpairs()
    end
    autocmd({"WinEnter", "BufWinEnter", "FileType"}, _11_)
    local function _12_()
      return update_matchpairs()
    end
    autocmd("OptionSet", _12_, {pattern = "matchpairs"})
    local function _13_(_241)
      return hl["clear-extmarks"](_241.buf)
    end
    return autocmd({"BufDelete", "BufUnload"}, _13_)
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
local function disable_builtin()
  vim.g.loaded_matchparen = 1
  if command_exists("NoMatchParen") then
    return nvim.command("NoMatchParen")
  else
    return nil
  end
end
_2amodule_locals_2a["disable-builtin"] = disable_builtin
local function enable()
  create_autocmds()
  update_matchpairs()
  return hl.update()
end
_2amodule_locals_2a["enable"] = enable
local function disable()
  delete_autocmds()
  return hl.hide()
end
_2amodule_locals_2a["disable"] = disable
local function create_namespace()
  opts["namespace"] = nvim.create_namespace(opts.augroup_name)
  return nil
end
_2amodule_locals_2a["create-namespace"] = create_namespace
local function create_commands()
  nvim.create_user_command("MatchParenEnable", enable, {})
  return nvim.create_user_command("MatchParenDisable", disable, {})
end
_2amodule_locals_2a["create-commands"] = create_commands
local function setup(config)
  disable_builtin()
  a["merge!"](opts, config)
  create_namespace()
  update_matchpairs()
  create_commands()
  if opts.on_startup then
    return create_autocmds()
  else
    return nil
  end
end
_2amodule_2a["setup"] = setup
return _2amodule_2a