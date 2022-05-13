-- This module adds missing nvim table of neovim

local function index(prefix)
  return {
    __index = function(t, k)
      local f = vim.api[prefix .. k]
      if f then
        rawset(t, k, f)
      end
      return f
    end
  }
end

return setmetatable({
  buf = setmetatable({}, index('nvim_buf_')),
  win = setmetatable({}, index('nvim_win_')),
  tab = setmetatable({}, index('nvim_tabpage_')),
}, index('nvim_'))

-- vim:sw=2:et
