local conf = require('matchparen').config
local utils = require('matchparen.utils')

local M = { hl = nil, root = nil, trees = {}, skip_nodes = {} }

-- copied from nvim-tresitter plugin
-- https://github.com/nvim-treesitter/nvim-treesitter/blob/master/lua/nvim-treesitter/ts_utils.lua
--- Determines whether (line, col) position is in node range
-- @param node Node defining the range
-- @param line number (0-based) line number
-- @param col number (0-based) column number
-- @return bool
function M.is_in_node_range(node, line, col)
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

function M.node_at(line, col)
    return M.root:descendant_for_range(line, col, line, col + 1)
end

-- Returns treesitter node at `line` and `col` position if it is in `captures` list
-- @param line number (0-based) line number
-- @param col number (0-based) column number
-- @param parent treesitter node
-- @return treesitter node or nil
function M.get_skip_node(line, col, parent)
    if parent and parent ~= M.node_at(line, col):parent() then
        return true
    end

    local function filter_captures(tree, iter)
        for id, node in iter do
            if vim.tbl_contains(conf.ts_skip_groups, tree.query.captures[id]) then
                table.insert(M.skip_nodes[line], node)
            end
        end
    end

    if not M.skip_nodes[line] then
        M.skip_nodes[line] = {}
        for _, tree in ipairs(M.trees) do
            local iter = tree.query:iter_captures(tree.root, M.hl.bufnr, line, line + 1)
            filter_captures(tree, iter)
        end
    end

    for _, node in ipairs(M.skip_nodes[line]) do
        if M.is_in_node_range(node, line, col) then
            return node
        end
    end
end

-- Returns all treesitter trees which have root nodes and highlight queries
-- @return table
function M.get_trees()
    local trees = {}
    M.hl.tree:for_each_tree(function(tstree, tree)
        if not tstree then return end

        local root = tstree:root()
        local query = M.hl:get_query(tree:lang()):query()

        -- Some injected languages may not have highlight queries.
        if not query then return end

        table.insert(trees, { root = root, query = query })
    end, true)

    return trees
end

-- Determines wheter `node` is type of comment
-- @return boolean
function M.is_node_comment(node)
    return utils.str_contains(node:type(), 'comment')
end

-- Returns treesitter highlighter for current buffer or nil
function M.get_highlighter()
    local bufnr = vim.api.nvim_get_current_buf()
    return vim.treesitter.highlighter.active[bufnr]
end

-- Returns treesitter tree root
function M.get_tree_root()
    return vim.treesitter.get_parser():parse()[1]:root()
end

-- Determines whether the cursor is inside conf.ts_skip_groups option
-- @param line number (0-based) line
-- @param col number (0-based) column
-- @return boolean
function M.in_ts_skip_region(line, col, parent)
    return utils.in_skip_region(line, col, function(l, c)
        return M.get_skip_node(l, c, parent)
    end)
end

-- Determines whether a search should stop if outside of the `node`
-- @param node treesitter node
-- @param backward boolean direction of the search
-- @return boolean
function M.limit_by_node(node, backward)
    return function(l, c)
        if not c then return end

        local get_sibling = backward and 'prev_sibling' or 'next_sibling'
        while node do
            -- limit the search to the current node only
            if M.is_in_node_range(node, l, c) then return end
            if not M.is_node_comment(node) then
                return true
            end
            -- increase the search limit for connected comments
            node = node[get_sibling](node)
            if not (node and M.is_node_comment(node)) then
                return true
            end
        end
    end
end

return M
