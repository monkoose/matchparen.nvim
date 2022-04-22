local opts = require('matchparen.options').opts
local utils = require('matchparen.utils')

local fn = vim.fn
local syntax = {}

---Returns true when built in syntax is on and
---current buffer has syntax for its filetype
---@return boolean
local function is_syntax_on()
  return vim.g.syntax_on == 1 and vim.o.syntax ~= ''
end

---Returns name of the syntax id group
---@param synid integer
---@return string
local function get_synname(synid)
  return string.lower(fn.synIDattr(synid, 'name'))
end

---Returns iterator with the last three syntax group names
---under the `line` `col` position in the current buffer
---@param line number 0-based line number
---@param col number 0-based column number
---@return function
local function last3_synnames(line, col)
  local synstack = fn.synstack(line + 1, col + 1)
  local len = #synstack
  local last3 = {
    synstack[len],
    synstack[len - 1],
    synstack[len - 2],
  }
  local i = 0

  return function()
    i = i + 1
    if i <= #last3 then
      return get_synname(last3[i])
    end
  end
end

---Determines whether the cursor is inside neovim syntax id name
---that match any value in `syntax_skip_groups` option list
---@param line number 0-based line number
---@param col number 0-based column number
---@return boolean
local function is_syntax_skip_region(line, col)
  if utils.inside_closed_fold(line) then
    return false
  end

  for synname in last3_synnames(line, col) do
    if utils.str_contains_any(synname,
        opts.syntax_skip_groups) then
      return true
    end
  end
  return false
end

---Returns skip function for `search.match_pos()`
---@param line number 0-based line number
---@param col number 0-based column number
---@return function|nil
function syntax.skip_by_region(line, col)
  if not is_syntax_on() then return end

  if is_syntax_skip_region(line, col) then
    return function(l, c)
      return is_syntax_skip_region(l, c) and 0 or 1
    end
  else
    return function(l, c)
      return is_syntax_skip_region(l, c) and 1 or 0
    end
  end
end

return syntax

-- vim:sw=2:et
