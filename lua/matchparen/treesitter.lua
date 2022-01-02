local conf = require('matchparen').config

local COMMENT = 'comment'

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

-- Returns treesitter parser for current buffer or nil
function M.get_parser()
    local ok, parser = pcall(vim.treesitter.get_parser)

    if not ok then return end
    return parser
end

-- Returs node at line and column position
function M.node_at(root, line, col)
    return root:descendant_for_range(line, col, line, col + 1)
end

-- True if `str` constains `pattern`
-- @param str (string)
-- @param pattern (string)
-- @return (bool)
local function str_contains(str, pattern)
    return str:find(pattern, 1, true) ~= nil
end

-- Returns `node` or the first parent of it that has one of the `types`
-- @param node (treesitter node)
-- @param types (list of strings) of all looking types
-- @return (treesitter node) or nil
function M.get_node_of_type(node, types)
    while node do
        for _, type in ipairs(types) do
            if str_contains(node:type(), type) then
                return node
            end
        end
        node = node:parent()
    end
end

-- Returns 0-based line and column of matched bracket if any or nil
-- @param matchpair
-- @param node (treesitter node)
-- @param line 0-based current line number
-- @param insert true if in insert mode
-- @return number, number or nil
function M.get_skip_match_pos(matchpair, node, line, insert)
    local match_line
    local match_col
    local flags = matchpair.backward and 'bnW' or 'nW'
    local timeout = insert and conf.timeout_insert or conf.timeout
    local win_height = vim.api.nvim_win_get_height(0)
    local stopline = matchpair.backward and math.max(1, line - win_height) or (line + win_height)
    local ok, match_pos = pcall(vim.fn.searchpairpos,
                                matchpair.left, '', matchpair.right, flags, '', stopline, timeout)

    if ok then
        match_line = match_pos[1] - 1
        match_col = match_pos[2] - 1
        local move_to_sibling = matchpair.backward and 'prev_sibling' or 'next_sibling'

        while node do
            if is_in_node_range(node, match_line, match_col) then
                return match_line, match_col
            end
            if str_contains(node:type(), COMMENT) then
                node = node[move_to_sibling](node)
                if not (node and str_contains(node:type(), COMMENT)) then return end
            else
                return
            end
        end
    end
end

function M.in_ts_skip_groups()
    local line, col = unpack(vim.api.nvim_win_get_cursor(0))

    if vim.fn.foldclosed(line) ~= -1 then
        return false
    end

    local node = M.node_at(conf.ts_root, line - 1, col)
    local full_node = M.get_node_of_type(node, conf.ts_skip_groups)

    return full_node and true or false
end

-- Returns 0-based line and column of matched bracket if any or nil
-- @param matchpair
-- @param line 1-based current line number
-- @param insert (boolean) true if in insert mode
-- @return number, number or nil
function M.get_match_pos(matchpair, line, insert)
    local flags = matchpair.backward and 'bnW' or 'nW'
    local timeout = insert and conf.timeout_insert or conf.timeout
    local win_height = vim.api.nvim_win_get_height(0)
    local stopline = matchpair.backward and math.max(1, line - win_height) or (line + win_height)
    local ok, match_pos = pcall(vim.fn.searchpairpos,
                                matchpair.left, '', matchpair.right, flags, 'matchparen#ts_skip()', stopline, timeout)

    if not ok or match_pos[1] == 0 then return end
    return match_pos[1] - 1, match_pos[2] - 1
end

return M
