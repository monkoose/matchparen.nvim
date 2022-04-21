local options = require('matchparen.options')
local hl = require('matchparen.highlight')
local nvim = require('missinvim')

local fn = vim.fn
local opts = options.opts
local M = {}

---Returns true when augroup with `name` exists.
---@param name string
---@return boolean
local function augroup_exists(name)
  return fn.exists('#' .. name) ~= 0
end

---Returns table created by splitting vim `matchpairs` option
---with opening brackets as keys and closing brackets as values.
---@return table
local function split_matchpairs()
  local t = {}
  for _, pair in ipairs(vim.opt.matchpairs:get()) do
    local left, right = pair:match('(.+):(.+)')
    t[left] = right
  end
  return t
end

---Updates `matchpairs` opt only if it was changed,
---can be changed by buffer local option
local function update_matchpairs()
  if opts.cache.matchpairs == vim.o.matchpairs then
    return
  end

  opts.cached_matchpairs = vim.o.matchpairs
  opts.matchpairs = {}
  for l, r in pairs(split_matchpairs()) do
    opts.matchpairs[l] = { left = l, right = r, backward = false }
    opts.matchpairs[r] = { left = l, right = r, backward = true }
  end
end

---Creates augroup and contained autocmds which are
---required for the plugin to work.
local function create_autocmds()
  if augroup_exists(opts.augroup_name) then return end

  local group = nvim.create_augroup(opts.augroup_name, {})
  local autocmd = function(event, callback, conf)
    local config = { group = group, callback = callback }
    if conf then
      config = vim.tbl_extend('error',
        { group = group, callback = callback }, conf)
    end
    nvim.create_autocmd(event, config)
  end

  autocmd('InsertEnter', function() hl.update(true) end)
  autocmd({ 'CursorMoved', 'CursorMovedI', 'WinEnter' }, hl.update)
  autocmd({ 'TextChanged', 'TextChangedI' }, hl.update_on_tick)
  autocmd({ 'WinLeave', 'BufLeave' }, hl.remove)
  autocmd({ 'WinEnter', 'BufWinEnter', 'FileType' }, update_matchpairs)
  autocmd('OptionSet', update_matchpairs, { pattern = 'matchpairs' })
end

---Delets plugins augroup and clears all it's autocmds.
local function delete_autocmds()
  if augroup_exists(opts.augroup_name) then
    nvim.del_augroup_by_name(opts.augroup_name)
  end
end

---Disables built in matchparen plugin.
local function disable_builtin()
  vim.g.loaded_matchparen = 1
  if fn.exists(":NoMatchParen") ~= 0 then
    nvim.command("NoMatchParen")
  end
end

---Enables the plugin.
local function enable()
  create_autocmds()
  update_matchpairs()
  hl.update()
end

---Disables the plugin.
local function disable()
  delete_autocmds()
  hl.remove()
end

---Creates plugin's custom commands.
local function create_commands()
  nvim.create_user_command('MatchParenEnable', enable, {})
  nvim.create_user_command('MatchParenDisable', disable, {})
end

---Initializes the plugin.
---@param config table
function M.setup(config)
  disable_builtin()
  options.update(config)
  opts.cache = {}
  opts.namespace = nvim.create_namespace(opts.augroup_name)
  opts.extmarks = { current = 0, match = 0 }
  update_matchpairs()
  create_commands()

  if opts.on_startup then
    create_autocmds()
  end
end

return M

-- vim:sw=2:et
