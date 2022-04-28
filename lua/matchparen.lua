local options = require('matchparen.options')
local hl = require('matchparen.highlight')
local nvim = require('matchparen.missinvim')

local fn = vim.fn
local opts = options.opts
local mp = {}

---Returns true when augroup with `name` exists
---@param name string
---@return boolean
local function augroup_exists(name)
  return fn.exists('#' .. name) ~= 0
end

---Returns table created by splitting vim `matchpairs` option
---with opening brackets as keys and closing brackets as values
---@return table
local function split_matchpairs()
  local t = {}
  for _, pair in ipairs(vim.opt_local.matchpairs:get()) do
    local left, right = pair:match('(.+):(.+)')
    t[left] = right
  end
  return t
end

---Updates `matchpairs` opt only if it was changed,
---can be changed by buffer local option
local function update_matchpairs()
  if opts.cache.matchpairs == vim.bo.matchpairs then
    return
  end

  opts.cache.matchpairs = vim.bo.matchpairs
  opts.matchpairs = {}
  for l, r in pairs(split_matchpairs()) do
    opts.matchpairs[l] = { left = l, right = r, backward = false }
    opts.matchpairs[r] = { left = l, right = r, backward = true }
  end
end

---Creates augroup and contained autocmds which are
---required for the plugin to work
local function create_autocmds()
  if augroup_exists(opts.augroup_name) then return end

  local group = nvim.create_augroup(opts.augroup_name, {})
  local autocmd = function(event, callback, conf)
    local config = { group = group, callback = callback }
    if conf then
      config = vim.tbl_extend('error', config, conf)
    end
    nvim.create_autocmd(event, config)
  end

  autocmd('InsertEnter', function() hl.update(true) end)
  autocmd({ 'WinEnter', 'VimEnter' }, function() hl.update(false) end)
  autocmd({ 'CursorMoved', 'CursorMovedI' }, function() hl.update(false) end)
  autocmd({ 'TextChanged', 'TextChangedI' }, function() hl.update_on_tick() end)
  autocmd({ 'WinLeave', 'BufLeave' }, function() hl.hide() end)
  autocmd({ 'WinEnter', 'BufWinEnter', 'FileType' }, function() update_matchpairs() end)
  autocmd('OptionSet', function() update_matchpairs() end, { pattern = 'matchpairs' })
  autocmd({ 'BufDelete', 'BufUnload' }, function(t) hl.clear_extmarks(t.buf) end)
end

---Delets plugins augroup and clears all it's autocmds
local function delete_autocmds()
  if augroup_exists(opts.augroup_name) then
    nvim.del_augroup_by_name(opts.augroup_name)
  end
end

---Disables built in matchparen plugin
local function disable_builtin()
  vim.g.loaded_matchparen = 1
  if fn.exists(':NoMatchParen') ~= 0 then
    nvim.command('NoMatchParen')
  end
end

---Enables the plugin
local function enable()
  create_autocmds()
  update_matchpairs()
  hl.update(false)
end

---Disables the plugin
local function disable()
  delete_autocmds()
  hl.hide()
end

---Creates plugin's custom commands
local function create_commands()
  nvim.create_user_command('MatchParenEnable', enable, {})
  nvim.create_user_command('MatchParenDisable', disable, {})
end

---Initializes the plugin
---@param config table
function mp.setup(config)
  disable_builtin()
  options.update(config)
  opts.namespace = nvim.create_namespace(opts.augroup_name)
  update_matchpairs()
  create_commands()

  if opts.on_startup then
    create_autocmds()
  end
end

return mp

-- vim:sw=2:et
