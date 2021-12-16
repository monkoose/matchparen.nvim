local conf = require('matchparen').config

local a = vim.api
local f = vim.fn
local g = vim.g
local max = math.max

local M = {}

local function is_syntax_on()
    return g.syntax_on == 1 and vim.opt.syntax:get() ~= ''
end

-- Returns true if the cursor is inside neovim syntax id name
-- that match any value in `synnames` list
-- @param synnames (table)
-- @return (bool)
function M.skip()
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

function M.match(matchpair, line, insert)
    local skip = is_syntax_on() and 'matchparen#skip()' or ''
    local starts = matchpair.opening
    local ends = matchpair.closing
    local backward = matchpair.backward
    local flags = backward and 'bnW' or 'nW'
    local timeout = insert and conf.timeout_insert or conf.timeout
    -- calculate how many lines `searchpairpos` should search before stop
    -- so we highlight characters even offscreen, so such characters scrolled into view
    -- would be highlited
    local win_height = a.nvim_win_get_height(0)
    local stopline = backward and max(1, line - win_height) or (line + win_height)
    local ok, match_pos

    if M.skip() then
        ok, match_pos = pcall(f.searchpairpos, starts, '', ends, flags, '!matchparen#skip()', stopline, timeout)
    else
        -- `searchpairpos` can cause errors when evaluating `skip` expression so it should be handled
        -- `searchpairpos` returns [0, 0] if there is no match
        ok, match_pos = pcall(f.searchpairpos, starts, '', ends, flags, skip, stopline, timeout)
    end

    return ok, match_pos[1] - 1, match_pos[2] - 1
end

return M
