## Matchparen.nvim
### alternative to default neovim matchparen plugin

**main** branch requires neovim v0.7 or higher.

Last version that uses neovim v0.6 can be found at this commit 8df2b177cd92c0fa7e4d4a7c1812612d9a59651d.

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
    hl_group = 'MatchParen', -- highlight group for matched characters
    augroup_name = 'matchparen',  -- almost no reason to touch this unless


    -- list of neovim default syntax names to match brackets only in this blocks
    syntax_skip_groups = {
        'string',
        'comment',
        'character',
        'singlequoute',
        'escape',
        'symbol',
    },

    -- list of TreeSitter query captures to match brackets only in this blocks
    ts_skip_groups = {
        'string',
        'comment',
    }
})
```
