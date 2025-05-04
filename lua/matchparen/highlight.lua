local opts = require("matchparen.options").opts
local search = require("matchparen.search")

local hl = {}
local namespace = vim.api.nvim_create_namespace(opts.augroup_name)
local extmarks = { current = 0, match = 0 }

---@diagnostic disable-next-line: assign-type-mismatch
hl.timer = vim.uv.new_timer() ---@type uv.uv_timer_t
-- On failing creating a timer, just silently don't use debounce
if not hl.timer then opts.debounce_time = nil end

---Wrapper for nvim_buf_set_extmark()
---@param line integer 0-based line number
---@param col integer 0-based column number
local function set_extmark(line, col)
   return vim.api.nvim_buf_set_extmark(
      0,
      namespace,
      line,
      col,
      { end_col = col + 1, hl_group = opts.hl_group }
   )
end

---Add brackets highlight
---@param brackets {current: pos, match: pos}
local function hl_add(brackets)
   extmarks.current = set_extmark(brackets.current.line, brackets.current.col)
   extmarks.match = set_extmark(brackets.match.line, brackets.match.col)
end

---Removes brackets highlight by deleting buffer extmarks
function hl.remove()
   vim.api.nvim_buf_del_extmark(0, namespace, extmarks.current)
   vim.api.nvim_buf_del_extmark(0, namespace, extmarks.match)
end

---Highlights new brackets pair if any
local function highlight_brackets()
   local brackets = search.find_pair()
   hl.remove()
   if brackets then hl_add(brackets) end
end

---Updates the highlight of brackets by first removing previous highlight
---and then if there is matching brackets pair at the new cursor position highlight them
---@param in_insert boolean
function hl.update(in_insert)
   search.in_insert = in_insert

   if opts.debounce_time then
      hl.timer:stop()
      hl.timer:start(opts.debounce_time, 0, function()
         vim.schedule(function()
            highlight_brackets()
         end)
      end)
   else
      highlight_brackets()
   end
end

return hl
