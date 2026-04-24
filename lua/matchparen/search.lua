local syntax = require("matchparen.syntax")
local ts = require("matchparen.treesitter")
local opts = require("matchparen.options").opts

local api = vim.api
local fn = vim.fn

---Determines what to do for the postion `line`, `col`.
---First return value answers if the position is to be skipped (continue search).
---Second return value answers if the search should be stopped (break search).
---@alias SkipFunction fun(line: integer, col: integer): boolean, boolean

local M = {}

---Returns first found index and full match substring (if pattern
---is in a capture) in the `text` or nil
---@param text string
---@param pattern string
---@param init integer? same as in string.find
---@return integer|nil, string|nil
local function find_forward(text, pattern, init)
   local index, _, bracket = text:find(pattern, init and init + 1)
   return index, bracket
end

---Returns first backward index and full match substring in the `text` or nil
---@param reversed_text string
---@param pattern string
---@param init integer? same as in string.find
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

---Returns closure for finding `pattern` on the `line` and below
---@param pattern string
---@param line integer 0-based line number
---@param col integer 0-based column number
---@param count integer number of lines to process
---@return function
local function forward_matches(pattern, line, col, count)
   local lines = get_lines(line, count)
   local offset = line - 1
   local i = 1
   local text = lines[i]
   local index = col + 1 ---@type integer?
   local capture

   return function()
      while text do
         index, capture = find_forward(text, pattern, index)

         if index then return offset + i, index - 1, capture end

         i = i + 1
         text = lines[i]
      end
   end
end

---@param lines string[]
---@param i integer
---@return string
local function reverse_line(lines, i)
   return lines[i] and lines[i]:reverse()
end

---Returns closure for finding `pattern` on the `line` and above
---@param pattern string
---@param line integer 0-based line number
---@param col integer 0-based column number
---@param count integer number of lines to process
---@return function
local function backward_matches(pattern, line, col, count)
   local start = math.max(0, line - count)
   local lines = get_lines(start, line - start + 1)
   local offset = line - #lines
   local i = #lines
   local index = col + 1 ---@type integer?
   local capture
   local reversed_text = reverse_line(lines, i)

   return function()
      while reversed_text do
         index, capture = find_backward(reversed_text, pattern, index)

         if index then return offset + i, index - 1, capture end

         i = i - 1
         reversed_text = reverse_line(lines, i)
      end
   end
end

---Returns closure for finding balanced bracket
---@param left string opening bracket
---@param right string closing bracket
---@param backward boolean direction of the search
---@return fun(bracket: string): boolean, boolean
local function skip_same_bracket(left, right, backward)
   local count = 0
   local same_bracket = backward and right or left

   return function(bracket)
      if bracket == same_bracket then
         count = count + 1
      else
         if count == 0 then
            return false, false
         else
            count = count - 1
         end
      end
      return true, false
   end
end

---Returns matched bracket position
---@param mp table
---@param line integer line of `bracket`
---@param col integer column of `bracket`
---@return integer|nil, integer|nil
local function find_match_pos(mp, line, col)
   ts.highlighter = ts.get_highlighter()

   local pattern = "([" .. mp.right .. mp.left .. "])"
   local max = api.nvim_win_get_height(0)
   local skip_bracket_fn = skip_same_bracket(mp.left, mp.right, mp.backward)

   local skip_region_fn = ts.highlighter and ts.skip_by_region(line, col, mp.backward)
      or syntax.skip_by_region(line, col)

   local skip_fn = function(l, c, bracket)
      local skip, stop = skip_region_fn(l, c)
      if skip or stop then
         return skip, stop
      else
         return skip_bracket_fn(bracket)
      end
   end

   local matches_iter = mp.backward and backward_matches or forward_matches
   for l, c, capture in matches_iter(pattern, line, col, max) do
      -- pcall because some skip functions can be errorness
      -- like `synstack()` for syntax
      local ok, skip, stop = pcall(skip_fn, l, c, capture)
      if not ok or stop then
         return
      elseif not skip then
         return l, c
      end
   end
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

---Returns matched pair data or nil if there is no match
---@return integer?, integer?, integer?, integer?
function M.pair()
   local line, col = get_cursor_pos()
   if is_inside_fold(line) then return end

   local match_bracket, bracket_col = get_bracket(col)
   if not match_bracket then return end

   local matchline, matchcol = find_match_pos(match_bracket, line, bracket_col)
   if not matchline then return end

   return line, bracket_col, matchline, matchcol
end

return M
