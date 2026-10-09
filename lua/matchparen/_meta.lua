---@meta types

---Determines what to do for the position `line`, `col`.
---First return value answers if the position is to be skipped (continue the search).
---Second optional return value answers if the search should be stopped (break the search).
---@alias SkipFunction fun(line: integer, col: integer): boolean, boolean|nil

---@alias MatchPairTable { left: string, right: string, pattern: string, backward: boolean }
