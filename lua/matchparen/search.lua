local syntax = require('matchparen.syntax')
local ts = require('matchparen.treesitter')
local utils = require('matchparen.utils')
local opts = require('matchparen.options').opts
local win = require('missinvim').win

local M = {}

local function forward_matches(pattern, line, col, count)
  local lines = utils.get_lines(line, count)
  local i = 1
  local text = lines[i]
  local index = col + 1
  local capture

  return function()
    while text do
      index, capture = utils.find_forward(text, pattern, index)

      if index then
        local match_line = line + i - 1
        return match_line, index - 1, capture
      end

      i = i + 1
      text = lines[i]
    end
  end
end

local function backward_matches(pattern, line, col, count)
  local start = math.max(0, line - count)
  local lines = utils.get_lines(start, line - start + 1)
  local i = #lines
  local text = lines[i]
  local index = col + 1
  local capture
  local r_text

  return function()
    while text do
      r_text = string.reverse(text)
      index, capture = utils.find_backward(r_text, pattern, index)

      if index then
        -- TODO: check correct return
        local match_line = line - #lines + i
        return match_line, index - 1, capture
      end

      i = i - 1
      text = lines[i]
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
---@return number|nil, number
function M.match(pattern, line, col, backward, count, skip)
  skip = skip or function() end
  local ok, to_skip
  local matches = backward and backward_matches or forward_matches

  for l, c, capture in matches(pattern, line, col, count) do
    ok, to_skip = pcall(skip, l, c, capture)
    if not ok then return end

    if not to_skip then
      return l, c
    end
  end
end

---Returns line and column of a matched bracket
---@param left string
---@param right string
---@param line number 0-based line number
---@param col number 0-based column number
---@param backward boolean direction of the search
---@param skip function
---@return number|nil, number
function M.pair(left, right, line, col, backward, skip)
  local count = 0
  local pattern = '([' .. right .. left .. '])'
  local same_bracket = backward and right or left
  local max = win.get_height(0)
  local skip_same_bracket = function(bracket)
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

  local skip_fn
  if skip then
    skip_fn = function(l, c, bracket)
      return skip(l, c) or skip_same_bracket(bracket)
    end
  else
    skip_fn = function(_, _, bracket)
      return skip_same_bracket(bracket)
    end
  end

  return M.match(pattern, line, col, backward, max, skip_fn)
end

---Returns matched bracket position
---@param mp table
---@param line number line of `bracket`
---@param col number column of `bracket`
---@return number|nil, number
function M.match_pos(mp, line, col)
  local skip
  opts.cache.hl = ts.get_highlighter()

  -- try treesitter highlighting or fallback to regex syntax
  if opts.cache.hl then
    skip = ts.skip_and_stop(line, col, mp.backward)
  else
    skip = syntax.skip_by_region(line, col)
  end

  return M.pair(mp.left, mp.right, line, col, mp.backward, skip)
end

return M

-- vim:sw=2:et
