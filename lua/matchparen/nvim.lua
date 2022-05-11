local _2afile_2a = "fnl/matchparen/nvim.fnl"
local function index(prefix)
  local function _1_(t, k)
    local func = vim.api[(prefix .. k)]
    if func then
      rawset(t, k, func)
    else
    end
    return func
  end
  return {__index = _1_}
end
return setmetatable({buf = setmetatable({}, index("nvim_buf_")), win = setmetatable({}, index("nvim_win_")), tab = setmetatable({}, index("nvim_tabpage_"))}, index("nvim_"))