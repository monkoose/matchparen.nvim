local utils = require('matchparen.utils')

local fn = vim.fn
local syntax = {}
local syntax_skip = {
  'string',
  'comment',
  'character',
  'singlequote',
  'doublequote',
  -- 'escape',
  -- 'symbol',
}

---Returns true when built in syntax is on and
---current buffer has syntax for its filetype
---@return boolean
local function is_syntax_on()
  return vim.g.syntax_on == 1 and vim.b.current_syntax
end

---Returns name of the syntax id group
---@param synid integer
---@return string
local function get_synname(synid)
  return string.lower(fn.synIDattr(synid, 'name'))
end

---Returns table with last three syntax ids
---under the `line` `col` position in the current buffer
---@param line integer 0-based line number
---@param col integer 0-based column number
---@return integer[]
local function last3_synids(line, col)
  local synstack = fn.synstack(line + 1, col + 1)
  local len = #synstack
  -- last three ids should be more than enough to determine
  -- if syntax under the cursor belongs to some syntax group
  -- at least for such groups like comment and string
  -- which don't have a lot of nested groups
  return {
    synstack[len],
    synstack[len - 1],
    synstack[len - 2],
  }
end

---Returns true when the cursor is inside any of `syntax_skip` groups
---@param line integer 0-based line number
---@param col integer 0-based column number
---@return boolean
local function is_syntax_skip_region(line, col)
  if utils.is_inside_fold(line) then
    return false
  end

  for _, synid in ipairs(last3_synids(line, col)) do
    local synname = get_synname(synid)
    if utils.str_contains_any(synname, syntax_skip) then
      return true
    end
  end
  return false
end

---Returns skip function for `search.match_pos()`
---@param line integer 0-based line number
---@param col integer 0-based column number
---@return function|nil
function syntax.skip_by_region(line, col)
  if not is_syntax_on() then return end

  if is_syntax_skip_region(line, col) then
    return function(l, c)
      if is_syntax_skip_region(l, c) then
        return { skip = false }
      else
        return { skip = true }
      end
    end
  else
    return function(l, c)
      if is_syntax_skip_region(l, c) then
        return { skip = true }
      else
        return { skip = false }
      end
    end
  end
end

return syntax

-- vim:sw=2:et
