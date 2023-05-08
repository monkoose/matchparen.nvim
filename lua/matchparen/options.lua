local defaults = {
  -- public
  on_startup = true,
  hl_group = 'MatchParen',
  augroup_name = 'matchparen',
  debounce_time = 200,
}

local options = { opts = defaults }

---Updates `options.opts` table with values from `new`
---@param new? table
function options:update(new)
  if not new then return end

  local defaults_keys = vim.tbl_keys(defaults)
  for option, value in pairs(new) do
    if vim.tbl_contains(defaults_keys, option) then
      self.opts[option] = value
    else
      vim.notify(
        'matchparen.nvim: Invalid option `' .. option .. '`.',
        vim.log.levels.WARN
      )
    end
  end
end

return options

-- vim:sw=2:et
