local conf = require('matchparen').config
local hl = require('matchparen.highlight')
local mp = require('matchparen')

local M = {}

---Returns splitted by `:` matchpairs vim option
---@return table
local function split_matchpairs_option()
    local t = {}
    for _, pair in ipairs(vim.opt.matchpairs:get()) do
        -- matchpairs option divide each pair with `:`, so we split by it
        local left, right = pair:match('(.+):(.+)')
        t[left] = right
    end
    return t
end

---Updates `matchpairs` conf option only if it was changed,
---can be changed by buffer local option
function M.create()
    if conf.cached_matchpairs == vim.o.matchpairs then return end

    conf.cached_matchpairs = vim.o.matchpairs
    conf.matchpairs = {}
    for l, r in pairs(split_matchpairs_option()) do
        conf.matchpairs[l] = { left = l, right = r, backward = false }
        conf.matchpairs[r] = { left = l, right = r, backward = true }
    end
end

---Enables the plugin
function M.enable()
    mp.create_autocmds()
    M.create()
    hl.pcall_update()
end

---Disables the plugin
function M.disable()
    mp.remove_autocmds()
    hl.remove()
end

return M
