local conf = require('matchparen').config
local hl = require('matchparen.highlight')
local mp = require('matchparen')

local M = {}

-- @return (table)
local function splitted_matchpairs()
    local t = {}
    for _, pair in ipairs(vim.opt.matchpairs:get()) do
        -- matchpairs option devide each pair with `:`, so we split by it
        local left, right = pair:match('(.+):(.+)')
        t[left] = right
    end
    return t
end

-- generates value for `matchpairs` table
-- @return (table)
local function matchpairs_value(left, right, backward)
    -- `[` and `]` should be escaped to process by vim regex in `searchpairpos()`
    local escape_symbols = ']['

    return {
        left = vim.fn.escape(left, escape_symbols),
        right = vim.fn.escape(right, escape_symbols),
        backward = backward
    }
end

-- Updates `matchpairs` table only if it was changed can be changed by buffer local option
function M.create_matchpairs()
    if conf.cached_matchpairs_opt == vim.o.matchpairs then return end

    conf.matchpairs = {}
    conf.matchpairs_ts = {}
    conf.cached_matchpairs_opt = vim.o.matchpairs
    for l, r in pairs(splitted_matchpairs()) do
        conf.matchpairs[l] = matchpairs_value(l, r, false)
        conf.matchpairs[r] = matchpairs_value(l, r, true)
        -- for now matchpairs_ts is required because lua doesn't accept escaped `][`
        conf.matchpairs_ts[l] = { left = l, right = r, backward = false }
        conf.matchpairs_ts[r] = { left = l, right = r, backward = true }
    end
end

-- Enables plugin
function M.enable()
    mp.create_autocmds()
    M.create_matchpairs()
    hl.update()
end

-- Disables plugin
function M.disable()
    mp.remove_autocmds()
    hl.remove()
end

return M
