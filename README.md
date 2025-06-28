## Matchparen.nvim
### An alternative to the default neovim matchparen plugin

matchparen.nvim fixes several bugs in the default plugin, including:
- Wrong highlights of matched characters in comments and strings in files with TreeSitter syntax highlighting
- Highlighting is properly disabled for plugins like [hop.nvim](https://github.com/phaazon/hop.nvim)
- Doesn't recolor characters in floating windows
- And some other

It is also much faster in some situations and doesn't cause cursor movement lag.

> [!IMPORTANT]
> Highlighting should work as expected, but jumping to highlighted
> brackets with `%` or text objects like `i(`, `a[`, etc. is not implemented yet, so it
> could work improperly when there are unmatched brackets in strings or
> comments inside highlighted brackets. You will have the same behavior with the default plugin.

---

### 📦 Installation

Here's an example for the 💤[lazy](https://github.com/folke/lazy.nvim) plugin
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

If you are using another plugin manager, you can disable the built-in
matchparen plugin with `vim.g.loaded_matchparen = 1` somewhere in your neovim
config.

---

### ⚒️ Configuration

```lua
require('matchparen').setup({
    -- Set to `false` to disable at matchpren at startup
    -- Enable matchparen manually with `:MatchParenEnable`
    enabled = true,
    -- Highlight group of the matched brackets
    -- Change it to any other or adjust colors of "MathParen" highlight group
    -- in your colorscheme to your liking
    hl_group = 'MatchParen',
    -- Debounce time in milliseconds for rehighlighting brackets
    -- Set to 0 to disable debouncing
    debounce_time = 60,
})
```

---

### 🚀 Usage

There are two commands to temporarily disable or enable the plugin:
```
:MatchParenDisable
:MatchParenEnable
```

---

### 🌟 License

MIT license
