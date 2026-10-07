---@class MatchParenState
---@field in_insert boolean # `true` when in insert mode
---@field matchpairs table # Cached `matchpairs` neovim option
---@field highlighter vim.treesitter.highlighter|nil # Current treesitter highlighter
return {
   in_insert = false,
   matchpairs = {},
   highlighter = nil,
}
