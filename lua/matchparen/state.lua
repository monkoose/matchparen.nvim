---@class MatchParenState
---@field id integer # Current search id. It is general validator to prevent race conditions
---@field in_insert boolean # `true` when in insert mode
---@field matchpairs table<string, MatchPairTable> # Cached `matchpairs` neovim option
return {
   id = 0,
   in_insert = false,
   matchpairs = {},
}
