local conf = require('matchparen').config

local ts = vim.treesitter
local a = vim.api
local f = vim.fn
local max = math.max
local find = string.find

local comment = 'comment'

local M = {}

-- copied from nvim-tresitter plugin
-- https://github.com/nvim-treesitter/nvim-treesitter/blob/master/lua/nvim-treesitter/ts_utils.lua

--- Determines whether (line, col) position is in node range
-- @param node Node defining the range
-- @param line A line (0-based)
-- @param col A column (0-based)
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

function M.root()
    local ok, parser = pcall(ts.get_parser)
    if ok then
        return true, parser:parse()[1]:root()
    else
        return false, nil
    end
end

function M.node_at(root, line, col)
    return root:descendant_for_range(line, col, line, col + 1)
end

local function str_contains(str, pattern)
    if find(str, pattern, 1, true) then
        return true
    end

    return false
end

local function is_in_tree_of_type(node, types)
    while node ~= nil do
        for _, type in ipairs(types) do
            if str_contains(node:type(), type) then
                return true, node, type
            end
        end
        node = node:parent()
    end

    return false
end

local function get_match_pos(node, matchpair)
    local match
    local move_to_sibling
    if matchpair.backward then
        match = matchpair.opening
        move_to_sibling = 'prev_sibling'
    else
        match = matchpair.closing
        move_to_sibling = 'next_sibling'
    end

    while true do
        node = node[move_to_sibling](node)

        if not node then return end

        if node:type() == match then
            local match_line, match_col, _, c = node:range()

            if c - match_col == 0 then return end

            return match_line, match_col
        end
    end
end

function M.match(char, node, line, insert)
    local match_line
    local match_col

    local ok, full_node, type = is_in_tree_of_type(node, conf.ts_skip_captures)

    if ok then
        local mp = conf.matchpairs[char]
        local flags = mp.backward and 'bnW' or 'nW'
        local timeout = insert and conf.timeout_insert or conf.timeout
        local win_height = a.nvim_win_get_height(0)
        local stopline = mp.backward and max(1, line - win_height) or (line + win_height)
        local match_pos

        ok, match_pos = pcall(f.searchpairpos, mp.opening, '', mp.closing, flags, '', stopline, timeout)

        if ok then
            match_line = match_pos[1] - 1
            match_col = match_pos[2] - 1
            local move_to_sibling = mp.backward and 'prev_sibling' or 'next_sibling'

            while full_node do
                if is_in_node_range(full_node, match_line, match_col) then
                    return match_line, match_col
                end

                if type == comment then
                    full_node = full_node[move_to_sibling](full_node)

                    if not (full_node and str_contains(full_node:type(), comment)) then return end
                else
                    return
                end
            end
        end
    end

    if node:type() == char then
        return get_match_pos(node, conf.matchpairs_ts[char])
    end

end

return M
