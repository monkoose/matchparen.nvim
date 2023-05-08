local defaults = {
  -- public
  on_startup = true,
  hl_group = 'MatchParen',
  augroup_name = 'matchparen',
  debounce_time = 200,
}

local options = defaults

---Updates `options` table with values from `new`
---@param new table
local function update_options(new)
  if not new then return end

  for option, value in pairs(new) do
    if vim.tbl_contains(defaults, option) then
      options[option] = value
    end
  end
end

return {
  opts = options,
  update = update_options
}

-- vim:sw=2:et
