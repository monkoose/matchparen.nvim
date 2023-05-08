## Matchparen.nvim
### alternative to default neovim matchparen plugin

**main** branch requires neovim v0.7 or higher.

Last version that uses neovim v0.6 is [8df2b17](https://github.com/monkoose/matchparen.nvim/commit/8df2b177cd92c0fa7e4d4a7c1812612d9a59651d).

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

For [vim-plug](https://github.com/junegunn/vim-plug)
```vim
Plug 'monkoose/matchparen.nvim'
```

For [packer.nvim](https://github.com/wbthomason/packer.nvim)
```lua
use 'monkoose/matchparen.nvim'
```

This plugin tries it best to disable built-in plugin before enabling itself,
but if you use `packer` (and it's `config` option to setup `matchparen.nvim`)
or use some kind of lazy loading, then you can check if built-in plugin was
loaded with trying to write and autocomplete such command `:DoMatchParen`.
If it is present then you may want to explicitly disable built-in matchparen
plugin with setting global variable to 1 somewhere in you config outside of
`packer` config option.
```lua
vim.g.loaded_matchparen = 1
```
It would improve startuptime a little bit and will not create unnecessary commands.

### Usage

Initialize the plugin with this line somewhere in your config
```lua
require('matchparen').setup()
```

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
    augroup_name = 'matchparen',  -- almost no reason to touch this unless there is already augroup with such name
    debounce_time = 200, -- debounce time in milliseconds for rehighlighting of brackets.
})
```
Read `:h matchparen.nvim-configuration` for more descriptive explanation of the options.
