local opts = require("matchparen.options").opts
local syntax = require("matchparen.syntax")
local ts = require("matchparen.treesitter")

local api = vim.api
local fn = vim.fn

---Determines what to do for the postion `line`, `col`.
---First return value answers if the position is to be skipped (continue the search).
---Second optional return value answers if the search should be stopped (break the search).
---@alias SkipFunction fun(line: integer, col: integer): boolean, boolean|nil

local M = {}
local namespace = api.nvim_create_namespace("matchparen.nvim")
---@type { current?: integer, match?: integer }
local extmarks = {}
local active_buf = 0
local active_co ---@type thread?
local remove_timer = assert(vim.uv.new_timer())

---Returns first found index and full match substring (if pattern
---is in a capture) in the `text` or nil
---@param text string
---@param pattern string
---@param init? integer same as in string.find
---@return integer|nil, string|nil
local function find_forward(text, pattern, init)
   local index, _, bracket = text:find(pattern, init and init + 1)
   return index, bracket
end

---Returns first backward index and full match substring in the `text` or nil
---@param reversed_text string
---@param pattern string
---@param init? integer same as in string.find
---@return integer|nil, string|nil
local function find_backward(reversed_text, pattern, init)
   local length = #reversed_text + 1
   local index, _, bracket = reversed_text:find(pattern, init and length - init + 1)
   if index then return length - index, bracket end
end

---Returns table of `count` lines starting from `start`
---@param start integer 0-based line number
---@param count integer number of lines to get
---@return string[]
local function get_lines(start, count)
   return api.nvim_buf_get_lines(0, start, start + count, false)
end

---Returns coroutine for finding `pattern` on the `line` and below
---Yields after each position check (match found or line advance)
---@param pattern string
---@param line integer 0-based line number
---@param col integer 0-based column number
---@param count integer number of lines to process
---@return thread
local function forward_matches(pattern, line, col, count)
   local curr_line = line
   local visible_count = 0
   local index = col + 1 ---@type integer?
   local lines = get_lines(curr_line, count)
   local idx = 1
   local text = lines[idx]

   return coroutine.create(function()
      while text do
         local capture
         index, capture = find_forward(text, pattern, index)
         if index then
            coroutine.yield(curr_line, index - 1, capture)
         else
            visible_count = visible_count + 1
            curr_line = curr_line + 1
            idx = idx + 1

            if opts.skip_folds then
               local fold_end = fn.foldclosedend(curr_line + 1)
               while fold_end ~= -1 do
                  local skipped = fold_end - curr_line
                  curr_line = fold_end
                  visible_count = visible_count + 1
                  idx = idx + skipped
                  fold_end = fn.foldclosedend(curr_line + 1)
               end
            else
               local fold_start = fn.foldclosed(curr_line + 1)
               if fold_start ~= -1 and fold_start ~= curr_line + 1 then
                  visible_count = visible_count - 1
               end
            end

            text = lines[idx]
            if not text and visible_count < count then
               lines = get_lines(curr_line, count - visible_count)
               idx = 1
               text = lines[idx]
            end

            coroutine.yield()
         end
      end
   end)
end

---@param lines string[]
---@param i integer
---@return string|nil
local function reverse_line(lines, i)
   return lines[i] and lines[i]:reverse()
end

---Returns coroutine for finding `pattern` on the `line` and above
---Yields after each position check (match found or line advance)
---@param pattern string
---@param line integer 0-based line number
---@param col integer 0-based column number
---@param count integer number of lines to process
---@return thread
local function backward_matches(pattern, line, col, count)
   local curr_line = line
   local visible_count = 0
   local index = col + 1 ---@type integer?

   local fetch_start = math.max(0, curr_line - count + 1)
   local lines = get_lines(fetch_start, curr_line - fetch_start + 1)
   local idx = #lines
   local reversed_text = reverse_line(lines, idx)

   return coroutine.create(function()
      while reversed_text do
         local capture
         index, capture = find_backward(reversed_text, pattern, index)
         if index then
            coroutine.yield(curr_line, index - 1, capture)
         else
            visible_count = visible_count + 1
            curr_line = curr_line - 1
            idx = idx - 1

            if opts.skip_folds then
               local fold_start = fn.foldclosed(curr_line + 1)
               while fold_start ~= -1 do
                  local target = fold_start - 2
                  local skipped = curr_line - target
                  curr_line = target
                  visible_count = visible_count + 1
                  idx = idx - skipped
                  fold_start = fn.foldclosed(curr_line + 1)
               end
            else
               local fold_end = fn.foldclosedend(curr_line + 1)
               if fold_end ~= -1 and fold_end ~= curr_line + 1 then
                  visible_count = visible_count - 1
               end
            end

            if curr_line < 0 then return end

            reversed_text = reverse_line(lines, idx)
            if not reversed_text and visible_count < count then
               local fetch_count = count - visible_count
               fetch_start = math.max(0, curr_line - fetch_count + 1)
               lines = get_lines(fetch_start, curr_line - fetch_start + 1)
               idx = #lines
               reversed_text = reverse_line(lines, idx)
            end

            coroutine.yield()
         end
      end
   end)
