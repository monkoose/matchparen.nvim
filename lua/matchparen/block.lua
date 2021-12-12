local conf = require('matchparen').config
local ts_utils = require('nvim-treesitter.ts_utils')
local ts_hl = vim.treesitter.highlighter

local a = vim.api
local f = vim.fn

local M = {}

-- implementation of this function taken from
-- https://github.com/nvim-treesitter/playground/blob/master/lua/nvim-treesitter-playground/hl-info.lua

-- @return (table) list of ts captures under the cursor
local function get_ts_captures()
    local buf = a.nvim_get_current_buf()
    local line, col = unpack(a.nvim_win_get_cursor(0))
    line = line - 1

    local self = ts_hl.active[buf]

    if not self then
        return {}
    end

    local captures = {}

    self.tree:for_each_tree(function(tstree, tree)
        if not tstree then return end

        local root = tstree:root()
        local root_start_line, _, root_end_line, _ = root:range()
        -- Only worry about trees within the line range
        if root_start_line > line or root_end_line < line then return end

        local query = self:get_query(tree:lang())
        -- Some injected languages may not have highlight queries.
        if not query:query() then return end

        local iter = query:query():iter_captures(root, self.bufnr, line, line + 1)

        for id, node in iter do
            if ts_utils.is_in_node_range(node, line, col) then
                table.insert(captures, query._query.captures[id])
            end
        end
    end, true)

    return captures
end

-- Returns true if the cursor is inside treesitter captures
-- that match any value in `captures` list
-- @param captures (table)
-- @return (bool)
local function in_ts_block(captures)
    for _, capture in ipairs(get_ts_captures()) do
        if vim.tbl_contains(captures, capture) then
            return true
        end
    end

    return false
end

-- Returns true if the cursor is inside neovim syntax id name
-- that match any value in `synnames` list
-- @param synnames (table)
-- @return (bool)
local function in_syn_block(synnames)
    local line, col = unpack(a.nvim_win_get_cursor(0))

    if f.foldclosed(line) ~= -1 then
        return false
    end

    for _, id in ipairs(f.synstack(line, col + 1)) do
        local synname = string.lower(f.synIDattr(id, 'name'))

        for _, pattern in ipairs(synnames) do
            if string.find(synname, pattern) then
                return true
            end
        end
    end

    return false
end

-- Returns true if the cursor is inside looking for synnames or
-- treesitter captures
function M.skip()
    if vim.opt.syntax:get() ~= '' and in_syn_block(conf.syn_skip_names) then
        return true
    end

    return in_ts_block(conf.ts_skip_captures)
end

return M
