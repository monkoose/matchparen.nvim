-- This module adds missing nvim table of neovim

local api = vim.api

return setmetatable({
  buf = setmetatable({}, {
    __index = function(t, k)
      local f = api['nvim_buf_' .. k]
      if f then
        rawset(t, k, f)
      end
      return f
    end
  }),
  win = setmetatable({}, {
    __index = function(t, k)
      local f = api['nvim_win_' .. k]
      if f then
        rawset(t, k, f)
      end
      return f
    end
  }),
  tab = setmetatable({}, {
    __index = function(t, k)
      local f = api['nvim_tabpage_' .. k]
      if f then
        rawset(t, k, f)
      end
      return f
    end
  }),
}, {
  __index = function(t, k)
    local f = api['nvim_' .. k]
    if f then
      rawset(t, k, f)
    end
    return f
  end
})

-- vim:sw=2:et
