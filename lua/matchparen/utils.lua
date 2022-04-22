local nvim = require('missinvim')

local win = nvim.win
local buf = nvim.buf
local fn = vim.fn
local M = { error = nil }

---Determines whether a search should stop if searched line outside of range
---@param line number 0-based line number
---@param backward boolean direction of the search
---@return function
function M.limit_by_line(line, backward)
  local stopline
  local win_height = win.get_height(0)
  if backward then
    stopline = line - win_height
    return function(l)
      return l < stopline
    end
  else
    stopline = line + win_height
    return function(l)
      return l > stopline
    end
  end
end

---Returns true if line is inside closed fold
---@param line number 0-based line number
---@return boolean
function M.inside_closed_fold(line)
  return fn.foldclosed(line + 1) ~= -1
end

---Returns true when current mode is insert or Replace
---@return boolean
function M.is_in_insert_mode()
  local mode = nvim.get_mode().mode
  return mode == 'i' or mode == 'R'
end

---Returns true if `str` constains `pattern`, false otherwise
---@param str string
---@param pattern string
---@return boolean
function M.str_contains(str, pattern)
  return str:find(pattern, 1, true) ~= nil
end

---Returns true when `str` contains any element from the `tbl`
---@param str string
---@param tbl string[]
---@return boolean
function M.str_contains_any(str, tbl)
  for _, pattern in ipairs(tbl) do
    if M.str_contains(str, pattern) then
      return true
    end
  end
  return false
end

---Returns 0-based current line and column
---@return number, number
function M.get_current_pos()
  local line, column = unpack(win.get_cursor(0))
  return line - 1, column
end

---Returns first found index and full match substring (if pattern
---is in a capture) in the `text` or nil
---@param text string
---@param pattern string
---@param init number same as in string.find
---@return number|nil, string
function M.find_forward(text, pattern, init)
  local index, _, bracket = string.find(text, pattern, init and init + 1)
  return index, bracket
end

---Returns first backward index and full match substring in the `text` or nil
---@param reversed_text string
---@param pattern string
---@param init number same as in string.find
---@return number|nil, string
function M.find_backward(reversed_text, pattern, init)
  local length = #reversed_text + 1
  local index, bracket = M.find_forward(reversed_text, pattern, init and length - init)
  if index then
    return length - index, bracket
  end
end

---Returns table of `count` lines starting from `start`
---@param start integer 0-based line number
---@return string[]
function M.get_lines(start, count)
  return buf.get_lines(0, start, start + count, false)
end

return M

-- vim:sw=2:et
