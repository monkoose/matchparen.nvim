---@class MatchParenOptions
---@field enabled boolean # Determines whether the plugin should be enabled at neovim startup
---@field hl_group string
---@field skip_folds boolean # Determines whether the plugin should skip closed folds
local defaults = {
   enabled = true,
   hl_group = "MatchParen",
   skip_folds = true,
}

local M = {}
---@type MatchParenOptions
M.opts = vim.tbl_extend("force", {}, defaults)

---@param new? MatchParenOptions
function M.set(new)
   if not new then return end

   for option, value in pairs(new) do
      if defaults[option] ~= nil then
         M.opts[option] = value
      else
         vim.notify("matchparen.nvim: Invalid option `" .. option .. "`.", vim.log.levels.WARN)
      end
   end
end

return M
