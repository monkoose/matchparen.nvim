local ts = vim.treesitter

local comment = 'comment'

local M = {}

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

function M.is_type_of(node, type)
    return node:type() == type
end

function M.comments_range(node, backward)
    local start = node
    local end_ = node

    local move_to_sibling = backward and 'prev_sibling' or 'next_sibling'
    while true do
        node = node[move_to_sibling](node)
        if node and M.is_type_of(node, comment) then
            end_ = node
        else
            break
        end
    end

    -- s - start, e - end, l - line, c - column
    local start_sl, start_sc, start_el, start_ec = start:range()
    local end_sl, end_sc, end_el, end_ec = end_:range()

    if end_sl > start_sl then
        return start_sl, start_sc, end_el, end_ec
    else
        return end_sl, end_sc, start_el, start_ec
    end
end

function M.get_match_pos(node, matchpair)
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

        if M.is_type_of(node, match) then
            local match_line, match_col, _, c = node:range()

            if c - match_col == 0 then return end

            return match_line, match_col
        end
    end
end

return M
