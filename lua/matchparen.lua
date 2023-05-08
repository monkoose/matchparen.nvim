local options = require('matchparen.options')
local hl = require('matchparen.highlight')

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
  local matchpairs_option = vim.opt_local.matchpairs:get() ---@type string[]
  for _, pair in ipairs(matchpairs_option) do
    local left, right = pair:match('(.+):(.+)')
    t[left] = right
  end
  return t
end

---Updates `matchpairs` opt only if it was changed,
---can be changed by buffer local option
local function update_matchpairs()
  if opts.cached_matchpairs == vim.bo.matchpairs then
    return
  end

  opts.cached_matchpairs = vim.bo.matchpairs
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

  local group = vim.api.nvim_create_augroup(opts.augroup_name, {})
  local autocmd = function(event, callback, conf)
    local config = { group = group, callback = callback }
    if conf then
      config = vim.tbl_extend('error', config, conf)
    end
    vim.api.nvim_create_autocmd(event, config)
  end

  autocmd('InsertEnter', function() hl.update(true) end, {
    desc = "Highlight matching pairs",
  })
  autocmd({
    'WinEnter',
    'CursorMoved',
    'CursorMovedI',
    'TextChanged',
    'TextChangedI',
  }, function() hl.update(false) end, { desc = "Highlight matching pairs" })
  autocmd({ 'WinLeave', 'BufLeave' }, function() hl.remove() end, {
    desc = "Hide matching pairs highlight",
  })
  autocmd({ 'WinEnter', 'BufWinEnter', 'FileType' }, function() update_matchpairs() end, {
    desc = "Update cache of matchpairs option",
  })
  autocmd('OptionSet', function() update_matchpairs() end, {
    pattern = 'matchpairs',
    desc = "Update cache of matchpairs option",
  })
end

---Deletes plugin's augroup and clears all it's autocmds
local function delete_autocmds()
  if augroup_exists(opts.augroup_name) then
    vim.api.nvim_del_augroup_by_name(opts.augroup_name)
  end
end

---Disables built in matchparen plugin
local function disable_builtin()
  vim.g.loaded_matchparen = 1
  if fn.exists(':NoMatchParen') ~= 0 then
    vim.cmd('NoMatchParen')
  end
  delete_autocmds()
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
  hl.remove()
end

---Creates plugin's custom commands
local function create_commands()
  vim.api.nvim_create_user_command('MatchParenEnable', enable, {})
  vim.api.nvim_create_user_command('MatchParenDisable', disable, {})
end

---Initializes the plugin
---@param config table
function mp.setup(config)
  disable_builtin()
  options:update(config)
  update_matchpairs()
  create_commands()

  if opts.on_startup then
    create_autocmds()
    hl.update(false)
  end
end

return mp

-- vim:sw=2:et
