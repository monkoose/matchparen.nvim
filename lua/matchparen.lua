local defaults = require('matchparen.defaults')
local ts_utils = require('nvim-treesitter.ts_utils')
local ts_hl = vim.treesitter.highlighter

local a = vim.api
local f = vim.fn
local max = math.max
local t_contains = vim.tbl_contains

-- Global variables
local cur_extmark_id = 0
local match_extmark_id = 0
local matchpairs = {}
local ns
local cached_matchpairs_opt

local M = {}

local function enable_autocmds()
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

-- Setup
function M.setup(options)
  M.config = vim.tbl_deep_extend('force', defaults, options or {})

  ns = a.nvim_create_namespace(M.config.augroup_name)

  if M.config.on_startup then
    enable_autocmds()
  end
end

local function remove_autocmds()
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

  matchpairs = {}
  for o, c in pairs(splitted_matchpairs()) do
    matchpairs[o] = matchpairs_value(o, c, false)
    matchpairs[c] = matchpairs_value(o, c, true)
  end
end

-- most part taken from treesitter-playground
local function get_ts_captures()
  local buf = a.nvim_get_current_buf()
  local row, col = unpack(a.nvim_win_get_cursor(0))
  row = row - 1

  local self = ts_hl.active[buf]

  if not self then
    return {}
  end

  local matches = {}

  self.tree:for_each_tree(function(tstree, tree)
    if not tstree then return end

    local root = tstree:root()
    local root_start_row, _, root_end_row, _ = root:range()
    -- Only worry about trees within the line range
    if root_start_row > row or root_end_row < row then return end

    local query = self:get_query(tree:lang())
    -- Some injected languages may not have highlight queries.
    if not query:query() then return end

    local iter = query:query():iter_captures(root, self.bufnr, row, row + 1)

    for id, node in iter do

      if ts_utils.is_in_node_range(node, row, col) then
        table.insert(matches, query._query.captures[id])
      end
    end
  end, true)

  return matches
end

local function in_ts_skip_block()
  for _, capture in ipairs(get_ts_captures()) do
    if t_contains(M.config.ts_skip_captures, capture) then
      return true
    end
  end

  return false
end

local function in_syn_skip_block()
  local line, col = unpack(a.nvim_win_get_cursor(0))

  if f.foldclosed(line) ~= -1 then
    return false
  end

  for _, id in ipairs(f.synstack(line, col + 1)) do
    local synname = string.lower(f.synIDattr(id, 'name'))

    for _, pattern in ipairs(M.config.syn_skip_names) do
      if string.find(synname, pattern) then
        return true
      end
    end
  end

  return false
end

function _G.skip_region()
  if vim.opt.syntax:get() ~= '' and in_syn_skip_block() then
    return true
  end

  return in_ts_skip_block()
end

local function is_insert_mode()
  local mode = a.nvim_get_mode().mode
  return mode == 'i' or mode == 'R'
end

function M.remove_highlight()
  a.nvim_buf_del_extmark(0, ns, cur_extmark_id)
  a.nvim_buf_del_extmark(0, ns, match_extmark_id)
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
    if matchpairs[before_char] then
      char = before_char
      before = 1
    end
  end

  if not matchpairs[char] then return end

  -- TODO: currently just skip comments and strings
  -- should make it works inside this blocks
  if skip_region() then return end

  local starts = matchpairs[char].opening
  local ends = matchpairs[char].closing
  local backward = matchpairs[char].backward
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
    local col = cur_col - before

    cur_extmark_id = a.nvim_buf_set_extmark(
      0, ns, cur_lnum - 1, col,
      { end_col = col + 1, hl_group = M.config.hl_group }
    )

    match_extmark_id = a.nvim_buf_set_extmark(
      0, ns, match_lnum - 1, match_col - 1,
      { end_col = match_col, hl_group = M.config.hl_group }
    )
  end
end

function M.enable()
  enable_autocmds()
  M.create_matchpairs()
  M.update_highlight()
end

function M.disable()
  remove_autocmds()
  M.remove_highlight()
end

return M
