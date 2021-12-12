return {
  on_startup = true,
  timeout = 150,
  timeout_insert = 50,
  hl_group = 'MatchParen',
  augroup_name = 'matchparen',

  -- Neovim builtin syntax names where the search for match parens would be skipped
  -- Not sure if we really need all of this just copied from matchparen plugin itself
  -- Here is the comment from Bram about this syntax names
  -- "We match 'escape' for special items, such as lispEscapeSpecial, and
  --  match "symbol" for lispBarSymbol."
  syn_skip_names = {
    'string',
    'comment',
    'character',
    'singlequoute',
    'escape',
    'symbol',
  },

  -- TreeSitter capture names where the search for match parens would be skipped
  ts_skip_captures = {
    'string',
    'comment'
  }
}
