---@class MatchParenState
---@field in_insert boolean # `true` when in insert mode
---@field matchpairs table # Cached `matchpairs` neovim option
---@field highlighter vim.treesitter.highlighter|nil # Current treesitter highlighter
---@field remove_timer uv.uv_timer_t|nil # Timer to remove brackets highlight
---@field current_buf integer # Current buffer number
return {
   in_insert = false,
   matchpairs = {},
   highlighter = nil,
   remove_timer = nil,
   current_buf = -1,
}
