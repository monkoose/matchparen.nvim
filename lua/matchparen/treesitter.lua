local conf = require('matchparen').config

local COMMENT = 'comment'

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
    local ok, parser = pcall(vim.treesitter.get_parser)
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
    return str:find(pattern, 1, true) ~= nil
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

local function get_left_bracket_pos(node, match)
    local parent = node:parent()
    local starts_with = vim.startswith
    local ends_with = vim.endswith
    local node_sl, node_sc = node:range()
    local in_range
    local match_line, match_col

    in_range = function(el, ec)
        return el < node_sl or (el == node_sl and ec <= node_sc)
    end

    for child in parent:iter_children() do
        local child_sl, child_sc, child_el, child_ec = child:range()
        local child_type = child:type()

        if in_range(child_el, child_ec) then
            if starts_with(child_type, match) then
                if child_ec - child_sc == 0 then return end
                match_line = child_sl
                match_col = child_sc
            elseif ends_with(child_type, match) then
                if child_ec - child_sc == 0 then return end
                match_line = child_el
                match_col = child_ec - 1
            end
        else
            return match_line, match_col
        end
    end
end

local function get_right_bracket_pos(node, match)
    local parent = node:parent()
    local starts_with = vim.startswith
    local ends_with = vim.endswith
    local in_range
    local _, _, node_el, node_ec = node:range()

    in_range = function(sl, sc)
        return sl > node_el or (sl == node_el and sc >= node_ec)
    end

    for child in parent:iter_children() do
        local child_sl, child_sc, child_el, child_ec = child:range()
        local child_type = child:type()

        if in_range(child_sl, child_sc) then
            if starts_with(child_type, match) then
                if child_ec - child_sc == 0 then return end
                return child_sl, child_sc
            elseif ends_with(child_type, match) then
                if child_ec - child_sc == 0 then return end
                return child_el, child_ec - 1
            end
        end
    end
end

function M.match(bracket, node, line, col, insert)
    local match_line
    local match_col

    local ok, full_node, type = is_in_tree_of_type(node, conf.ts_skip_captures)

    if ok then
        local mp = conf.matchpairs[bracket]
        local flags = mp.backward and 'bnW' or 'nW'
        local timeout = insert and conf.timeout_insert or conf.timeout
        local win_height = vim.api.nvim_win_get_height(0)
        local stopline = mp.backward and math.max(1, line - win_height) or (line + win_height)
        local match_pos

        ok, match_pos = pcall(vim.fn.searchpairpos, mp.opening, '', mp.closing, flags, '', stopline, timeout)

        if ok then
            match_line = match_pos[1] - 1
            match_col = match_pos[2] - 1
            local move_to_sibling = mp.backward and 'prev_sibling' or 'next_sibling'

            while full_node do
                if is_in_node_range(full_node, match_line, match_col) then
                    return match_line, match_col
                end

                if type == COMMENT then
                    full_node = full_node[move_to_sibling](full_node)

                    if not (full_node and str_contains(full_node:type(), COMMENT)) then return end
                else
                    return
                end
            end
        end
    end

    local node_type = node:type()
    local double_bracket = bracket .. bracket
    local mp_ts = conf.matchpairs_ts[bracket]
    local get_bracket_pos
    local match = mp_ts.backward and mp_ts.opening or mp_ts.closing
    if mp_ts.backward then
        match = mp_ts.opening
        get_bracket_pos = get_left_bracket_pos
    else
        match = mp_ts.closing
        get_bracket_pos = get_right_bracket_pos
    end

    if node_type == double_bracket then
        local _, node_sc = node:range()
        match_line, match_col = get_bracket_pos(node, match .. match)
        local first = col == node_sc
        if first then
            match_col = match_col + 1
        end
        return match_line, match_col
    elseif vim.startswith(node_type, bracket) or vim.endswith(node_type, bracket) then
        return get_bracket_pos(node, match)
    end

end

return M