end

---Returns closure for finding balanced bracket
---@param left string opening bracket
---@param right string closing bracket
---@param backward boolean direction of the search
---@return fun(bracket: string): boolean
local function skip_same_bracket(left, right, backward)
   local count = 0
   local same_bracket = backward and right or left

   return function(bracket)
      if bracket == same_bracket then
         count = count + 1
      else
         if count == 0 then
            return false
         else
            count = count - 1
         end
      end
      return true
   end
end

---Returns 0-based current line and column
---@return integer, integer
local function get_cursor_pos()
   local pos = api.nvim_win_get_cursor(0)
   return pos[1] - 1, pos[2]
end

---Returns true if line is inside closed fold
---@param line integer 0-based line number
---@return boolean
local function is_inside_fold(line)
   return fn.foldclosed(line + 1) ~= -1
end

---Returns matched bracket option and its column or nil
---@param col integer 0-based column number
---@return table|nil, integer
local function get_bracket(col)
   local text = api.nvim_get_current_line()

   if col > 0 and opts.in_insert then
      local before_char = text:sub(col, col)
      if opts.matchpairs[before_char] then return opts.matchpairs[before_char], col - 1 end
   end

   local inc_col = col + 1
   local cursor_char = text:sub(inc_col, inc_col)
   return opts.matchpairs[cursor_char], col
end

---Schedules the search for the matching bracket
---@param co thread
---@param line integer 0-based cursor bracket line
---@param col integer 0-based cursor bracket column
---@param skip_fn SkipFunction
---@param callback fun(line?: integer, col?: integer, matchline?: integer, matchcol?: integer)
local function searchpair(co, line, col, skip_fn, callback)
   if active_co ~= co then return end

   local co_ok, found_line, found_col, capture = coroutine.resume(co)
   if not co_ok then
      callback()
      return
   end

   if found_line then
      -- pcall to catch errors in skip_fn (can be the case for vim.fn.synstack() used for syntax highlighting)
      local ok, skip, stop = pcall(skip_fn, found_line, found_col, capture)
      if not ok or stop then
         callback()
         return
      elseif not skip then
         if active_co == co then
            callback(line, col, found_line, found_col)
         else
            callback()
         end
         return
      end
   end

   vim.schedule(function()
      if coroutine.status(co) == "dead" then
         callback()
         return
      end
      searchpair(co, line, col, skip_fn, callback)
   end)
end

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
   if active_buf == api.nvim_get_current_buf() then
      M.remove()
      extmarks.current = set_extmark(line, col)
      extmarks.match = set_extmark(matchline, matchcol)
   end
end

---Removes brackets highlight by deleting buffer extmarks
function M.remove()
   if
      extmarks.current and api.nvim_buf_get_extmark_by_id(0, namespace, extmarks.current, {})[1]
   then
      api.nvim_buf_del_extmark(0, namespace, extmarks.current)
      api.nvim_buf_del_extmark(0, namespace, extmarks.match)
      extmarks.match = nil
      extmarks.current = nil
   end
end

---Updates the highlight of brackets by first removing previous highlight
---and then if there is matching brackets pair at the new cursor position highlight them
---@param bufnr? integer buffer number
function M.update(bufnr)
   active_co = nil

   if extmarks.current and not remove_timer:is_active() then
      remove_timer:start(200, 0, vim.schedule_wrap(M.remove))
   end

   active_buf = bufnr or api.nvim_get_current_buf()

   local line, col = get_cursor_pos()
   if is_inside_fold(line) then return end

   local mp
   mp, col = get_bracket(col)
   if not mp then return end

   ts.highlighter = ts.get_highlighter()

   local max_lines = api.nvim_win_get_height(0)
   local skip_bracket_fn = skip_same_bracket(mp.left, mp.right, mp.backward)
   local skip_region_fn = ts.highlighter and ts.skip_by_region(line, col, mp.backward)
      or syntax.skip_by_region(line, col)

   local skip_fn = function(l, c, bracket)
      local skip, stop = skip_region_fn(l, c)
      if skip or stop then return skip, stop end
      return skip_bracket_fn(bracket)
   end

   local matches = mp.backward and backward_matches or forward_matches
   local co = matches(mp.pattern, line, col, max_lines)
   active_co = co

   vim.schedule(function()
      searchpair(co, line, col, skip_fn, function(l, c, match_l, match_c)
         remove_timer:stop()
         if l then
            hl_add(l, c, match_l, match_c)
         else
            M.remove()
         end
      end)
   end)
end

return M
