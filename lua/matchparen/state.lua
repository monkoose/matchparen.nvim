---@class MatchParenState
---@field in_insert boolean # `true` when in insert mode
---@field matchpairs table # Cached `matchpairs` neovim option
---@field highlighter vim.treesitter.highlighter|nil # Current treesitter highlighter
---@field remove_timer uv.uv_timer_t|nil # Timer to remove brackets highlight
return {
   in_insert = false,
   matchpairs = {},
   highlighter = nil,
   remove_timer = nil,
}
