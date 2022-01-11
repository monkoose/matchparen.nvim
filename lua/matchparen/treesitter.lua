local conf = require('matchparen').config
local utils = require('matchparen.utils')

local M = {}
local root

-- copied from nvim-tresitter plugin
-- https://github.com/nvim-treesitter/nvim-treesitter/blob/master/lua/nvim-treesitter/ts_utils.lua
--- Determines whether (line, col) position is in node range
-- @param node Node defining the range
-- @param line number (0-based) line number
-- @param col number (0-based) column number
-- @return bool
local function is_in_node_range(node, line, col)
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

local function node_at(line, col)
    return root:descendant_for_range(line, col, line, col + 1)
end

-- Returns treesitter node at `line` and `col` position if it is in `captures` list
-- @param line number (0-based) line number
-- @param col number (0-based) column number
-- @return treesitter node or nil
local function get_skip_node(line, col, parent)
    if parent and parent ~= node_at(line, col):parent() then
        return true
    end

    local skip_node
    local hl = conf.ts_highlighter
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
            if is_in_node_range(node, line, col) then
                if vim.tbl_contains(conf.ts_skip_groups, query._query.captures[id]) then
                    skip_node = node
                    break
                end
            end
        end
    end, true)

    return skip_node
end

-- Determines whether `str` constains `pattern`
-- @param str string
-- @param pattern string
-- @return boolean
local function str_contains(str, pattern)
    return str:find(pattern, 1, true) ~= nil
end

-- Determines wheter `node` is type of comment
-- @return boolean
local function is_node_comment(node)
    return str_contains(node:type(), 'comment')
end

-- Returns treesitter highlighter for current buffer or nil
function M.get_highlighter()
    local bufnr = vim.api.nvim_get_current_buf()
    return vim.treesitter.highlighter.active[bufnr]
end

-- Determines whether the cursor is inside conf.ts_skip_groups option
-- @param line number (0-based) line
-- @param col number (0-based) column
-- @return boolean
local function in_ts_skip_region(line, col, parent)
    return utils.in_skip_region(line, col, function(l, c)
        return get_skip_node(l, c, parent)
    end)
end

-- Determines whether a search should stop if outside of the `node`
-- @param node treesitter node
-- @param backward boolean direction of the search
-- @return boolean
local function limit_by_node(node, backward)
    return function(l, c)
        if not c then return end

        local get_sibling = backward and 'prev_sibling' or 'next_sibling'
        while node do
            -- limit the search to the current node only
            if is_in_node_range(node, l, c) then
                return false
            end

            -- but increase the search limit for connected line comments
            if is_node_comment(node) then
                node = node[get_sibling](node)
                if not (node and is_node_comment(node)) then
                    return true
                end
            else
                return true
            end
        end
    end
end

-- Returns 0-based line and column of matched bracket if any or nil
-- @param matchpair
-- @param line 1-based line number
-- @param col 0-based column number
-- @return (number, number) or nil
function M.get_match_pos(matchpair, line, col)
    local node = get_skip_node(line, col)
    -- TODO: this if condition only to fix annotying bug when treesitter isn't updated
    if node and not is_node_comment(node) then
        if not is_in_node_range(node, line, col + 1) then
            node = false
        end
    end

    local skip
    local stop
    if node then  -- inside string or comment
        stop = limit_by_node(node, matchpair.backward)
    else
        root = vim.treesitter.get_parser():parse()[1]:root()
        local parent = node_at(line, col):parent()
        skip = function(l, c)
            return in_ts_skip_region(l, c, parent)
        end
        stop = utils.limit_by_line(line, matchpair.backward)
    end

    return utils.search_pair(matchpair.left,
                             matchpair.right,
                             line,
                             col,
                             matchpair.backward,
                             skip,
                             stop)
end

return M
