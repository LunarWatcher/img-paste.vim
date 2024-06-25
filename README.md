# img-paste.vim

Heavily refactored version of [loblab/img-paste.vim](https://github.com/loblab/img-paste.vim) (which itself is a rewrite of [img-paste-devs/img-paste.vim](https://github.com/img-paste-devs/img-paste.vim)). Also rewritten with vim9script, because I can :)

**NOTE:** The plugin is currently borked, as it's in the middle of a major refactor.

## Quick start

```vim
" for vim-plug, change for your plugin manager
Plug 'LunarWatcher/img-paste.vim'

" modify for your keymap setting
nnoremap <C-i> :call imgpaste#MarkdownClipboardImage()<CR>
```

## License 

MIT; see the LICENSE file. Note that the LICENSE file was added on 2024-06-25; prior to this, the repo did not have a LICENSE file at all.
