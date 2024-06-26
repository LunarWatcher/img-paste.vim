vim9script

import autoload "imgpaste/util.vim" as util

export def Format(imgurl: string)
    util.Insert(imgurl)
enddef
