local _2afile_2a = "fnl/matchparen/treesitter.fnl"
local _2amodule_name_2a = "matchparen.treesitter"
local _2amodule_2a
do
  package.loaded[_2amodule_name_2a] = {}
  _2amodule_2a = package.loaded[_2amodule_name_2a]
end
local _2amodule_locals_2a
do
  _2amodule_2a["aniseed/locals"] = {}
  _2amodule_locals_2a = (_2amodule_2a)["aniseed/locals"]
end
local autoload = (require("matchparen.aniseed.autoload")).autoload
local a, nvim, utils = autoload("matchparen.aniseed.core"), autoload("matchparen.aniseed.nvim"), autoload("matchparen.utils")
do end (_2amodule_locals_2a)["a"] = a
_2amodule_locals_2a["nvim"] = nvim
_2amodule_locals_2a["utils"] = utils
local opts = (require("matchparen.options")).options
_2amodule_locals_2a["opts"] = opts
local cache = {trees = {}, ["skip-nodes"] = {}}
_2amodule_locals_2a["cache"] = cache
local ts_skip = {"string", "comment"}
_2amodule_locals_2a["ts-skip"] = ts_skip
local function in_node_range_3f(node, line, col)
  local startline, startcol, endline, endcol = node:range()
  if (function(_1_,_2_,_3_) return (_1_ <= _2_) and (_2_ <= _3_) end)(startline,line,endline) then
    if (function(_4_,_5_,_6_) return (_4_ == _5_) and (_5_ == _6_) end)(line,startline,endline) then
      return ((startcol <= col) and (col < endcol))
    elseif (line == startline) then
      return (startcol <= col)
    elseif (line == endline) then
      return (col < endcol)
    else
      return true
    end
  else
    return false
  end
end
_2amodule_locals_2a["in-node-range?"] = in_node_range_3f
local function cache_nodes(line, tree, iter)
  for id, node in {iter} do
    if vim.tbl_contains(opts.ts_skip_groups, tree.query.captures[id]) then
      table.insert((cache["skip-nodes"])[line], node)
    else
    end
  end
  return nil
end
_2amodule_locals_2a["cache-nodes"] = cache_nodes
local function node_at_pos(line, col)
  return (cache.root):descendant_for_range(line, col, line, a.inc(col))
end
_2amodule_locals_2a["node-at-pos"] = node_at_pos
local function get_skip_node(line, col, parent)
  if (parent and (parent ~= node_at_pos(line, col):parent())) then
    return true
  else
    if not (cache["skip-nodes"])[line] then
      cache["skip-nodes"][line] = {}
      for _, tree in ipairs(cache.trees) do
        local iter = (tree.query):iter_captures(tree.root, cache.highlighter.bufnr, line, a.inc(line))
        cache_nodes(line, tree, iter)
      end
    else
    end
    local skip_node = nil
    for _, node in ipairs((cache["skip-nodes"])[line]) do
      if skip_node then break end
      if in_node_range_3f(node, line, col) then
        skip_node = node
      else
      end
    end
    return skip_node
  end
end
_2amodule_locals_2a["get-skip-node"] = get_skip_node
local function get_trees()
  local trees = {}
  local function _13_(tstree, tree)
    if tstree then
      local query = (cache.highlighter):get_query(tree:lang()):query()
      if query then
        return table.insert(trees, {root = tstree:root(), query = query})
      else
        return nil
      end
    else
      return nil
    end
  end
  do end (cache.highlighter.tree):for_each_tree(_13_, true)
  return trees
end
_2amodule_locals_2a["get-trees"] = get_trees
local function string_node_3f(node)
  return utils["string-contains?"](node:type(), "string")
end
_2amodule_locals_2a["string-node?"] = string_node_3f
local function comment_node_3f(node)
  return utils["string-contains?"](node:type(), "comment")
end
_2amodule_locals_2a["comment-node?"] = comment_node_3f
local function skip_region_3f(line, col, parent)
  if utils["inside-closed-fold"](line) then
    return false
  else
    return (nil ~= get_skip_node(line, col, parent))
  end
end
_2amodule_locals_2a["skip-region?"] = skip_region_3f
local function get_sibling_position(backward_3f)
  if backward_3f then
    return "prev_sibling"
  else
    return "next_sibling"
  end
end
_2amodule_locals_2a["get-sibling-position"] = get_sibling_position
local function get_sibling_node(node, sibling_pos)
  return node[sibling_pos](node)
end
_2amodule_locals_2a["get-sibling-node"] = get_sibling_node
local function stop_search_3f(node, line, col, sibling_pos)
  if in_node_range_3f(node, line, col) then
    return false
  else
    if not comment_node_3f(node) then
      return true
    else
      local sibling = get_sibling_node(node, sibling_pos)
      if not (sibling and comment_node_3f(sibling)) then
        return true
      else
        return stop_search_3f(sibling, line, col, sibling_pos)
      end
    end
  end
end
_2amodule_locals_2a["stop-search?"] = stop_search_3f
local function limit_by_node(node, backward_3f)
  local function _21_(line, col)
    if not col then
      return false
    else
      local sibling_pos = get_sibling_position(backward_3f)
      return stop_search_3f(node, line, col, sibling_pos)
    end
  end
  return _21_
end
_2amodule_locals_2a["limit-by-node"] = limit_by_node
local function get_highlighter()
  local bufnr = nvim.get_current_buf()
  return vim.treesitter.highlighter.active[bufnr]
end
_2amodule_2a["get-highlighter"] = get_highlighter
return _2amodule_2a