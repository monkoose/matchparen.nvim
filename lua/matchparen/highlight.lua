local opts = require("matchparen.options").opts
local search = require("matchparen.search")

local api = vim.api

local hl = {}
local namespace = api.nvim_create_namespace("matchparen.nvim")
local extmarks = { current = 0, match = 0 }

---@diagnostic disable-next-line: assign-type-mismatch
hl.timer = vim.uv.new_timer() ---@type uv.uv_timer_t
-- On failing creating a timer, just silently disable debouncing
if not hl.timer then opts.debounce_time = 0 end

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
function hl.remove()
   api.nvim_buf_del_extmark(0, namespace, extmarks.current)
   api.nvim_buf_del_extmark(0, namespace, extmarks.match)
end

---Highlights new brackets pair if any
local function highlight_brackets()
   local line, col, matchline, matchcol = search.find_pair()
   hl.remove()
   ---@diagnostic disable-next-line: param-type-mismatch
   if line then hl_add(line, col, matchline, matchcol) end
end

---Shedules highlighting of brackets to use as timer callback
local function debounced_highlight_brackets()
   vim.schedule(function()
      highlight_brackets()
   end)
end

---Updates the highlight of brackets by first removing previous highlight
---and then if there is matching brackets pair at the new cursor position highlight them
if opts.debounce_time and opts.debounce_time > 0 then
   function hl.update()
      hl.timer:stop()
      hl.timer:start(opts.debounce_time, 0, debounced_highlight_brackets)
   end
else
   function hl.update()
      highlight_brackets()
   end
end

return hl
