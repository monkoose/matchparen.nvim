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

For [vim-plug](https://github.com/junegunn/vim-plug)
```vim
Plug 'monkoose/matchparen.nvim'
```

For [packer.nvim](https://github.com/wbthomason/packer.nvim)
```lua
use 'monkoose/matchparen.nvim'
```

### Usage

You need to disable default matchparen plugin
```vim
let g:loaded_matchparen = 1
```
or
```lua
vim.g.loaded_matchparen = 1
```

Initialize it with this line somewhere in your config
```lua
require('matchparen').setup()
```

There is two commands to temporary disable or enable the plugin
```
:MatchParenDisable
:MatchParenEnable
```

### Configuration

```lua
require('matchparen').setup({
    on_startup = true, -- Should it be enabled by default
    timeout = 150, -- timeout in ms to drop searching for matched character in normal mode
    timeout_insert = 50, -- same but in insert mode
    hl_group = 'MatchParen', -- highlight group for matched characters
    augroup_name = 'matchparen',  -- almost no reason to touch this if you don't already have augroup with this name


    -- list of neovim default syntax names to match brackets only in this blocks
    syntax_skip_groups = {
        'string',
        'comment',
        'character',
        'singlequoute',
        'escape',
        'symbol',
    },

    -- list of TreeSitter names to match brackets only in this blocks
    ts_skip_groups = {
        'string',
        'comment',
        'quoted_attribute',
    }
})
```

Some inspiration for built-in syntax was taken from neovim matchparen plugin itself and this [PR](https://github.com/vim/vim/pull/7985) from vim repository by [lacygoill](https://github.com/lacygoill)
