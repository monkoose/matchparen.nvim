local syntax = require("matchparen.syntax")
local ts = require("matchparen.treesitter")
local utils = require("matchparen.utils")
local opts = require("matchparen.options").opts

local search = { in_insert = false }

---@alias pos { line: integer, col: integer }

---Returns closure for finding `pattern` on the `line` and below
---@param pattern string
---@param line integer 0-based line number
---@param col integer 0-based column number
---@param count integer number of lines to process
---@return function
local function forward_matches(pattern, line, col, count)
   local lines = utils.get_lines(line, count)
   local offset = line - 1
   local i = 1
   local text = lines[i]
   local index = col + 1 ---@type integer?
   local capture

   return function()
      while text do
         index, capture = utils.find_forward(text, pattern, index)

         if index then return offset + i, index - 1, capture end

         i = i + 1
         text = lines[i]
      end
   end
end

---Returns closure for finding `pattern` on the `line` and above
---@param pattern string
---@param line integer 0-based line number
---@param col integer 0-based column number
---@param count integer number of lines to process
---@return function
local function backward_matches(pattern, line, col, count)
   local start = math.max(0, line - count)
   local lines = utils.get_lines(start, line - start + 1)
   local offset = line - #lines
   local i = #lines
   local index = col + 1 ---@type integer?
   local capture
   local reversed_text = lines[i] and string.reverse(lines[i])

   return function()
      while reversed_text do
         index, capture = utils.find_backward(reversed_text, pattern, index)

         if index then return offset + i, index - 1, capture end

         i = i - 1
         reversed_text = lines[i] and string.reverse(lines[i])
      end
   end
end

---Returns positon of the first match of the `pattern` in the current buffer
---starting from `line` and `col`
---@param pattern string
---@param line integer 0-based line number
---@param col integer 0-based column number
---@param backward boolean direction of the search
---@param count integer number of lines to search
---@param skip function
---@return number|nil, number|nil
function search.match(pattern, line, col, backward, count, skip)
   skip = skip or function()
      return { skip = false }
   end
   local matches = backward and backward_matches or forward_matches

   for l, c, capture in matches(pattern, line, col, count) do
      -- pcall because some skip functions can be errorness
      -- like `synstack()` for syntax
      local ok, to = pcall(skip, l, c, capture)
      if not ok then return end

      if to.stop then
         return
      elseif not to.skip then
         return l, c
      end
   end
end

---Returns closure for finding balanced bracket
---@param left string opening bracket
---@param right string closing bracket
---@param backward boolean direction of the search
---@return function
local function skip_same_bracket(left, right, backward)
   local count = 0
   local same_bracket = backward and right or left

   return function(bracket)
      if bracket == same_bracket then
         count = count + 1
      else
         if count == 0 then
            return { skip = false }
         else
            count = count - 1
         end
      end
      return { skip = true }
   end
end

---Returns line and column of a matched bracket
---@param left string
---@param right string
---@param line integer 0-based line number
---@param col integer 0-based column number
---@param backward boolean direction of the search
---@param skip? function
---@return integer|nil, integer|nil
function search.pair(left, right, line, col, backward, skip)
   local pattern = "([" .. right .. left .. "])"
   local max = vim.api.nvim_win_get_height(0)
   local skip_bracket = skip_same_bracket(left, right, backward)

   local skip_fn
   if skip then
      skip_fn = function(l, c, bracket)
         local s = skip(l, c)
         if s.stop or s.skip then
            return s
         else
            return skip_bracket(bracket)
         end
      end
   else
      skip_fn = function(_, _, bracket)
         return skip_bracket(bracket)
      end
   end

   return search.match(pattern, line, col, backward, max, skip_fn)
end

---Returns matched bracket position
---@param mp table
---@param line integer line of `bracket`
---@param col integer column of `bracket`
---@return integer|nil, integer|nil
function search.match_pos(mp, line, col)
   local skip
   ts.highlighter = ts.get_highlighter()

   -- try treesitter highlighting or fallback to regex syntax
   if ts.highlighter then
      skip = ts.skip_by_region(line, col, mp.backward)
   else
      skip = syntax.skip_by_region(line, col)
   end

   return search.pair(mp.left, mp.right, line, col, mp.backward, skip)
end

---Returns matched bracket option and its column or nil
---@param col integer 0-based column number
---@return table|nil, integer
local function get_bracket(col)
   local text = vim.api.nvim_get_current_line()
   search.in_insert = search.in_insert or utils.is_in_insert_mode()

   if col > 0 and search.in_insert then
      local before_char = text:sub(col, col)
      if opts.matchpairs[before_char] then return opts.matchpairs[before_char], col - 1 end
   end

   local inc_col = col + 1
   local cursor_char = text:sub(inc_col, inc_col)
   return opts.matchpairs[cursor_char], col
end

---Returns matched pair data or nil if there is no match
---@return { current: pos, match: pos }|nil
function search.find_pair()
   local line, col = utils.get_cursor_pos()
   if utils.is_inside_fold(line) then return nil end

   local match_bracket, bracket_col = get_bracket(col)
   if not match_bracket then return nil end

   local matchline, matchcol = search.match_pos(match_bracket, line, bracket_col)
   if not matchline then return nil end

   return {
      current = { line = line, col = bracket_col },
      match = { line = matchline, col = matchcol or 0 },
   }
end

return search
