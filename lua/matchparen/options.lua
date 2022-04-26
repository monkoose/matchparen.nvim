local defaults = {
  -- public
  on_startup = true,
  hl_group = 'MatchParen',
  augroup_name = 'matchparen',

  -- private
  cache = {},
  extmarks = {},
  -- Neovim builtin syntax names to limit search only for this range
  -- Not sure if we really need all of this just copied from matchparen plugin itself
  -- Here is the comment from Bram about this syntax names
  -- "We match 'escape' for special items, such as lispEscapeSpecial, and
  --  match "symbol" for lispBarSymbol."
  syntax_skip = {
    'string',
    'comment',
    'character',
    'singlequote',
    'escape',
    'symbol',
  },
  -- TreeSitter names to limit search only in this range
  treesitter_skip = {
    'string',
    'comment',
  }
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
