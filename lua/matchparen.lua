local defaults = require('matchparen.defaults')

-- commands
local function create_commands()
    vim.cmd [[
        silent! command MatchParenEnable lua require'matchparen.utils'.enable()
        silent! command MatchParenDisable lua require'matchparen.utils'.disable()
    ]]
end

local M = {}

-- Setup
function M.setup(options)
    M.config = vim.tbl_deep_extend('force', defaults, options or {})

    M.config.namespace = vim.api.nvim_create_namespace(M.config.augroup_name)
    M.config.extmarks = { current = 0, match = 0 }

    create_commands()

    if M.config.on_startup then
        M.create_autocmds()
    end
end

-- autocmds
function M.create_autocmds()
    if vim.fn.exists('#' .. M.config.augroup_name) == 0 then
        vim.cmd('augroup ' .. M.config.augroup_name)
        vim.cmd [[
            autocmd!
            autocmd WinEnter,BufWinEnter,FileType,VimEnter * lua require'matchparen.utils'.create_matchpairs()
            autocmd CursorMoved,CursorMovedI * lua require'matchparen.highlight'.update()
            autocmd TextChanged,TextChangedI,WinEnter * lua require'matchparen.highlight'.update()
            autocmd WinLeave,BufLeave * lua require'matchparen.highlight'.remove()
            autocmd OptionSet matchpairs lua require'matchparen.utils'.create_matchpairs()
        augroup END
        ]]
    end
end

function M.remove_autocmds()
    if vim.fn.exists('#' .. M.config.augroup_name) ~= 0 then
        vim.cmd('autocmd! ' .. M.config.augroup_name)
        vim.cmd('augroup! ' .. M.config.augroup_name)
    end
end

return M
