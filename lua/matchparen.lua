local defaults = require('matchparen.defaults')

local M = {}

local function augroup_exists(name)
    return vim.fn.exists('#' .. name) ~= 0
end

-- commands
local function create_commands()
    vim.cmd [[
        silent! command MatchParenEnable lua require'matchparen.matchpairs'.enable()
        silent! command MatchParenDisable lua require'matchparen.matchpairs'.disable()
    ]]
end

-- setup
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
    if not augroup_exists(M.config.augroup_name) then
        vim.cmd('augroup ' .. M.config.augroup_name)
        vim.cmd [[
            autocmd!
            autocmd WinEnter,BufWinEnter,FileType,VimEnter * lua require'matchparen.matchpairs'.create()
            autocmd CursorMoved,CursorMovedI,WinEnter * lua require'matchparen.highlight'.update()
            autocmd InsertEnter * lua require'matchparen.highlight'.update(true)
            autocmd TextChanged,TextChangedI * lua require'matchparen.highlight'.update_on_tick()
            autocmd WinLeave,BufLeave * lua require'matchparen.highlight'.remove()
            autocmd OptionSet matchpairs lua require'matchparen.matchpairs'.create()
        augroup END
        ]]
    end
end

function M.remove_autocmds()
    if augroup_exists(M.config.augroup_name) then
        vim.cmd('autocmd! ' .. M.config.augroup_name)
        vim.cmd('augroup! ' .. M.config.augroup_name)
    end
end

return M
