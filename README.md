## Matchparen.nvim
### alternative to plugin that shipped with neovim

It fixes some bugs of the default plugin like:
- wrong highlights of matched characters in comments and strings in files with TreeSitter syntax highlighting
- highlighting is properly disabled for such plugins like [hop.nvim](https://github.com/phaazon/hop.nvim)
- doesn't recolor characters of floating windows
- and others

It is also much faster (~10 times in my synthetic tests) in treesitter parsed buffers and without any
spikes, so highlighting of matched parens should not exceed 2-3ms and in most cases it is less then 0.2ms on
my laptop. In buffers that are not parsed by treesitter it is still faster when cursor is not at matching paren
at the same ~10 times, but on matched it is still take almost the same time as default plugin and in some situations
with high spikes of 100ms+ to highlighting matched parens (once again the same as default), mostly because of slow `synstack()` function.

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


    -- list of neovim default syntax names to match parens only in this blocks
    syn_skip_names = {
        'string',
        'comment',
        'character',
        'singlequoute',
        'escape',
        'symbol',
    },

    -- list of TreeSitter capture names to match parens only in this blocks
    ts_skip_captures = {
        'string',
        'comment'
    }
})
```

Some inspiration for built-in syntax was taken from neovim matchparen plugin itself and this [PR](https://github.com/vim/vim/pull/7985) from vim repository by [lacygoill](https://github.com/lacygoill)
