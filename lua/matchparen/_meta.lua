---@meta types

---Determines what to do with the search result for the position `line`, `col`.
---@alias SkipFunction fun(line: integer, col: integer, bracket?: string): SearchStatus

---@alias MatchPairTable { left: string, right: string, pattern: string, backward: boolean }

---@class MatchParenOptions
---@field enabled boolean # Determines whether the plugin should be enabled at neovim startup
---@field hl_group string
---@field skip_folds boolean # Determines whether the plugin should skip closed folds

---@class MatchParenConfig
---@field enabled? boolean # Determines whether the plugin should be enabled at neovim startup
---@field hl_group? string
---@field skip_folds? boolean # Determines whether the plugin should skip closed folds
