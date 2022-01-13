local conf = require('matchparen').config
local utils = require('matchparen.utils')

local M = { highlighter = nil, root = nil }

-- copied from nvim-tresitter plugin
-- https://github.com/nvim-treesitter/nvim-treesitter/blob/master/lua/nvim-treesitter/ts_utils.lua
--- Determines whether (line, col) position is in node range
-- @param node Node defining the range
-- @param line number (0-based) line number
-- @param col number (0-based) column number
-- @return bool
function M.is_in_node_range(node, line, col)
    local start_line, start_col, end_line, end_col = node:range()
    if line >= start_line and line <= end_line then
        if line == start_line and line == end_line then
            return col >= start_col and col < end_col
        elseif line == start_line then
            return col >= start_col
        elseif line == end_line then
            return col < end_col
        else
            return true
        end
    else
        return false
    end
end

function M.node_at(line, col)
    return M.root:descendant_for_range(line, col, line, col + 1)
end

-- Returns treesitter node at `line` and `col` position if it is in `captures` list
-- @param line number (0-based) line number
-- @param col number (0-based) column number
-- @return treesitter node or nil
function M.get_skip_node(line, col, parent)
    if parent and parent ~= M.node_at(line, col):parent() then
        return true
    end

    local skip_node
    local hl = M.highlighter
    hl.tree:for_each_tree(function(tstree, tree)
        if skip_node then return end
        if not tstree then return end

        local root = tstree:root()
        local root_start_line, _, root_end_line, _ = root:range()
        -- Only worry about trees within the line range
        if root_start_line > line or root_end_line < line then return end

        local query = hl:get_query(tree:lang())
        -- Some injected languages may not have highlight queries.
        if not query:query() then return end

        local iter = query:query():iter_captures(root, hl.bufnr, line, line + 1)
        for id, node in iter do
            if M.is_in_node_range(node, line, col) then
                if vim.tbl_contains(conf.ts_skip_groups, query._query.captures[id]) then
                    skip_node = node
                    break
                end
            end
        end
    end, true)

    return skip_node
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
            if M.is_in_node_range(node, l, c) then
                return false
            end

            -- but increase the search limit for connected line comments
            if M.is_node_comment(node) then
                node = node[get_sibling](node)
                if not (node and M.is_node_comment(node)) then
                    return true
                end
            else
                return true
            end
        end
    end
end

return M
