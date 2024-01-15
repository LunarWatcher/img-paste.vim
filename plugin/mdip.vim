echo 'img-paste.vim ver 0.3.1 (01/16/2024)'

let s:scriptdir = fnamemodify(resolve(expand('<sfile>:p')), ':h')
if !exists('g:mdip_imgdir')
    let g:mdip_imgdir = 'img'
endif
if !exists('g:mdip_imgsite')
    let g:mdip_imgsite = g:mdip_imgdir
endif
if !exists('g:mdip_imgpat')
    let g:mdip_imgpat = '%Y%m%d-%H%M%S.png'
endif

function! s:GetCmdLine()
    let s:os = "Windows"
    let fscript = 'img-paste.ps1'
    if !(has("win64") || has("win32") || has("win16"))
        let s:os = substitute(system('uname'), '\n', '', '')
        let fscript = 'img-paste.sh'
    endif

    let ch = g:mdip_imgdir[0]
    if ch == '/' || ch == '\\' || ch == '~'
        let outroot = expand(g:mdip_imgdir, ':p')
    else
        let outroot = expand('%:p:h') . '/' . g:mdip_imgdir
    endif

    let s:imgsubpath = strftime(g:mdip_imgpat)
    let s:imgfullpath = outroot . '/' . s:imgsubpath

    let cmdline = s:scriptdir . '/' . fscript . ' ' . s:imgfullpath

    if s:os == "Windows"
        cmdline = substitute(cmdline, '/', '\\', 'g')
    endif

    return cmdline
endfunction

function! g:MarkdownPasteImage(imgurl)
    execute "normal! i![" . g:mdip_imgtitle[0:0]
    let ipos = getcurpos()
    execute "normal! a" . g:mdip_imgtitle[1:] . "](" . a:imgurl . ")"
    call setpos('.', ipos)
    execute "normal! vt]\<C-g>"
endfunction

function! g:LatexPasteImage(imgurl)
    execute "normal! i\\includegraphics{" . a:imgurl . "}\r\\caption{I"
    let ipos = getcurpos()
    execute "normal! a" . "mage}"
    call setpos('.', ipos)
    execute "normal! ve\<C-g>"
endfunction

function! g:EmptyPasteImage(imgurl)
    execute "normal! i" . a:imgurl
endfunction

let g:PasteImageFunction = 'g:MarkdownPasteImage'

function! mdip#MarkdownClipboardImage()
    let cmdline = s:GetCmdLine()
    let result = system(cmdline)[:-2]
    if v:shell_error != 0
        let msg = strftime("%H:%M:%S - ") . 'no image in clipboard'
        echom msg
        return
    endif

    let g:mdip_imgtitle = 'screenshot'
    "let msg = strftime("%H:%M:%S - ") . 'saved image to ' . s:imgfullpath
    "echom msg
    let imgurl = g:mdip_imgsite . '/' . s:imgsubpath
    if call(get(g:, 'PasteImageFunction'), [imgurl])
        return
    endif
endfunction
