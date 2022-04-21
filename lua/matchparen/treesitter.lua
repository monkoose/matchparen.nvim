local opts = require('matchparen.options').opts
local utils = require('matchparen.utils')
local nvim = require('missinvim')

local M = { hl = nil, root = nil, trees = {}, skip_nodes = {} }

---Determines whether (line, col) position is in node range
---@param node userdata node defining the range
---@param line number 0-based line number
---@param col number 0-based column number
---@return boolean
---
---copied from nvim-tresitter plugin
---https://github.com/nvim-treesitter/nvim-treesitter/blob/master/lua/nvim-treesitter/ts_utils.lua
local function is_in_node_range(node, line, col)
  local start_line, start_col, end_line, end_col = node:range()

  if not (line >= start_line and line <= end_line) then
    return false
  end

  if line == start_line and line == end_line then
    return col >= start_col and col < end_col
  elseif line == start_line then
    return col >= start_col
  elseif line == end_line then
    return col < end_col
  else
    return true
  end
end

---Returns treesitter node at (line, col) position
---@param line number 0-based line number
---@param col number 0-based column number
---@return userdata
local function node_at(line, col)
  return M.root:descendant_for_range(line, col, line, col + 1)
end

---Returns treesitter node at `line` and `col` position if it is in `captures` list
---@param line number 0-based line number
---@param col number 0-based column number
---@param parent userdata treesitter node
---@return userdata|nil node
local function get_skip_node(line, col, parent)
  if parent and parent ~= node_at(line, col):parent() then
    return true
  end

  local function filter_captures(tree, iter)
    for id, node in iter do
      if vim.tbl_contains(opts.ts_skip_groups, tree.query.captures[id]) then
        table.insert(M.skip_nodes[line], node)
      end
    end
  end

  if not M.skip_nodes[line] then
    M.skip_nodes[line] = {}
    for _, tree in ipairs(M.trees) do
      local iter = tree.query:iter_captures(tree.root, M.hl.bufnr,
                                            line, line + 1)
      filter_captures(tree, iter)
    end
  end

  for _, node in ipairs(M.skip_nodes[line]) do
    if is_in_node_range(node, line, col) then
      return node
    end
  end
end

---Returns all treesitter trees which have root nodes and highlight queries
---@return table
local function get_trees()
  local trees = {}
  M.hl.tree:for_each_tree(function(tstree, tree)
    if not tstree then return end

    local root = tstree:root()
    local query = M.hl:get_query(tree:lang()):query()

    -- Some injected languages may not have highlight queries.
    if query then
      table.insert(trees, { root = root, query = query })
    end
  end, true)

return trees
end

---Determines wheter `node` is type of comment
---@return boolean
local function is_node_comment(node)
  return utils.str_contains(node:type(), 'comment')
end

---Returns treesitter tree root
local function get_tree_root()
  return vim.treesitter.get_parser():parse()[1]:root()
end

---Determines whether the cursor is inside conf.ts_skip_groups option
---@param line number 0-based line
---@param col number 0-based column
---@param parent userdata treesitter node
---@return boolean
local function is_ts_skip_region(line, col, parent)
  if utils.inside_closed_fold(line) then
    return false
  end
  return get_skip_node(line, col, parent) ~= nil
end

---Determines whether a search should stop if outside of the `node`
---@param node userdata treesitter node
---@param backward boolean direction of the search
---@return boolean
local function limit_by_node(node, backward)
  return function(l, c)
    if not c then return end

    local get_sibling = backward and 'prev_sibling' or 'next_sibling'
    while node do
      -- limit the search to the current node only
      if is_in_node_range(node, l, c) then return end
      if not is_node_comment(node) then
        return true
      end
      -- increase the search limit for connected comments
      node = node[get_sibling](node)
      if not (node and is_node_comment(node)) then
        return true
      end
    end
  end
end

---Returns treesitter highlighter for current buffer or nil
function M.get_highlighter()
  local bufnr = nvim.get_current_buf()
  return vim.treesitter.highlighter.active[bufnr]
end

---Returns `skip` and `stop` functions for `match_pos`
---based on treesitter node under the `line` and `col`
---@param line number 0-based line number
---@param col number 0-based column number
---@param backward boolean direction of the search
---@return function, function
function M.skip_and_stop(line, col, backward)
  local skip, stop
  M.trees = get_trees()
  M.skip_nodes = {}
  local skip_node = get_skip_node(line, col)
  -- FiXME: this if condition only to fix annotying bug for treesitter strings
  if skip_node and not is_node_comment(skip_node) then
    if not is_in_node_range(skip_node, line, col + 1) then
      skip_node = false
    end
  end

  if skip_node then  -- inside string or comment
    stop = limit_by_node(skip_node, backward)
  else
    M.root = get_tree_root()
    local parent = node_at(line, col):parent()
    skip = function(l, c)
      return is_ts_skip_region(l, c, parent)
    end
    stop = utils.limit_by_line(line, backward)
  end
  return skip, stop
end

return M

-- vim:sw=2:et
