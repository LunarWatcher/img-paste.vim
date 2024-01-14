" ver 0.2.1 (01/14/2024)

" https://stackoverflow.com/questions/57014805/check-if-using-windows-console-in-vim-while-in-windows-subsystem-for-linux
function! s:IsWSL()
    let lines = readfile("/proc/version")
    if (lines[0] =~ "Microsoft" || lines[0] =~ "microsoft")
        return 1
    endif
    return 0
endfunction

function! s:SafeMakeDir()
    if !exists('g:mdip_imgdir_absolute')
        if s:os == "Windows"
            let outdir = expand('%:p:h') . '\' . g:mdip_imgdir
        else
            let outdir = expand('%:p:h') . '/' . g:mdip_imgdir
        endif
    else
        let outdir = g:mdip_imgdir
    endif
    echo 'DEBUG22: ' . outdir
    if !isdirectory(outdir)
        echo 'DEBUG24 mkdir: ' . outdir
        call mkdir(outdir,"p")
    endif
    if s:os == "Darwin"
        return outdir
    else
        return fnameescape(outdir)
    endif
endfunction

function! s:SaveFileTMPWSL(imgdir, tmpname) abort
    let tmpfile = a:imgdir . '/' . a:tmpname . '.png'
    let outfile = system('wslpath -w ' . tmpfile)[:-2]
    let outfile = substitute(outfile, '\\', '\\\\', 'g')
    echo 'DEBUG: ' . outfile

    let cmdline1 = 'Add-Type -AssemblyName System.Windows.Forms;'
    let cmdline2 = '[System.Windows.Forms.Clipboard]::GetImage().Save'
    let cmdline = 'powershell.exe -command "' . cmdline1 . cmdline2 . "('" . outfile . "')\""
    echo 'DEBUG: ' . cmdline

    let result = system(cmdline)[:-2]
    echo 'DEBUG: ' . result
    return tmpfile
endfunction

function! s:SaveFileTMPLinux(imgdir, tmpname) abort
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

    let tmpfile = a:imgdir . '/' . a:tmpname . '.' . extension
    call system(printf(system_clip, mimetype, tmpfile))
    return tmpfile
endfunction

function! s:SaveFileTMPWin32(imgdir, tmpname) abort
    let tmpfile = a:imgdir . '\' . a:tmpname . '.png'
    let tmpfile = substitute(tmpfile, '\\ ', ' ', 'g')

    let clip_command = "Add-Type -AssemblyName System.Windows.Forms;"
    let clip_command .= "if ($([System.Windows.Forms.Clipboard]::ContainsImage())) {"
    let clip_command .= "[System.Drawing.Bitmap][System.Windows.Forms.Clipboard]::GetDataObject().getimage().Save('"
    let clip_command .= tmpfile ."', [System.Drawing.Imaging.ImageFormat]::Png) }"
    let clip_command = "powershell -nologo -noprofile -noninteractive -sta \"".clip_command. "\""

    silent call system(clip_command)
    if v:shell_error == 1
        return 1
    else
        return tmpfile
    endif
endfunction

function! s:SaveFileTMPMacOS(imgdir, tmpname) abort
    let tmpfile = a:imgdir . '/' . a:tmpname . '.png'
    let clip_command = 'osascript'
    let clip_command .= ' -e "set png_data to the clipboard as «class PNGf»"'
    let clip_command .= ' -e "set referenceNumber to open for access POSIX path of'
    let clip_command .= ' (POSIX file \"' . tmpfile . '\") with write permission"'
    let clip_command .= ' -e "write png_data to referenceNumber"'

    silent call system(clip_command)
    if v:shell_error == 1
        return 1
    else
        return tmpfile
    endif
endfunction

function! s:SaveFileTMP(imgdir, tmpname)
    echo "DEBUG: " . a:imgdir . ' ' . a:tmpname
    if s:os == "Linux"
        " Linux could also mean Windowns Subsystem for Linux
        if s:IsWSL()
            return s:SaveFileTMPWSL(a:imgdir, a:tmpname)
        endif
        return s:SaveFileTMPLinux(a:imgdir, a:tmpname)
    elseif s:os == "Darwin"
        return s:SaveFileTMPMacOS(a:imgdir, a:tmpname)
    elseif s:os == "Windows"
        return s:SaveFileTMPWin32(a:imgdir, a:tmpname)
    endif
endfunction


function! s:InputName()
    let name = strftime("%Y%m%d-%H%M%S")
    echo name
    return name
endfunction

function! g:MarkdownPasteImage(relpath)
    echo "DEBUG169: " . a:relpath
    execute "normal! i![" . g:mdip_tmpname[0:0]
    let ipos = getcurpos()
    execute "normal! a" . g:mdip_tmpname[1:] . "](" . a:relpath . ")"
    call setpos('.', ipos)
    execute "normal! vt]\<C-g>"
endfunction

function! g:LatexPasteImage(relpath)
    execute "normal! i\\includegraphics{" . a:relpath . "}\r\\caption{I"
    let ipos = getcurpos()
    execute "normal! a" . "mage}"
    call setpos('.', ipos)
    execute "normal! ve\<C-g>"
endfunction

function! g:EmptyPasteImage(relpath)
    execute "normal! i" . a:relpath
endfunction

let g:PasteImageFunction = 'g:MarkdownPasteImage'

function! mdip#MarkdownClipboardImage()
    " detect os: https://vi.stackexchange.com/questions/2572/detect-os-in-vimscript
    let s:os = "Windows"
    if !(has("win64") || has("win32") || has("win16"))
        let s:os = substitute(system('uname'), '\n', '', '')
    endif

    let workdir = s:SafeMakeDir()
    " change temp-file-name and image-name
    let g:mdip_tmpname = s:InputName()
    let testpath =  workdir . '/' . g:mdip_tmpname . '.png'

    let tmpfile = s:SaveFileTMP(workdir, g:mdip_tmpname)
    if tmpfile == 1
        return
    else
        let extension = split(tmpfile, '\.')[-1]
        let relpath = g:mdip_imgdir_intext . '/' . g:mdip_tmpname . '.' . extension
        if call(get(g:, 'PasteImageFunction'), [relpath])
            return
        endif
    endif
endfunction

if !exists('g:mdip_imgdir') && !exists('g:mdip_imgdir_absolute')
    let g:mdip_imgdir = 'img'
endif
"allow absolute paths. E.g., on linux: /home/path/to/imgdir/
if exists('g:mdip_imgdir_absolute')
    let g:mdip_imgdir = g:mdip_imgdir_absolute
endif
"allow a different intext reference for relative links
if !exists('g:mdip_imgdir_intext')
    let g:mdip_imgdir_intext = g:mdip_imgdir
endif
if !exists('g:mdip_tmpname')
    let g:mdip_tmpname = 'tmp'
endif
