local conf = require('matchparen').config
local utils = require('matchparen.utils')

local M = {}

-- copied from nvim-tresitter plugin
-- https://github.com/nvim-treesitter/nvim-treesitter/blob/master/lua/nvim-treesitter/ts_utils.lua
--- Determines whether (line, col) position is in node range
-- @param node Node defining the range
-- @param line A line (0-based)
-- @param col A column (0-based)
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

-- Returns treesitter node at `line` and `col` position if it is in `captures` list
-- @return treesitter node or nil
local function get_skip_node(line, col)
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
-- @return boolean
function M.in_ts_skip_region()
    return utils.in_skip_region(get_skip_node)
end

-- Returns 0-based line and column of matched bracket if any or nil
-- @param matchpair
-- @param line 1-based line number
-- @param col 0-based column number
-- @param insert boolean true if in insert mode
-- @return (number, number) or nil
function M.get_match_pos(matchpair, line, col, insert)
    local node = get_skip_node(line - 1, col)
    -- TODO: this if condition only to fix annotying bug when treesitter isn't updated
    if node and not is_node_comment(node) then
        if not is_in_node_range(node, line - 1, col + 1) then
            node = false
        end
    end
    local skip_ref = node and '' or 'matchparen#ts_skip()'
    local match_line, match_col = utils.search_pair_pos(matchpair, skip_ref, line, insert)

    -- if in string or comment
    if node and match_line then
        local go_to_sibling = matchpair.backward and 'prev_sibling' or 'next_sibling'
        while node do
            -- limit search to current node only
            if is_in_node_range(node, match_line, match_col) then
                break
            end
            -- but increase search limit for connected line comments if needed
            if is_node_comment(node) then
                node = node[go_to_sibling](node)
                if not (node and is_node_comment(node)) then
                    return
                end
            else
                return
            end
        end
    end

    return match_line, match_col
end

return M
