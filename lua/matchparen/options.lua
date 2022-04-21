local defaults = {
  on_startup = true,
  hl_group = 'MatchParen',
  augroup_name = 'matchparen',

  -- Neovim builtin syntax names to limit search only for this range
  -- Not sure if we really need all of this just copied from matchparen plugin itself
  -- Here is the comment from Bram about this syntax names
  -- "We match 'escape' for special items, such as lispEscapeSpecial, and
  --  match "symbol" for lispBarSymbol."
  syntax_skip_groups = {
    'string',
    'comment',
    'character',
    'singlequoute',
    'escape',
    'symbol',
  },

  -- TreeSitter names to limit search only in this range
  ts_skip_groups = {
    'string',
    'comment',
  }
}

local options = defaults

---Updates `options` table with values from `new_options`
---@param new_options table
local function update_options(new_options)
  for option, value in pairs(new_options) do
    if options[option] then
      options[option] = value
    end
  end
end

return {
  opts = options,
  update = update_options
}

-- vim:sw=2:et
