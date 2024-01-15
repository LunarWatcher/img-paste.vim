echo 'img-paste.vim ver 0.3.0 (01/16/2024)'

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

" https://stackoverflow.com/questions/57014805/check-if-using-windows-console-in-vim-while-in-windows-subsystem-for-linux
function! s:IsWSL()
    let lines = readfile("/proc/version")
    if (lines[0] =~ "Microsoft" || lines[0] =~ "microsoft")
        return 1
    endif
    return 0
endfunction

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

    " get directory of current script
    let cmdline = s:scriptdir . '/' . fscript . ' ' . s:imgfullpath

    if s:os == "Windows"
        cmdline = substitute(cmdline, '/', '\\', 'g')
    endif

    "echo 'DEBUG/cmdline: ' . cmdline
    return cmdline
endfunction

function! s:SafeMakeDir(imgsubpath)
    let ch = g:mdip_imgdir[0]
    if ch == '/' || ch == '\\' || ch == '~'
        let outroot = expand(g:mdip_imgdir, ':p')
    else
        let outroot = expand('%:p:h') . '/' . g:mdip_imgdir
    endif
    let imgfullpath = outroot . '/' . a:imgsubpath
    let outdir = fnamemodify(imgfullpath, ':h')
    if s:os == "Windows"
        imgfullpath = substitute(imgfullpath, '/', '\\', 'g')
        outdir = substitute(outdir, '/', '\\', 'g')
    endif
    if !isdirectory(outdir)
        "echo 'DEBUG27 mkdir: ' . outdir
        call mkdir(outdir, "p")
    endif
    if s:os == "Darwin"
        return imgfullpath
    else
        return fnameescape(imgfullpath)
    endif
endfunction

function! s:SaveFileWSL(imgpath) abort
    let imgfile = a:imgpath
    " create an empty file, otherwise wslpath -w will fail
    let result = system('touch ' . imgfile)
    let outfile = system('wslpath -w ' . imgfile)[:-2]
    let outfile = substitute(outfile, '\\', '\\\\', 'g')
    "echo 'DEBUG42: ' . outfile

    let cmdline1 = 'Add-Type -AssemblyName System.Windows.Forms;'
    let cmdline2 = '[System.Windows.Forms.Clipboard]::GetImage().Save'
    let cmdline = 'powershell.exe -command "' . cmdline1 . cmdline2 . "('" . outfile . "')\""
    "echo 'DEBUG: ' . cmdline

    let result = system(cmdline)[:-2]
    if v:shell_error != 0
        let result = system('rm -f ' . imgfile)
        return 1
    endif
    return imgfile
endfunction

function! s:SaveFileLinux(imgpath) abort
    if $WAYLAND_DISPLAY != "" && executable('wl-copy')
        let system_targets = "wl-paste --list-types"
        let system_clip = "wl-paste --no-newline --type %s > %s"
    elseif $DISPLAY != '' && executable('xclip')
        let system_targets = 'xclip -selection clipboard -t TARGETS -o'
        let system_clip = 'xclip -selection clipboard -t %s -o > %s'
    else
        echoerr 'Needs xclip in X11 or wl-clipboard in Wayland.'
        return 1
    endif

    let targets = filter(systemlist(system_targets), 'v:val =~# ''image/''')
    if empty(targets) | return 1 | endif

    if index(targets, "image/png") >= 0
        " Use PNG if available
        let mimetype = "image/png"
        let extension = "png"
    else
        " Fallback
        let mimetype = targets[0]
        let extension = split(mimetype, '/')[-1]
    endif

    call system(printf(system_clip, mimetype, imgpath))
    return imgpath
endfunction

function! s:SaveFileWin32(imgpath) abort
    let imgfile = substitute(a:imgpath, '\\ ', ' ', 'g')

    let clip_command = "Add-Type -AssemblyName System.Windows.Forms;"
    let clip_command .= "if ($([System.Windows.Forms.Clipboard]::ContainsImage())) {"
    let clip_command .= "[System.Drawing.Bitmap][System.Windows.Forms.Clipboard]::GetDataObject().getimage().Save('"
    let clip_command .= imgfile ."', [System.Drawing.Imaging.ImageFormat]::Png) }"
    let clip_command = "powershell -nologo -noprofile -noninteractive -sta \"".clip_command. "\""

    silent call system(clip_command)
    if v:shell_error == 1
        return 1
    else
        return imgfile
    endif
endfunction

function! s:SaveFileMacOS(imgpath) abort
    let imgfile = a:imgpath
    let clip_command = 'osascript'
    let clip_command .= ' -e "set png_data to the clipboard as «class PNGf»"'
    let clip_command .= ' -e "set referenceNumber to open for access POSIX path of'
    let clip_command .= ' (POSIX file \"' . imgfile . '\") with write permission"'
    let clip_command .= ' -e "write png_data to referenceNumber"'

    silent call system(clip_command)
    if v:shell_error == 1
        return 1
    else
        return imgfile
    endif
endfunction

function! s:SaveFile(imgpath)
    "echo 'DEBUG: ' . a:imgpath
    if s:os == "Linux"
        " Linux could also mean Windowns Subsystem for Linux
        if s:IsWSL()
            return s:SaveFileWSL(a:imgpath)
        endif
        return s:SaveFileLinux(a:imgpath)
    elseif s:os == "Darwin"
        return s:SaveFileMacOS(a:imgpath)
    elseif s:os == "Windows"
        return s:SaveFileWin32(a:imgpath)
    endif
endfunction

function! g:MarkdownPasteImage(imgurl)
    "echo 'DEBUG169: ' . a:imgurl
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
    let msg = strftime("%H:%M:%S - ") . 'saved image to ' . s:imgfullpath
    echom msg
    let imgurl = g:mdip_imgsite . '/' . s:imgsubpath
    if call(get(g:, 'PasteImageFunction'), [imgurl])
        return
    endif
endfunction

function! mdip#MarkdownClipboardImageV1()
    " detect os: https://vi.stackexchange.com/questions/2572/detect-os-in-vimscript
    let s:os = "Windows"
    if !(has("win64") || has("win32") || has("win16"))
        let s:os = substitute(system('uname'), '\n', '', '')
    endif

    let imgsubpath = strftime(g:mdip_imgpat)
    let imgfullpath = s:SafeMakeDir(imgsubpath)
    let g:mdip_imgtitle = 'screenshot'

    let imgfile = s:SaveFile(imgfullpath)
    if imgfile == 1
        let msg = strftime("%H:%M:%S - ") . 'no image in clipboard'
        echom msg
        return
    else
        let msg = strftime("%H:%M:%S - ") . 'saved image to ' . imgfile
        echom msg
        let imgurl = g:mdip_imgsite . '/' . imgsubpath
        if call(get(g:, 'PasteImageFunction'), [imgurl])
            return
        endif
    endif
endfunction
