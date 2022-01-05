local conf = require('matchparen').config
local hl = require('matchparen.highlight')
local mp = require('matchparen')

local M = {}

-- Returns splitted by `:` matchpairs vim option
-- @return table
local function split()
    local t = {}
    for _, pair in ipairs(vim.opt.matchpairs:get()) do
        -- matchpairs option divide each pair with `:`, so we split by it
        local left, right = pair:match('(.+):(.+)')
        t[left] = right
    end
    return t
end

-- Generates value for `matchpairs` table
-- @return table
local function generate_value(left, right, backward)
    -- `[` and `]` should be escaped to process by vim regex in `searchpairpos()`
    local escape_symbols = ']['

    return {
        left = vim.fn.escape(left, escape_symbols),
        right = vim.fn.escape(right, escape_symbols),
        backward = backward
    }
end

-- Updates `matchpairs` table only if it was changed, can be changed by buffer local option
function M.create()
    if conf.cached_matchpairs == vim.o.matchpairs then return end

    conf.matchpairs = {}
    conf.cached_matchpairs = vim.o.matchpairs
    for l, r in pairs(split()) do
        conf.matchpairs[l] = generate_value(l, r, false)
        conf.matchpairs[r] = generate_value(l, r, true)
    end
end

-- Enables plugin
function M.enable()
    mp.create_autocmds()
    M.create()
    hl.update()
end

-- Disables plugin
function M.disable()
    mp.remove_autocmds()
    hl.remove()
end

return M
