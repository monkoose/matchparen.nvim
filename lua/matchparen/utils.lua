local fn = vim.fn
local utils = {}

---Returns true if line is inside closed fold
---@param line integer 0-based line number
---@return boolean
function utils.is_inside_fold(line)
   return fn.foldclosed(line + 1) ~= -1
end

---Returns true when current mode is insert or Replace
---@return boolean
function utils.is_in_insert_mode()
   local mode = vim.api.nvim_get_mode().mode
   return mode == "i" or mode == "R"
end

---Returns true if `str` constains `pattern`, false otherwise
---@param str string
---@param pattern string
---@return boolean
function utils.str_contains(str, pattern)
   return str:find(pattern, 1, true) ~= nil
end

---Returns true when `str` contains any element from the `tbl`
---@param str string
---@param tbl string[]
---@return boolean
function utils.str_contains_any(str, tbl)
   for _, pattern in ipairs(tbl) do
      if utils.str_contains(str, pattern) then return true end
   end
   return false
end

---Returns 0-based current line and column
---@return integer, integer
function utils.get_cursor_pos()
   local line, column = unpack(vim.api.nvim_win_get_cursor(0))
   return line - 1, column
end

---Returns first found index and full match substring (if pattern
---is in a capture) in the `text` or nil
---@param text string
---@param pattern string
---@param init integer? same as in string.find
---@return integer|nil, string|nil
function utils.find_forward(text, pattern, init)
   local index, _, bracket = string.find(text, pattern, init and init + 1)
   return index, bracket
end

---Returns first backward index and full match substring in the `text` or nil
---@param reversed_text string
---@param pattern string
---@param init integer? same as in string.find
---@return integer|nil, string|nil
function utils.find_backward(reversed_text, pattern, init)
   local length = #reversed_text + 1
   local index, bracket = utils.find_forward(reversed_text, pattern, init and length - init)
   if index then return length - index, bracket end
end

---Returns table of `count` lines starting from `start`
---@param start integer 0-based line number
---@param count integer number of lines to get
---@return string[]
function utils.get_lines(start, count)
   return vim.api.nvim_buf_get_lines(0, start, start + count, false)
end

return utils
