vim9script

import autoload "imgpaste/util.vim" as util

export def Format(imgurl: string)
    util.Insert("![insert alt text here](" .. imgurl .. ")")
enddef
