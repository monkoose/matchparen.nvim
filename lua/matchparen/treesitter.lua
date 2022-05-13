local opts = require('matchparen.options').opts
local utils = require('matchparen.utils')
local nvim = require('matchparen.missinvim')

local ts = {}

local cache = {
  trees = {},
  skip_nodes = {},
}

local treesitter_skip = {
  'string',
  'comment',
}

---Determines whether (line, col) position is in node range
---@param node userdata node defining the range
---@param line integer 0-based line number
---@param col integer 0-based column number
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

---Caches `line` skip nodes
---@param line integer 0-based line number
local function cache_nodes(line)
  cache.skip_nodes[line] = {}
  for _, tree in ipairs(cache.trees) do
    local iter = tree.query:iter_captures(tree.root, opts.cache.hl.bufnr,
      line, line + 1)
    for id, node in iter do
      if vim.tbl_contains(treesitter_skip, tree.query.captures[id]) then
        table.insert(cache.skip_nodes[line], node)
      end
    end
  end
end

---Returns treesitter node at `line` and `col` position if it is in `captures` list
---@param line integer 0-based line number
---@param col integer 0-based column number
---@return userdata|nil node
local function get_skip_node(line, col)
  if not cache.skip_nodes[line] then
    -- pcall for https://github.com/monkoose/matchparen.nvim/issues/14
    pcall(cache_nodes, line)
  end

  for _, node in ipairs(cache.skip_nodes[line]) do
    if is_in_node_range(node, line, col) then
      return node
    end
  end
end

---Returns all treesitter trees which have root nodes and highlight queries
---@return table
local function get_trees()
  local trees = {}
  opts.cache.hl.tree:for_each_tree(function(tstree, tree)
    if not tstree then return end

    local root = tstree:root()
    local query = opts.cache.hl:get_query(tree:lang()):query()

    -- Some injected languages may not have highlight queries.
    if query then
      table.insert(trees, { root = root, query = query })
    end
  end, true)

  return trees
end

---Returns true when `node` type is string
---@param node userdata
---@return boolean
local function is_node_string(node)
  return utils.str_contains(node:type(), 'string')
end

---Returns true when `node` type is comment
---@param node userdata
---@return boolean
local function is_node_comment(node)
  return utils.str_contains(node:type(), 'comment')
end

---Returns true when the cursor is inside any of `treesitter_skip` captures
---@param line integer 0-based line
---@param col integer 0-based column
---@return boolean
local function is_ts_skip_region(line, col)
  if utils.is_inside_fold(line) then
    return false
  end
  return get_skip_node(line, col) ~= nil
end

---Determines whether a search should stop if outside of the `node`
---@param node userdata treesitter node
---@param backward boolean direction of the search
---@return integer
local function skip_by_node(node, backward)
  local get_sibling = backward and 'prev_sibling' or 'next_sibling'

  return function(l, c)
    if not c then
      return 0
    end

    while node do
      -- limit the search to the current node only
      if is_in_node_range(node, l, c) then
        return 0
      end
      -- increase the search limit for connected comments
      if not is_node_comment(node) then
        return -1
      end
      node = node[get_sibling](node)
      if not (node and is_node_comment(node)) then
        return -1
      end
    end
  end
end

---Returns treesitter highlighter for current buffer or nil
---@return table
function ts.get_highlighter()
  local bufnr = nvim.get_current_buf()
  return vim.treesitter.highlighter.active[bufnr]
end

---Returns `skip` function for `match_pos`
---based on treesitter node under the `line` and `col`
---@param line integer 0-based line number
---@param col integer 0-based column number
---@param backward boolean direction of the search
---@return function
function ts.skip_by_region(line, col, backward)
  cache.trees = get_trees()
  cache.skip_nodes = {}
  local skip_node = get_skip_node(line, col)
  -- FiXME: requires only to fix annoying bug for treesitter strings
  -- that still shows that char after the string belongs to this string
  if skip_node and is_node_string(skip_node) and utils.is_in_insert_mode() then
    if not is_in_node_range(skip_node, line, col + 1) then
      skip_node = false
    end
  end

  if skip_node then  -- inside string or comment
    return skip_by_node(skip_node, backward)
  else
    return function(l, c)
      return is_ts_skip_region(l, c) and 1 or 0
    end
  end
end

return ts

-- vim:sw=2:et
