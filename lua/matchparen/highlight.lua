local opts = require("matchparen.options").opts
local search = require("matchparen.search")

local api = vim.api

local M = {}
local namespace = api.nvim_create_namespace("matchparen.nvim")
local extmarks = { current = 0, match = 0 }

---Wrapper for nvim_buf_set_extmark()
---@param line integer 0-based line number
---@param col integer 0-based column number
local function set_extmark(line, col)
   return api.nvim_buf_set_extmark(
      0,
      namespace,
      line,
      col,
      { end_col = col + 1, hl_group = opts.hl_group }
   )
end

---Add brackets highlight
---@param line integer 0-based line number
---@param col integer 0-based column number
---@param matchline integer 0-based line number
---@param matchcol integer 0-based column number
local function hl_add(line, col, matchline, matchcol)
   extmarks.current = set_extmark(line, col)
   extmarks.match = set_extmark(matchline, matchcol)
end

---Removes brackets highlight by deleting buffer extmarks
function M.remove()
   api.nvim_buf_del_extmark(0, namespace, extmarks.current)
   api.nvim_buf_del_extmark(0, namespace, extmarks.match)
end

---Updates the highlight of brackets by first removing previous highlight
---and then if there is matching brackets pair at the new cursor position highlight them
function M.update()
   M.remove()
   search.pair(hl_add)
end

return M
