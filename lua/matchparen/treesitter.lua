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
local autoload = (require("aniseed.autoload")).autoload
local a, nvim, opts, utils = autoload("matchparen.aniseed.core"), autoload("matchparen.nvim"), autoload("matchparen.defaults"), autoload("matchparen.utils")
do end (_2amodule_locals_2a)["a"] = a
_2amodule_locals_2a["nvim"] = nvim
_2amodule_locals_2a["opts"] = opts
_2amodule_locals_2a["utils"] = utils
local cache = {trees = {}, ["skip-nodes"] = {}}
_2amodule_locals_2a["cache"] = cache
local ts_skip = {"string", "comment"}
_2amodule_locals_2a["ts-skip"] = ts_skip
local highlighter = nil
_2amodule_2a["highlighter"] = highlighter
local function in_node_range_3f(node, pos)
  local startline, startcol, endline, endcol = node:range()
  if (function(_1_,_2_,_3_) return (_1_ <= _2_) and (_2_ <= _3_) end)(startline,pos.line,endline) then
    if (function(_4_,_5_,_6_) return (_4_ == _5_) and (_5_ == _6_) end)(pos.line,startline,endline) then
      return ((startcol <= pos.col) and (pos.col < endcol))
    elseif (pos.line == startline) then
      return (startcol <= pos.col)
    elseif (pos.line == endline) then
      return (pos.col < endcol)
    else
      return true
    end
  else
    return false
  end
end
_2amodule_locals_2a["in-node-range?"] = in_node_range_3f
local function line_nodes(tree, line)
  return (tree.query):iter_captures(tree.root, highlighter.bufnr, line, a.inc(line))
end
_2amodule_locals_2a["line-nodes"] = line_nodes
local function cache_nodes(line)
  cache["skip-nodes"][line] = {}
  for _, tree in ipairs(cache.trees) do
    local tbl_15_auto = (cache["skip-nodes"])[line]
    local i_16_auto = #tbl_15_auto
    for id, node in line_nodes(tree, line) do
      local val_17_auto
      do
        local capture = tree.query.captures[id]
        if vim.tbl_contains(ts_skip, capture) then
          val_17_auto = node
        else
          val_17_auto = nil
        end
      end
      if (nil ~= val_17_auto) then
        i_16_auto = (i_16_auto + 1)
        do end (tbl_15_auto)[i_16_auto] = val_17_auto
      else
      end
    end
  end
  return nil
end
_2amodule_locals_2a["cache-nodes"] = cache_nodes
local function get_skip_node(pos)
  if not (cache["skip-nodes"])[pos.line] then
    pcall(cache_nodes, pos.line)
  else
  end
  local function _12_(_241)
    return in_node_range_3f(_241, pos)
  end
  return a.some(_12_, (cache["skip-nodes"])[pos.line])
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
  do end (highlighter.tree):for_each_tree(_13_, true)
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
local function in_skip_region_3f(pos)
  if utils["inside-closed-fold"](pos.line) then
    return false
  else
    return (nil ~= get_skip_node(pos))
  end
end
_2amodule_locals_2a["in-skip-region?"] = in_skip_region_3f
local function get_sibling_position(backward_3f)
  if backward_3f then
    return "prev_sibling"
  else
    return "next_sibling"
  end
end
_2amodule_locals_2a["get-sibling-position"] = get_sibling_position
local function get_sibling_node(node, sibling_pos)
  local get_sibling = node[sibling_pos]
  return get_sibling(node)
end
_2amodule_locals_2a["get-sibling-node"] = get_sibling_node
local function skip_by_node(node, backward_3f)
  local get_sibling
  if backward_3f then
    get_sibling = "prev_sibling"
  else
    get_sibling = "next_sibling"
  end
  local function _19_(l, c)
    if not c then
      return 0
    else
      while node do
      end
      return nil
    end
  end
  return _19_
end
_2amodule_locals_2a["skip-by-node"] = skip_by_node
local function fix_string_range_3f(node, pos)
  if (node and string_node_3f(node) and utils["insert-mode?"]() and not in_node_range_3f(node, {line = pos.line, col = a.inc(pos.col)})) then
    return false
  else
    return true
  end
end
_2amodule_locals_2a["fix-string-range?"] = fix_string_range_3f
local function get_highlighter()
  return vim.treesitter.highlighter.active[nvim.get_current_buf()]
end
_2amodule_2a["get-highlighter"] = get_highlighter
local function skip_by_region(pos, backward_3f)
  cache.trees = get_trees()
  cache["skip-nodes"] = {}
  local skip_node = get_skip_node(pos)
  local fix = fix_string_range_3f(skip_node, pos)
  if (skip_node and fix) then
    return skip_by_node(skip_node, backward_3f)
  else
    local function _22_(_241)
      if in_skip_region_3f(_241) then
        return 1
      else
        return 0
      end
    end
    return _22_
  end
end
_2amodule_2a["skip-by-region"] = skip_by_region
return _2amodule_2a