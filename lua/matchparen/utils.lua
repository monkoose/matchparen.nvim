local conf = require('matchparen').config
local hl = require('matchparen.highlight')
local mp = require('matchparen')

local f = vim.fn

local M = {}

local function splitted_matchpairs()
    local t = {}

    for _, pair in ipairs(vim.opt.matchpairs:get()) do
        -- matchpairs option devide each pair with `:`, so we split by it
        local opening, closing = pair:match('(.+):(.+)')
        t[opening] = closing
    end

    return t
end

-- generates value for `matchpairs` table
local function matchpairs_value(opening, closing, backward)
    -- `[` and `]` should be escaped to process by searchpairpos()
    local escape_symbols = ']['

    return {
        opening = f.escape(opening, escape_symbols),
        closing = f.escape(closing, escape_symbols),
        backward = backward
    }
end

function M.create_matchpairs()
    if conf.cached_matchpairs_opt == vim.o.matchpairs then return end

    conf.cached_matchpairs_opt = vim.o.matchpairs

    conf.matchpairs = {}
    for o, c in pairs(splitted_matchpairs()) do
        conf.matchpairs[o] = matchpairs_value(o, c, false)
        conf.matchpairs[c] = matchpairs_value(o, c, true)
    end
end

function M.enable()
    mp.create_autocmds()
    M.create_matchpairs()
    hl.update()
end

function M.disable()
    mp.remove_autocmds()
    hl.remove()
end

return M
