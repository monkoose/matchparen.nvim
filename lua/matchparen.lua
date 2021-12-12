local defaults = require('matchparen.defaults')

local a = vim.api
local f = vim.fn
local max = math.max

-- Global variables
local cached_matchpairs_opt

local M = {}

-- Setup
function M.setup(options)
  M.config = vim.tbl_deep_extend('force', defaults, options or {})

  M.namespace = a.nvim_create_namespace(M.config.augroup_name)
  M.extmarks = { current = 0, match = 0 }
  M.matchpairs = {}

  if M.config.on_startup then
    M.enable_autocmds()
  end
end

function M.enable_autocmds()
  if f.exists('#' .. M.config.augroup_name) == 0 then
    vim.cmd('augroup ' .. M.config.augroup_name)
    vim.cmd [[
        autocmd!
        autocmd WinEnter,BufWinEnter,FileType,VimEnter * lua require'matchparen'.create_matchpairs()
        autocmd CursorMoved,CursorMovedI * lua require'matchparen'.update_highlight()
        autocmd TextChanged,TextChangedI,WinEnter * lua require'matchparen'.update_highlight()
        autocmd WinLeave,BufLeave * lua require'matchparen'.remove_highlight()
        autocmd OptionSet matchpairs lua require'matchperen'.create_matchpairs()
      augroup END
    ]]
  end
end

function M.remove_autocmds()
  if f.exists('#' .. M.config.augroup_name) ~= 0 then
    vim.cmd('autocmd! ' .. M.config.augroup_name)
    vim.cmd('augroup! ' .. M.config.augroup_name)
  end
end

local function splitted_matchpairs()
  local t = {}

  for _, pair in ipairs(vim.opt.matchpairs:get()) do
    -- matchpairs option devide each pair with `:`, so we split by it
    local opening, closing = pair:match('(.+):(.+)')
    t[opening] = closing
  end

  return t
end

-- generates value for `matchpairs` table
local function matchpairs_value(opening, closing, backward)
  -- `[` and `]` should be escaped to process by searchpairpos()
  local escape_symbols = ']['

  return {
    opening = f.escape(opening, escape_symbols),
    closing = f.escape(closing, escape_symbols),
    backward = backward
  }
end

function M.create_matchpairs()
  if cached_matchpairs_opt == vim.o.matchpairs then return end

  cached_matchpairs_opt = vim.o.matchpairs

  M.matchpairs = {}
  for o, c in pairs(splitted_matchpairs()) do
    M.matchpairs[o] = matchpairs_value(o, c, false)
    M.matchpairs[c] = matchpairs_value(o, c, true)
  end
end

local function is_insert_mode()
  local mode = a.nvim_get_mode().mode
  return mode == 'i' or mode == 'R'
end

local function delete_extmark(id)
  a.nvim_buf_del_extmark(0, M.namespace, id)
end

function M.remove_highlight()
  delete_extmark(M.extmarks.current)
  delete_extmark(M.extmarks.match)
end

local function create_extmark(line, col)
  return a.nvim_buf_set_extmark(0, M.namespace,
                                line, col,
                                { end_col = col + 1, hl_group = M.config.hl_group })
end

function M.update_highlight()
  M.remove_highlight()

  local cur_lnum, cur_col = unpack(a.nvim_win_get_cursor(0))

  -- Should it also check for pumvisible() as original matchparen does?
  -- Because i do not notice any difference and popupmenu doesn't close
  -- Do not process current line if it is in closed fold
  if f.foldclosed(cur_lnum) ~= -1 then return end

  local text = a.nvim_get_current_line()
  local inc_col = cur_col + 1
  local char = text:sub(inc_col, inc_col)
  local in_insert = is_insert_mode()
  local before = 0

  if cur_col > 0 and in_insert then
    local before_char = text:sub(cur_col, cur_col)
    if M.matchpairs[before_char] then
      char = before_char
      before = 1
    end
  end

  if not M.matchpairs[char] then return end

  -- TODO: currently just skip comments and strings
  -- should make it works inside this blocks
  -- if skip() then return end

  local starts = M.matchpairs[char].opening
  local ends = M.matchpairs[char].closing
  local backward = M.matchpairs[char].backward
  local flags = backward and 'bnW' or 'nW'
  local win_height = a.nvim_win_get_height(0)
  local stopline = backward and max(1, cur_lnum - win_height) or (cur_lnum + win_height)

  local saved_cursor
  if before > 0 then
    saved_cursor = a.nvim_win_get_cursor(0)
    a.nvim_win_set_cursor(0, { cur_lnum, cur_col - before })
  end

  local timeout = in_insert and M.config.timeout_insert or M.config.timeout

  local ok, match_pos = pcall(f.searchpairpos, starts, '', ends, flags, 'matchparen#skip()', stopline, timeout)
  if not ok then return end

  local match_lnum, match_col = unpack(match_pos)

  if before > 0 then
    a.nvim_win_set_cursor(0, saved_cursor)
  end

  if match_lnum > 0 then
    M.extmarks.current = create_extmark(cur_lnum - 1, cur_col - before)
    M.extmarks.match = create_extmark(match_lnum - 1, match_col - 1)
  end
end

function M.enable()
  M.enable_autocmds()
  M.create_matchpairs()
  M.update_highlight()
end

function M.disable()
  M.remove_autocmds()
  M.remove_highlight()
end

return M
