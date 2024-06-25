
g:ImgpasteFormatMap = extend(
    {
        'markdown': 'markdown',
        'tex': 'tex'
    },
    get(g:, 'ImgpasteFormatMap', {})
)

let s:scriptdir = fnamemodify(resolve(expand('<sfile>:p')), ':h')
if !exists('g:mdip_imgroot')
    let g:mdip_imgroot = 'img'
endif
if !exists('g:mdip_imgsite')
    let g:mdip_imgsite = g:mdip_imgroot
endif
if !exists('g:mdip_imgfile')
    let g:mdip_imgfile = '%Y%m%d-%H%M%S.png'
endif

function! s:GetCmdLine()
    let s:os = "Windows"
    let fscript = 'img-paste.ps1'
    if !(has("win64") || has("win32") || has("win16"))
        let s:os = substitute(system('uname'), '\n', '', '')
        let fscript = 'img-paste.sh'
    endif

    let ch = g:mdip_imgroot[0]
    if ch == '/' || ch == '\\' || ch == '~'
        let outroot = expand(g:mdip_imgroot, ':p')
    else
        let outroot = expand('%:p:h') . '/' . g:mdip_imgroot
    endif

    let rstr = printf('%06x', rand() % 0xffffff)
    let pattern = substitute(g:mdip_imgfile, '%R', rstr, 'g')
    let s:imgsubpath = strftime(pattern)
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
    let cmdline = s:GetCmdLine() . ' 2>&1 >/dev/null'
    let errmsg = system(cmdline)
    if v:shell_error != 0
        let errmsg = substitute(errmsg, '\s*\r*\n$', '', 'g')
        let msg = strftime("%H:%M:%S - ") . errmsg
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
