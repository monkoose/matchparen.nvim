local conf = require('matchparen').config
local ts_utils = require('nvim-treesitter.ts_utils')
local ts_hl = vim.treesitter.highlighter

local a = vim.api
local f = vim.fn
local t_contains = vim.tbl_contains

local M = {}

-- most part taken from treesitter-playground
local function get_ts_captures()
    local buf = a.nvim_get_current_buf()
    local row, col = unpack(a.nvim_win_get_cursor(0))
    row = row - 1

    local self = ts_hl.active[buf]

    if not self then
        return {}
    end

    local matches = {}

    self.tree:for_each_tree(function(tstree, tree)
        if not tstree then return end

        local root = tstree:root()
        local root_start_row, _, root_end_row, _ = root:range()
        -- Only worry about trees within the line range
        if root_start_row > row or root_end_row < row then return end

        local query = self:get_query(tree:lang())
        -- Some injected languages may not have highlight queries.
        if not query:query() then return end

        local iter = query:query():iter_captures(root, self.bufnr, row, row + 1)

        for id, node in iter do
            if ts_utils.is_in_node_range(node, row, col) then
                table.insert(matches, query._query.captures[id])
            end
        end
    end, true)

    return matches
end

local function in_ts_skip_block()
    for _, capture in ipairs(get_ts_captures()) do
        if t_contains(conf.ts_skip_captures, capture) then
            return true
        end
    end

    return false
end

local function in_syn_skip_block()
    local line, col = unpack(a.nvim_win_get_cursor(0))

    if f.foldclosed(line) ~= -1 then
        return false
    end

    for _, id in ipairs(f.synstack(line, col + 1)) do
        local synname = string.lower(f.synIDattr(id, 'name'))

        for _, pattern in ipairs(conf.syn_skip_names) do
            if string.find(synname, pattern) then
                return true
            end
        end
    end

    return false
end

function M.skip()
    if vim.opt.syntax:get() ~= '' and in_syn_skip_block() then
        return true
    end

    return in_ts_skip_block()
end

return M
