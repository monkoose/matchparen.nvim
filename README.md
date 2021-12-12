## Matchparen.nvim
### alternative to plugin that shipped with neovim

It fixes some bugs of the default plugin like:
- wrong highlights of matched characters in comments and strings in files with TreeSitter syntax highlighting
(for now it just disables this regions)
- highlighting is properly disabled for such plugins like [hop.nvim](https://github.com/phaazon/hop.nvim)
- doesn't recolor characters of floating windows
- and others

In my synthetic tests it is faster by 6-10 times when the cursor is not on a matching character and
1-2 times faster on a matching character (because under the hood this plugin is still using
`searchpairpos()` and `synstack()` functions)

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

You need to disable default matchparen plugin with `let g:loaded_matchparen = 1` or `vim.g.loaded_matchparen = 1`

Defaults just work fine so just add this line somewhere in your config
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


    -- list of neovim default syntax names to skip highlighting
    syn_skip_names = {
        'string',
        'comment',
        'character',
        'singlequoute',
        'escape',
        'symbol',
    },

    -- list of TreeSitter capture names to skip highlighting
    ts_skip_captures = {
        'string',
        'comment'
    }
})
```

Some insiration for this plugin was taken from neovim matchparen plugin itself, this [PR](https://github.com/vim/vim/pull/7985) from vim repository by [lacygoill](https://github.com/lacygoill)

Some code for getting TreeSitter capture names was taken from [playground](https://github.com/nvim-treesitter/playground) plugin
