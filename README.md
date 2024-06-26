# img-paste.vim

Heavily refactored version of [loblab/img-paste.vim](https://github.com/loblab/img-paste.vim) (which itself is a rewrite of [img-paste-devs/img-paste.vim](https://github.com/img-paste-devs/img-paste.vim)). Also rewritten with vim9script, because I can :)

## Quick start

```vim
" for vim-plug, change for your plugin manager
Plug 'LunarWatcher/img-paste.vim'
```

Use `<C-i>` in normal mode to paste images. Config coming Soon:tm:. See also `:h imgpaste` for more documentation.

## Changes from upstream
* Vim9script
* There's a well-defined interface for defining arbitrary custom paste formats, and for defining what filetypes use what format

## License 

MIT; see the LICENSE file. Note that the LICENSE file was added on 2024-06-25; prior to this, the repo did not have a LICENSE file at all.
