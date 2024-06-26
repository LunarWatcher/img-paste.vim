vim9script

export def Insert(text: string)
    exec "normal! a" .. text
enddef
