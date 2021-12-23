local conf = require('matchparen').config

local M = {}

-- Returns true if built-in syntax is on and has syntax for buffer filetype
local function is_syntax_on()
    return vim.g.syntax_on == 1 and vim.opt.syntax:get() ~= ''
end

-- Returns true if the cursor is inside neovim syntax id name
-- that match any value in `syntax_skip_groups` option list
-- @return (bool)
function M.in_syntax_skip_groups()
    local line, col = unpack(vim.api.nvim_win_get_cursor(0))

    if vim.fn.foldclosed(line) ~= -1 then
        return false
    end

    for _, id in ipairs(vim.fn.synstack(line, col + 1)) do
        local synname = string.lower(vim.fn.synIDattr(id, 'name'))
        for _, pattern in ipairs(conf.syntax_skip_groups) do
            if string.find(synname, pattern) then
                return true
            end
        end
    end
    return false
end

-- Returns 0-based line and column of matched bracket if any or nil
-- @param matchpair
-- @param line 0-based current line number
-- @param insert true if in insert mode
-- @return number, number or nil
function M.get_match_pos(matchpair, line, insert)
    local flags = matchpair.backward and 'bnW' or 'nW'
    local timeout = insert and conf.timeout_insert or conf.timeout
    local win_height = vim.api.nvim_win_get_height(0)
    -- highlight characters offscreen, so such characters scrolled into view would be highlited
    local stopline = matchpair.backward and math.max(1, line - win_height) or (line + win_height)
    local skip_ref
    if is_syntax_on() then
        if M.in_syntax_skip_groups() then
            skip_ref = '!matchparen#skip()'
        else
            skip_ref = 'matchparen#skip()'
        end
    else
        skip_ref = ''
    end

    -- `searchpairpos` can cause errors when evaluating `skip_ref` expression
    -- so it should be handled
    local ok, match_pos = pcall(vim.fn.searchpairpos,
                                matchpair.left,
                                '',
                                matchpair.right,
                                flags,
                                skip_ref,
                                stopline,
                                timeout)
    -- `searchpairpos` returns [0, 0] if there is no match, so check for it
    if not ok or match_pos[1] == 0 then return end
    -- `searchpairpos()` returns 1-based results, but we work with 0-based
    return match_pos[1] - 1, match_pos[2] - 1
end

return M
