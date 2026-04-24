local options = require("matchparen.options")

local api = vim.api
local fn = vim.fn
local opts = options.opts
local mp = {}
local augroup
local cached_matchpairs

---Returns table created by splitting vim `matchpairs` option
---with opening brackets as keys and closing brackets as values
---@return table
local function split_matchpairs()
   local result = {}
   local matchpairs_option = vim.split(cached_matchpairs, ",", { trimempty = true })
   for _, pair in ipairs(matchpairs_option) do
      local left, right = pair:match("(.+):(.+)")
      result[left] = right
   end
   return result
end

---Updates `matchpairs` opt only if it was changed,
---can be changed by buffer local option
local function update_matchpairs()
   local buf_matchpairs = vim.bo.matchpairs
   if cached_matchpairs == buf_matchpairs then return end

   cached_matchpairs = buf_matchpairs
   opts.matchpairs = {}
   for l, r in pairs(split_matchpairs()) do
      opts.matchpairs[l] = { left = l, right = r, backward = false }
      opts.matchpairs[r] = { left = l, right = r, backward = true }
   end
end

---Creates augroup and contained autocmds which are
---required for the plugin to work
local function create_autocmds()
   if augroup then return end

   augroup = api.nvim_create_augroup("matchparen.nvim", {})
   local hl = require("matchparen.highlight")

   ---@param ev string|string[]
   ---@param ot vim.api.keyset.create_autocmd
   local function autocmd(ev, ot)
      ot.group = augroup
      api.nvim_create_autocmd(ev, ot)
   end

   autocmd("InsertEnter", {
      callback = function()
         -- only for actual insert mode
         if vim.v.insertmode == "i" then
            opts.in_insert = true
            hl.update()
         end
      end,
      desc = "Highlight matching pairs",
   })

   autocmd("ModeChanged", {
      pattern = "i*:[^i]*",
      callback = function()
         opts.in_insert = false
      end,
   })

   autocmd({
      "WinEnter",
      "CursorMoved",
      "CursorMovedI",
      "TextChanged",
      -- "TextChangedI",
   }, {
      callback = function()
         hl.update()
      end,
      desc = "Highlight matching pairs",
   })

   autocmd({ "WinLeave", "BufLeave" }, {
      callback = function()
         hl.timer:stop()
         hl.remove()
      end,
      desc = "Hide matching pairs highlight",
   })

   autocmd({ "WinEnter", "BufWinEnter", "FileType" }, {
      callback = function()
         update_matchpairs()
      end,
      desc = "Update cache of matchpairs option",
   })

   autocmd("OptionSet", {
      pattern = "matchpairs",
      callback = function()
         update_matchpairs()
      end,
      desc = "Update cache of matchpairs option",
   })
end

---Deletes plugin's augroup and clears all it's autocmds
local function delete_autocmds()
   if augroup then api.nvim_del_augroup_by_id(augroup) end
   augroup = nil
end

---Disables built in matchparen plugin
local function disable_builtin()
   vim.g.loaded_matchparen = 1
   if fn.exists(":NoMatchParen") ~= 0 then
      vim.cmd("NoMatchParen")
      pcall(api.nvim_del_augroup_by_name, "matchparen")
   end
end

---Enables the plugin
local function enable()
   create_autocmds()
   update_matchpairs()
   require("matchparen.highlight").update()
end

---Disables the plugin
local function disable()
   delete_autocmds()
   require("matchparen.highlight").remove()
end

---Creates plugin's custom commands
local function create_commands()
   api.nvim_create_user_command("MatchParenEnable", enable, {})
   api.nvim_create_user_command("MatchParenDisable", disable, {})
end

---Initializes the plugin
---@param config MatchParenOptions
function mp.setup(config)
   disable_builtin()
   options:update(config)
   update_matchpairs()
   create_commands()

   if opts.enabled then
      create_autocmds()
      require("matchparen.highlight").update()
   end
end

return mp
