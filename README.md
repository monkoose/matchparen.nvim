## Matchparen.nvim
### alternative to default neovim matchparen plugin

**BE AWARE:** highlighting should work as expected, but jumping to highlighted
bracket with `%` or text objects as `i(`, `a[` etc not implemented yet, so it
could work improperly when there are some unmatched brackets in strings or
comments inside highlighted brackets. With default plugin you will have the
same behavior.

It fixes some bugs of the default plugin like:
- wrong highlights of matched characters in comments and strings in files with TreeSitter syntax highlighting
- highlighting is properly disabled for such plugins like [hop.nvim](https://github.com/phaazon/hop.nvim)
- doesn't recolor characters of floating windows
- and others

It is also much faster (5-10 times in my synthetic tests).

### Installation

Here’s an example for 💤[lazy](https://github.com/folke/lazy.nvim) plugin
manager. If you're using a different plugin manager, please refer to its
documentation for installation instructions.

```lua
require("lazy").setup({
    performance = {
        rtp = {
            disabled_plugins = {
                -- disable built-in matchparen plugin
                "matchparen",
                -- ... (other built-in plugins you want to disable)
            },
        },

    },
    -- ... (other lazy options)

    -- plugins
    spec = {
        {
            "monkoose/matchparen.nvim",
            config = function()
                require("matchparen").setup()
            end,
        },
        -- ... (other plugins)
    }
})
```

If you are using some other plugin manager, you can disable the built-in
matchparen plugin with `vim.g.loaded_matchparen = 1` somewhere in your neovim
config.

### Usage

There are two commands to temporary disable or enable the plugin
```
:MatchParenDisable
:MatchParenEnable
```

### Configuration

```lua
require('matchparen').setup({
    on_startup = true, -- Should it be enabled by default
    hl_group = 'MatchParen', -- highlight group of the matched brackets
    debounce_time = 60, -- debounce time in milliseconds for rehighlighting of brackets.
})
```
Read `:h matchparen.nvim-configuration` for more descriptive explanation of the options.
