local conf = require('matchparen').config

local M = {}

-- Returns matched position of vim.fn.searchpairpos call
-- @param matchpair
-- @param skip_ref string vim function reference
-- @param line number 1-based line number
-- @param insert boolean is in insert mode
-- @return (number, number) or nil
function M.search_pair_pos(matchpair, skip_ref, line, insert)
    local flags = matchpair.backward and 'bnW' or 'nW'
    local timeout = insert and conf.timeout_insert or conf.timeout
    local win_height = vim.api.nvim_win_get_height(0)
    -- highlight characters offscreen, so such characters scrolled into view would be highlited
    local stopline = matchpair.backward and math.max(1, line - win_height) or (line + win_height)
    -- `searchpairpos()` can cause errors when evaluating `skip_ref` expression
    -- so it should be handled
    local ok, match_pos = pcall(vim.fn.searchpairpos,
                                matchpair.left,
                                '',
                                matchpair.right,
                                flags,
                                skip_ref,
                                stopline,
                                timeout)
    if ok and match_pos[1] > 0 then
        -- `searchpairpos()` returns 1-based results, but we work with 0-based
        return match_pos[1] - 1, match_pos[2] - 1
    end
end

return M
