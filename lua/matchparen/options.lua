local defaults = {
  -- public
  on_startup = true,
  hl_group = 'MatchParen',
  augroup_name = 'matchparen',

  -- private
  cache = {},
}

local options = defaults
local public_options = {
  'on_startup',
  'hl_group',
  'augroup_name',
}

---Updates `options` table with values from `new`
---@param new table
local function update_options(new)
  if not new then return end

  for option, value in pairs(new) do
    if vim.tbl_contains(public_options, option) then
      options[option] = value
    end
  end
end

return {
  opts = options,
  update = update_options
}

-- vim:sw=2:et
