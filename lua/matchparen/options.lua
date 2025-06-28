---@class MatchParenDefaultOptions
---@field enabled boolean # Determines whether the plugin should be enabled at neovim startup
---@field hl_group string
---@field debounce_time integer # Debounce time in milliseconds for rehighlighting brackets. `0` disables debouncing.
local defaults = {
   enabled = true,
   hl_group = "MatchParen",
   debounce_time = 60,
}

---@class MatchParenOptions : MatchParenDefaultOptions
---@field in_insert boolean # `true` when in insert mode
---@field matchpairs table # Cached `matchpairs` option

---@class OptionsTable
---@field opts MatchParenOptions|MatchParenDefaultOptions
---@field update fun(self: OptionsTable, new?: MatchParenDefaultOptions)
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
         vim.notify("matchparen.nvim: Invalid option `" .. option .. "`.", vim.log.levels.WARN)
      end
   end
end

return options
