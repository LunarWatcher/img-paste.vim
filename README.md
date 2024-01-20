# img-paste.vim

vim/neovim plugin. Paste image, auto save to specified dir/name, and generate markdown link.

Rewrite of [img-paste-devs/img-paste.vim](https://github.com/img-paste-devs/img-paste.vim). Simplify it, and make it work for current WSL.

- Auto naming the image files with pattern.
- Separate the scripts for debugging standalone.

## Use Cases

### Relative directory

Configuration in .vimrc, vimrc

```
let g:mdip_imgsite = 'img'
let g:mdip_imgroot = 'img'
let g:mdip_imgfile = '%Y%m%d-%H%M%S.png'
```

- Save image to "img" sub dir (relative to current document),
- Generate link like "! [screenshot] (img/20240120-201435.png)"

### Absolute directory

Configuration in .vimrc

```
let g:mdip_imgsite = '/img'
let g:mdip_imgroot = '~/Pictures/screenshot'
let g:mdip_imgfile = '%Y/%m/%d-%H%M%S-%R.png'
```

- Store all images to ~/Pictures/screenshot
- Oranized by year & month
- Generate link like "! [screenshot] (/img/2024/01/20-201435-1ac8d5f.png)"

To manage all your screenshots in a picture web site, you can config like this way.
You can also use a web site url. e.g.

```vim
let g:mdip_imgsite = 'https://pic.my.site/img'
```

The link will be

! [screenshot] (https://pic.my.site/img/2024/01/20-201435-1ac8d5f.png)

## Pattern of file name/path

- g:mdip_imgfile supports pattern in [strftime](https://strftime.org/)
- can use "/" in the pattern. "/" will auto create sub directories.
- use "%R" for a 6-char random string.

## Installation & Configuration

vimrc for [vim-plug](https://github.com/junegunn/vim-plug),
[Vundle.vim](https://github.com/VundleVim/Vundle.vim), etc

```vim
Plugin 'loblab/img-paste.vim'

nnoremap <C-i> :call mdip#MarkdownClipboardImage()<CR>
```

init.lua for [lazy.vim](https://github.com/folke/lazy.nvim)

```lua
require('lazy').setup({
  ...
  'loblab/img-paste.vim',
  ...
})
```

## Tested on

- vim 9.1, nevim 0.9.5, 0.10.0
- WSL2 on Windows 10/11
- Linux: Ubuntu 20/22, Arch Linux
